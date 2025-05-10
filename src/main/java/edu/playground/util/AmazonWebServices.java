package edu.playground.util;

import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;

import java.net.URI;

@NoArgsConstructor(access = AccessLevel.PRIVATE)
@Slf4j
public class AmazonWebServices {

    public static final int PORT = 4566;
    public static final String SERVICE_NAME = "amazon-web-services";
    private static final String S3_ENDPOINT = "http://localhost:" + PORT;

    public static void createBucket(String bucketName) {
        S3ClientBuilder s3ClientBuilder = S3Client.builder()
                .endpointOverride(URI.create(S3_ENDPOINT))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create("test", "test")))
                .region(Region.US_EAST_1)
                .forcePathStyle(true);

        try (S3Client s3 = s3ClientBuilder.build()) {
            s3.createBucket(CreateBucketRequest.builder().bucket(bucketName).build());
            log.info("Bucket '{}' created successfully at {}", bucketName, S3_ENDPOINT);
        } catch (Exception e) {
            log.error("Error creating bucket '{}': {}", bucketName, e.getMessage(), e);
        }
    }

    public static void main(String[] args) {
        createBucket("my-bucket");
    }
}
