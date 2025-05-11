package edu.playground;


import edu.playground.avro.FlightTicketAvro;
import edu.playground.util.FlightTicketAvroDataSample;
import edu.playground.util.Kafka;
import edu.playground.util.KafkaAvroProducer;
import edu.playground.util.KafkaSchemaRegistry;
import edu.playground.util.KafkaSchemas;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.List;

@Slf4j
public class AvroProducer {

    private static final String TOPIC_NAME = "flight-tickets-avro";

    @SneakyThrows
    public static void main(String[] args) {

        Kafka.createKafkaTopic(TOPIC_NAME);
        var schema = KafkaSchemas.flightTicketAvroSchema();
        KafkaSchemaRegistry.registerSchema(schema, TOPIC_NAME + "-value");

        List<FlightTicketAvro> tickets = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            FlightTicketAvro e = FlightTicketAvroDataSample.flightTicketRandomSample();
            e.setTicketId("TCKT43963_0"); // Same ticket id
            e.setMealPreference(String.format("%4d lunch", i));
            tickets.add(e);
        }
        KafkaAvroProducer.send(FlightTicketAvro::getTicketId, TOPIC_NAME, tickets);

    }
}
