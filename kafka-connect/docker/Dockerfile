FROM alpine:3.18

# Allow passing Kafka version as a build argument
ARG KAFKA_VERSION=3.8.1
ARG SCALA_VERSION=2.13

# Set environment variables
ENV KAFKA_VERSION=${KAFKA_VERSION}
ENV SCALA_VERSION=${SCALA_VERSION}
ENV KAFKA_HOME=/opt/kafka
ENV PATH="${KAFKA_HOME}/bin:${PATH}"

# Install dependencies
RUN apk add --no-cache \
    openjdk17-jre \
    curl \
    bash \
    tar \
    jq \
    coreutils

# Function to download Kafka, trying the primary URL first, then falling back to the archive
RUN set -ex; \
    KAFKA_MAIN_URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"; \
    KAFKA_ARCHIVE_URL="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"; \
    if curl --head --fail --silent "$KAFKA_MAIN_URL"; then \
        echo "✅ Fetching Kafka from: $KAFKA_MAIN_URL"; \
        curl -fsSL "$KAFKA_MAIN_URL" | tar -xz -C /opt; \
    elif curl --head --fail --silent "$KAFKA_ARCHIVE_URL"; then \
        echo "⚠️ Main URL failed. Fetching Kafka from archive: $KAFKA_ARCHIVE_URL"; \
        curl -fsSL "$KAFKA_ARCHIVE_URL" | tar -xz -C /opt; \
    else \
        echo "❌ Failed to download Kafka from both sources!" && exit 1; \
    fi; \
    mv /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME}; \
    rm -rf ${KAFKA_HOME}/site-docs

# Copy startup script into the container
COPY ./kafka-connect/docker/kafka-connect.start.sh /usr/local/bin/kafka-connect.start.sh
RUN chmod +x /usr/local/bin/kafka-connect.start.sh

# Set working directory
WORKDIR ${KAFKA_HOME}

# Expose Kafka Connect REST API port
EXPOSE 8083

# Start Kafka Connect using the script
CMD ["/usr/local/bin/kafka-connect.start.sh"]
