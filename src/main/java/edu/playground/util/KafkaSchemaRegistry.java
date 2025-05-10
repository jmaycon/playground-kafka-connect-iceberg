package edu.playground.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import io.confluent.kafka.schemaregistry.avro.AvroSchema;
import io.confluent.kafka.schemaregistry.json.JsonSchema;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.SneakyThrows;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.io.entity.StringEntity;

import java.io.IOException;

import static java.nio.charset.StandardCharsets.UTF_8;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
public class KafkaSchemaRegistry {

    public static final int PORT = 8082;
    static final String SERVICE_NAME = "kafka-schema-registry";

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .disable(SerializationFeature.INDENT_OUTPUT)
            .disable(SerializationFeature.WRITE_SELF_REFERENCES_AS_NULL);

    @SneakyThrows
    public static void registerSchema(AvroSchema avroSchema, String schemaName) {
        doRegisterSchema(avroSchema.toString(), schemaName, "AVRO");
    }

    @SneakyThrows
    public static void registerSchema(JsonSchema jsonSchema, String schemaName) {
        doRegisterSchema(jsonSchema.toString(), schemaName, "JSON");
    }

    private static void doRegisterSchema(String schema, String schemaName, String schemaType) throws IOException {
        var targetURL = "http://localhost:%d/subjects/%s/versions".formatted(PORT, schemaName);

        var payloadNode = MAPPER.createObjectNode();
        payloadNode.put("schemaType", schemaType);
        payloadNode.put("schema", schema);
        var jsonInputString = payloadNode.toString();

        try (var client = HttpClients.createDefault()) {
            var post = new HttpPost(targetURL);
            post.setHeader("Content-Type", "application/vnd.schemaregistry.v1+json");
            post.setEntity(new StringEntity(jsonInputString, UTF_8));

            client.execute(post, response -> {
                String responseBody = response.getEntity() != null ? new String(response.getEntity().getContent().readAllBytes(), UTF_8) : "";
                if (response.getCode() != 200) {
                    throw new RuntimeException("Fail to register schema with response %d/n%s"
                            .formatted(response.getCode(), responseBody));
                }
                return responseBody;
            });
        }
    }

    @SneakyThrows
    public static String getLatestSchema(String schemaName) {
        var targetURL = "http://localhost:%d/subjects/%s/versions/latest".formatted(PORT, schemaName);

        try (var client = HttpClients.createDefault()) {
            var get = new HttpGet(targetURL);
            get.setHeader("Accept", "application/vnd.schemaregistry.v1+json");

            return client.execute(get, response -> {
                String responseBody = new String(response.getEntity().getContent().readAllBytes(), UTF_8);
                if (response.getCode() != 200) {
                    throw new RuntimeException("Could not fetch schema %d/%s".formatted(response.getCode(), responseBody));
                }
                return responseBody;
            });
        }
    }
}
