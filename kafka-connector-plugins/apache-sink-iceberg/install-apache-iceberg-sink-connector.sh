#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
PLUGINS_BASE_DIR="/kafka-connect-3rd-party-plugins"
GIT_REF="${GIT_REF:-apache-iceberg-1.9.0}"

WORK_DIR="/work-dir"
BUILD_DIR="$WORK_DIR/build"
EXTRA_LIBS_DIR="$WORK_DIR/extra-libs"
PLUGIN_SOURCE_DIR="$BUILD_DIR/kafka-connect/kafka-connect-runtime/build/distributions"
PLUGINS_TARGET_DIR="$PLUGINS_BASE_DIR/apache-sink-iceberg-$GIT_REF"

# Extra dependencies
EXTRA_DEPENDENCIES_POM_FILE="$EXTRA_LIBS_DIR/download-extra-dependencies.xml"
MVN_LOCAL_REPO_DIR="/maven-local-repo"

main() {
  build_connector
  add_extra_dependencies
  echo "✅ Done; connector(s) ready in $PLUGINS_BASE_DIR"
}

build_connector() {
  echo "➡️ Building Apache Iceberg connector from '$GIT_REF'…"
  if [ -d "$PLUGINS_TARGET_DIR" ]; then
    echo "✅ Connector already present at $PLUGINS_TARGET_DIR, skipping build."
    return 0
  fi

  if [ ! -d "$BUILD_DIR/.git" ]; then
    git clone --branch "$GIT_REF" --depth 1 https://github.com/apache/iceberg.git "$BUILD_DIR"
    cd "$BUILD_DIR"
  else
    cd "$BUILD_DIR"
    git fetch --depth 1 origin "$GIT_REF" || true
    git fetch --tags --depth 1 origin
    git checkout "$GIT_REF"
  fi

  ./gradlew --no-daemon --parallel \
    -x test -x integrationTest \
    -x spotlessJava -x spotlessJavaCheck -x spotlessCheck \
    -x javadoc -x javadocJar -x sourceJar \
    -x checkstyleMain -x checkstyleTest -x check \
    clean build

  ZIP_FILES=$(find "$PLUGIN_SOURCE_DIR" -name '*.zip')

  if [ -z "$ZIP_FILES" ]; then
    echo "❌ No connector ZIPs found!"
    exit 1
  fi

  echo "➡️ Extracting connector ZIP(s) to $PLUGINS_BASE_DIR"
  for file in $ZIP_FILES; do
    # Check if the file matches the pattern 'iceberg-kafka-connect-runtime-hive*.zip'
    if [[ "$file" == *iceberg-kafka-connect-runtime-hive*.zip ]]; then
      echo "⏩ Skipping: $file (matches 'iceberg-kafka-connect-runtime-hive*.zip')"
      continue
    fi

    # Preserve directory structure by getting the relative path
    rel_path=$(realpath --relative-to="$PLUGIN_SOURCE_DIR" "$file")
    dest_dir="$PLUGINS_TARGET_DIR/$(dirname "$rel_path")"

    # Ensure the destination subdirectory exists
    mkdir -p "$dest_dir"

    filename=$(basename "$file")
    echo "📦 Extracting: $filename into $dest_dir"
    unzip -o "$file" -d "$dest_dir"
  done
}

add_extra_dependencies() {
  echo "➡️ Adding extra dependencies…"

  # Make sure the extra dependencies file exists
  if [ ! -f "$EXTRA_DEPENDENCIES_POM_FILE" ]; then
    echo "❌ Extra dependencies file not found: $EXTRA_DEPENDENCIES_POM_FILE"
    exit 1
  fi

  # Ensure Maven is available, or install it if missing
  if ! command -v mvn &>/dev/null; then
    local MAVEN_VERSION=3.9.9
    echo "📦 Installing Maven $MAVEN_VERSION…"
    wget -q -O /tmp/maven.tar.gz \
      "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
    tar -xf /tmp/maven.tar.gz -C /tmp
    export PATH="/tmp/apache-maven-${MAVEN_VERSION}/bin:$PATH"
  fi

  # Run Maven to resolve the dependencies defined in the extra dependencies file
  mvn -f "$EXTRA_DEPENDENCIES_POM_FILE" clean package -DskipTests -T 3C -Dmaven.repo.local="$MVN_LOCAL_REPO_DIR"

  # Copy the dependencies to each connector's lib directory (no overwriting)
  echo "➡️ Copying extra dependencies…"
  for plugin_dir in "$PLUGINS_TARGET_DIR"/*; do
    if [ -d "$plugin_dir" ]; then
      local src_dir="$EXTRA_LIBS_DIR/target/lib"
      local dest_dir="$plugin_dir/lib"
      mkdir -p "$dest_dir"

      # Ensure JAR files exist before proceeding
      if compgen -G "$src_dir/*.jar" > /dev/null; then
        echo "📁 Copying new jars into $dest_dir (skipping existing)"
        for jar in "$src_dir"/*.jar; do
          local base
          base=$(basename "$jar")
          if [ ! -f "$dest_dir/$base" ]; then
            cp "$jar" "$dest_dir/"
            echo "   ✔ Copied $base"
          else
            echo "   ⚠ Skipped existing $base"
          fi
        done
      else
        echo "⚠ No JARs found in $src_dir to copy to $plugin_dir"
      fi
    fi
  done
}

main "$@"
