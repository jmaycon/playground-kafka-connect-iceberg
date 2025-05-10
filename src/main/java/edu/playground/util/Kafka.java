package edu.playground.util;

import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;

import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
@Slf4j
public class Kafka {

    static final String SERVICE_NAME = "kafka";
    public static final int PORT = 9092;

    @SneakyThrows
    public static void createKafkaTopic(String topicName) {
        Properties config = new Properties();
        config.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:" + PORT);

        try (var adminClient = AdminClient.create(config)) {
            var newTopic = new NewTopic(topicName, 3, (short) 1);
            adminClient.createTopics(Collections.singletonList(newTopic)).all().get();
            log.info("Topic '{}' created successfully.", topicName);
        } catch (ExecutionException e) {
            if (e.getCause() instanceof org.apache.kafka.common.errors.TopicExistsException) {
                log.info("Topic '{}' already exists.", topicName);
            } else {
                throw new RuntimeException("Failed to create topic", e);
            }
        }
    }
}
