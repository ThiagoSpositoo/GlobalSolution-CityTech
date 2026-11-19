package br.com.fiap.citytech.messaging;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import br.com.fiap.citytech.category.Category;
import br.com.fiap.citytech.category.CategoryRepository;
import br.com.fiap.citytech.classification.AiSuggestionRepository;
import br.com.fiap.citytech.classification.AiSuggestionStatus;
import br.com.fiap.citytech.classification.ProcessedEventRepository;
import br.com.fiap.citytech.history.StatusHistoryRepository;
import br.com.fiap.citytech.occurrence.OccurrenceContracts;
import br.com.fiap.citytech.occurrence.OccurrenceRepository;
import br.com.fiap.citytech.occurrence.OccurrenceService;
import br.com.fiap.citytech.occurrence.Priority;
import br.com.fiap.citytech.security.AuthenticatedUser;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPairGenerator;
import java.time.Duration;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:citytech-rabbit;MODE=Oracle;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "citytech.messaging.publisher-enabled=true",
    "citytech.messaging.publisher-delay-ms=100",
    "spring.rabbitmq.listener.simple.retry.enabled=true",
    "spring.rabbitmq.listener.simple.retry.max-attempts=3"
})
@EnabledIfEnvironmentVariable(named = "CITYTECH_RUN_RABBIT_INTEGRATION", matches = "true")
class RabbitIntegrationTests {

    private static final Path PUBLIC_KEY_PATH = createPublicKey();

    @Autowired
    private RabbitAdmin rabbitAdmin;

    @Autowired
    private OccurrenceService occurrenceService;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private OccurrenceRepository occurrenceRepository;

    @Autowired
    private StatusHistoryRepository historyRepository;

    @Autowired
    private OutboxEventRepository outboxRepository;

    @Autowired
    private AiSuggestionRepository suggestionRepository;

    @Autowired
    private ProcessedEventRepository processedEventRepository;

    @DynamicPropertySource
    static void runtimeProperties(DynamicPropertyRegistry registry) {
        registry.add("citytech.security.public-key-path", PUBLIC_KEY_PATH::toString);
        registry.add("spring.rabbitmq.host", () -> "localhost");
        registry.add("spring.rabbitmq.port", () -> env("RABBITMQ_PORT", "5672"));
        registry.add("spring.rabbitmq.username", () -> env("RABBITMQ_USER", null));
        registry.add("spring.rabbitmq.password", () -> env("RABBITMQ_PASSWORD", null));
    }

    @BeforeEach
    void clean() {
        rabbitAdmin.purgeQueue(RabbitTopologyConfig.QUEUE, false);
        rabbitAdmin.purgeQueue(RabbitTopologyConfig.DEAD_LETTER_QUEUE, false);
        processedEventRepository.deleteAllInBatch();
        suggestionRepository.deleteAllInBatch();
        outboxRepository.deleteAllInBatch();
        historyRepository.deleteAllInBatch();
        occurrenceRepository.deleteAllInBatch();
        categoryRepository.deleteAllInBatch();
    }

    @AfterEach
    void purgeQueues() {
        rabbitAdmin.purgeQueue(RabbitTopologyConfig.QUEUE, false);
        rabbitAdmin.purgeQueue(RabbitTopologyConfig.DEAD_LETTER_QUEUE, false);
    }

    @AfterAll
    static void removeGeneratedKey() throws Exception {
        Files.deleteIfExists(PUBLIC_KEY_PATH);
    }

    @Test
    void publishesAndConsumesOccurrenceCreatedThroughRealBroker() throws Exception {
        var category = categoryRepository.saveAndFlush(
                new Category("VIAS", "Vias e buracos", null));
        var user = new AuthenticatedUser(UUID.randomUUID(), Set.of("CIDADAO"));
        var response = occurrenceService.create(
                new OccurrenceContracts.CreateRequest(
                        "Buraco na faixa direita",
                        "Buraco profundo próximo à faixa de pedestres.",
                        category.getId(),
                        Priority.ALTA,
                        new OccurrenceContracts.AddressRequest(
                                "Rua Exemplo",
                                "100",
                                null,
                                "Centro",
                                "São Paulo",
                                "SP",
                                "01000-000")),
                user);

        var deadline = Instant.now().plus(Duration.ofSeconds(15));
        while (Instant.now().isBefore(deadline)
                && suggestionRepository.findByOccurrenceId(response.id()).isEmpty()) {
            Thread.sleep(100);
        }

        var suggestion = suggestionRepository.findByOccurrenceId(response.id()).orElseThrow();
        var outbox = outboxRepository.findAll().getFirst();
        assertEquals(AiSuggestionStatus.FALHOU, suggestion.getStatus());
        assertEquals("MODEL_NOT_CONFIGURED", suggestion.getErrorCode());
        assertEquals(1, processedEventRepository.count());
        assertNotNull(outbox.getPublishedAt());
        assertEquals(1, outbox.getAttempts());
    }

    private static String env(String name, String defaultValue) {
        var value = System.getenv(name);
        return value == null || value.isBlank() ? defaultValue : value;
    }

    private static Path createPublicKey() {
        try {
            var generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            var publicKey = generator.generateKeyPair().getPublic();
            var directory = Path.of("target", "test-keys");
            Files.createDirectories(directory);
            var path = directory.resolve("rabbit-integration-public.pem").toAbsolutePath();
            var encoded = java.util.Base64.getMimeEncoder(64, new byte[] {'\n'})
                    .encodeToString(publicKey.getEncoded());
            Files.writeString(
                    path,
                    "-----BEGIN PUBLIC KEY-----\n"
                            + encoded
                            + "\n-----END PUBLIC KEY-----\n",
                    StandardCharsets.US_ASCII);
            return path;
        } catch (Exception exception) {
            throw new ExceptionInInitializerError(exception);
        }
    }
}
