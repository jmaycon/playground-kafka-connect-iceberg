#!/bin/sh

# Mark service as healthy
touch /tmp/healthy

echo "✅ Kafka version is $(/opt/kafka/bin/kafka-topics.sh --version)"

# Start Kafka Connect in distributed mode
exec bin/connect-distributed.sh /opt/kafka/config/kafka-connect.properties
