package edu.playground.util;

import io.confluent.kafka.schemaregistry.avro.AvroSchema;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.SneakyThrows;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Represents src/main/resources/kafka-schemas
 */
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class KafkaSchemas {

    private static final Path PATH = Paths.get("src", "main", "resources", "kafka-schemas");

    @SneakyThrows
    public static AvroSchema flightTicketAvroSchema() {
        return new AvroSchema(Files.readString(PATH.resolve("FlightTicket.schema.avsc")));
    }
}
