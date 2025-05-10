package edu.playground.util;

import io.confluent.kafka.serializers.KafkaAvroSerializer;
import io.confluent.kafka.serializers.KafkaAvroSerializerConfig;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.apache.avro.Schema;
import org.apache.avro.specific.SpecificRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

import java.util.List;
import java.util.Properties;
import java.util.UUID;
import java.util.function.Function;
import java.util.function.Supplier;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
@Slf4j
public final class KafkaAvroProducer {

    @SneakyThrows
    public static <T extends SpecificRecord> void send(String topicName, T value) {
        send(topicName, List.of(value));
    }

    @SneakyThrows
    public static <T extends SpecificRecord> void send(String topicName, List<T> values) {
        send(v -> UUID.randomUUID().toString(), topicName, values);
    }

    @SneakyThrows
    public static <T extends SpecificRecord> void send(Function<T, String> keyExtractor, String topicName, List<T> values) {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:" + Kafka.PORT); // Adjust if needed
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class.getName());
        props.put(KafkaAvroSerializerConfig.SCHEMA_REGISTRY_URL_CONFIG, "http://localhost:" + KafkaSchemaRegistry.PORT);
        props.put(KafkaAvroSerializerConfig.AVRO_REMOVE_JAVA_PROPS_CONFIG, true);
        props.put(KafkaAvroSerializerConfig.AUTO_REGISTER_SCHEMAS, false);

        try (var producer = new KafkaProducer<String, T>(props)) {
            for (int i = 0; i < values.size(); i++) {
                var value = values.get(i);
                String key = keyExtractor.apply(value);
                var record = new ProducerRecord<>(topicName, key, value);
                var metadata = producer.send(record).get(); // Synchronously send message
                log.info("Produced message to topic {} at partition {} offset {}",
                        metadata.topic(), metadata.partition(), metadata.offset());
            }
        }
    }
}
