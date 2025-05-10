#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
PLUGINS_BASE=/kafka-connect-3rd-party-plugins
ARTIFACT_VERSION="${ARTIFACT_VERSION:-0.6.19}"
ZIP_NAME="iceberg-kafka-connect-databricks-$ARTIFACT_VERSION.zip"

WORK_DIR=/work-dir
EXTRA_LIBS_DIR="$WORK_DIR/extra-libs"
PLUGIN_SOURCE_DIR="$WORK_DIR/$ZIP_NAME"
PLUGINS_TARGET_DIR="$PLUGINS_BASE/databricks-sink-iceberg-$ARTIFACT_VERSION"

# Extra dependencies
EXTRA_DEPENDENCIES_POM_FILE="$EXTRA_LIBS_DIR/download-extra-dependencies.xml"
MVN_LOCAL_REPO_DIR=/maven-local-repo

# Main function to run the tasks
main() {
  download_databricks_connector
  add_extra_dependencies
  echo "✅ Done"
}

download_databricks_connector() {
  
  if [ -f "$PLUGINS_TARGET_DIR" ]; then
    echo "✅  $PLUGINS_TARGET_DIR already exists, skipping download."
    return 0
  fi
  
  echo "➡️  Downloading Databricks Iceberg Sink Connector v$ARTIFACT_VERSION…"
  curl -fSL "https://github.com/databricks/iceberg-kafka-connect/releases/download/v$ARTIFACT_VERSION/iceberg-kafka-connect-runtime-$ARTIFACT_VERSION.zip" -o "$PLUGIN_SOURCE_DIR"
  echo "✅  Downloaded to $PLUGIN_SOURCE_DIR"

  # Extract the ZIP file
  echo "➡️  Extracting $PLUGIN_SOURCE_DIR to $PLUGINS_TARGET_DIR…"
  mkdir -p "$PLUGINS_TARGET_DIR"
  unzip -o "$PLUGIN_SOURCE_DIR" -d "$PLUGINS_TARGET_DIR"
  echo "✅  Extracted to $PLUGINS_TARGET_DIR"
}

add_extra_dependencies() {
  echo "➡️ Adding extra dependencies…"

  # Make sure the extra dependencies file exists
  if [ ! -f "$EXTRA_DEPENDENCIES_POM_FILE" ]; then
    echo "❌ Extra dependencies file not found: $EXTRA_DEPENDENCIES_POM_FILE"
    exit 1
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

# Start the process
main "$@"
