package edu.playground.util;

/*import edu.playground.avro.BaggageInfo;
import edu.playground.avro.BaggageItem;
import edu.playground.avro.BaggageType;*/

import edu.playground.avro.Baggage;
import edu.playground.avro.BaggageType;
import edu.playground.avro.FlightDetails;
import edu.playground.avro.FlightTicketAvro;
import edu.playground.avro.Passenger;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import net.datafaker.Faker;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
public final class FlightTicketAvroDataSample {

    public static FlightTicketAvro flightTicketSample() {
        // Create FlightDetails
        Instant departureTime = Instant.parse("2025-08-02T10:45:01.123Z");
        Instant arrivalTime = Instant.parse("2025-08-02T15:30:02.123Z");

        FlightDetails flightDetails = FlightDetails.newBuilder()
                .setFlightNumber("AA123")
                .setDepartureAirport("JFK")
                .setArrivalAirport("LAX")
                .setDepartureTime(departureTime) // timestamp-millis
                .setArrivalTime(arrivalTime) // 1 hour later
                .build();

        // Create Passenger with LocalDate.parse
        LocalDate dateOfBirth = LocalDate.parse("1990-05-15");
        Passenger passenger = Passenger.newBuilder()
                .setFirstName("John")
                .setLastName("Doe")
                .setDateOfBirth(dateOfBirth) // Convert LocalDate to Avro logical type date
                .build();

       Baggage baggage1 = Baggage.newBuilder()
                .setWeightKg(new BigDecimal("15.546"))
                .setType(BaggageType.CHECKED)
                .build();

        Baggage baggage2 = Baggage.newBuilder()
                .setWeightKg(new BigDecimal("7.032"))
                .setType(BaggageType.CARRY_ON)
                .build();

        List<Baggage> baggageList = List.of(baggage1, baggage2);


        // Create FlightTicket
        return FlightTicketAvro.newBuilder()
                .setTicketUuid(UUID.fromString("550e8400-e29b-41d4-a716-446655440000"))
                .setPrice(new BigDecimal("299.99"))
                .setTicketId("TCKT1234567")
                .setFlight(flightDetails)
                .setPassenger(passenger)
                .setSeat("12A")
                .setBaggage(baggageList)
                .setMealPreference("Vegetarian")
                .build();
    }

    public static FlightTicketAvro flightTicketRandomSample() {
        Faker faker = new Faker();
        // Create FlightDetails
        Instant departureTime = faker.date().past(2, TimeUnit.DAYS).toInstant();
        Instant arrivalTime = departureTime.plusSeconds(faker.number().numberBetween(7200, 86400));

        FlightDetails flightDetails = FlightDetails.newBuilder()
                .setFlightNumber(faker.text().text(4) + "-" + faker.number().digits(6))
                .setDepartureAirport(faker.text().text(3).toUpperCase())
                .setArrivalAirport(faker.text().text(3).toUpperCase())
                .setDepartureTime(departureTime) // timestamp-millis
                .setArrivalTime(arrivalTime) // 1 hour later
                .build();

        // Create Passenger with LocalDate.parse
        LocalDate dateOfBirth = faker.date().birthday(19, 65).toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
        Passenger passenger = Passenger.newBuilder()
                .setFirstName(faker.name().firstName())
                .setLastName(faker.name().lastName())
                .setDateOfBirth(dateOfBirth)
                .build();

        Baggage baggage1 = Baggage.newBuilder()
                .setWeightKg(BigDecimal.valueOf(faker.number().randomDouble(3, 13, 23)))
                .setType(BaggageType.CHECKED)
                .build();

        Baggage baggage2 = Baggage.newBuilder()
                .setWeightKg(BigDecimal.valueOf(faker.number().randomDouble(3, 1, 12)))
                .setType(BaggageType.CARRY_ON)
                .build();

        List<Baggage> baggageList = List.of(baggage1, baggage2);


        // Create FlightTicket
        return FlightTicketAvro.newBuilder()
                .setTicketUuid(UUID.randomUUID())
                .setPrice(BigDecimal.valueOf(faker.number().randomDouble(2, 317, 1535)))
                .setTicketId("TCKT" + faker.number().digits(5))
                .setFlight(flightDetails)
                .setPassenger(passenger)
                .setSeat(faker.number().digits(2) + faker.text().text(2))
                .setBaggage(baggageList)
                .setMealPreference(faker.food().dish())
                .build();
    }
}
