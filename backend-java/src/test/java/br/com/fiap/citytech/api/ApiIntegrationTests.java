package br.com.fiap.citytech.api;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.com.fiap.citytech.category.Category;
import br.com.fiap.citytech.category.CategoryRepository;
import br.com.fiap.citytech.classification.AiSuggestionRepository;
import br.com.fiap.citytech.classification.AiSuggestionStatus;
import br.com.fiap.citytech.classification.AiSuggestion;
import br.com.fiap.citytech.classification.ClassificationService;
import br.com.fiap.citytech.classification.ProcessedEventRepository;
import br.com.fiap.citytech.history.StatusHistoryRepository;
import br.com.fiap.citytech.messaging.OccurrenceCreatedEvent;
import br.com.fiap.citytech.messaging.OutboxEventRepository;
import br.com.fiap.citytech.occurrence.OccurrenceRepository;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPairGenerator;
import java.util.UUID;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(
        webEnvironment = WebEnvironment.MOCK,
        properties = {
            "spring.datasource.url=jdbc:h2:mem:citytech-api;MODE=Oracle;DB_CLOSE_DELAY=-1",
            "spring.datasource.driver-class-name=org.h2.Driver",
            "spring.datasource.username=sa",
            "spring.datasource.password=",
            "spring.jpa.hibernate.ddl-auto=create-drop",
            "spring.jpa.properties.hibernate.jdbc.time_zone=UTC",
            "spring.rabbitmq.username=test",
            "spring.rabbitmq.password=test",
            "spring.rabbitmq.listener.simple.auto-startup=false",
            "citytech.messaging.publisher-enabled=false",
            "spring.profiles.active=local",
            "citytech.cors.allowed-origins=http://localhost:8081,http://localhost:19006"
        })
@AutoConfigureMockMvc
class ApiIntegrationTests {

    private static final Path PUBLIC_KEY_PATH = createPublicKey();

    @Autowired
    private MockMvc mockMvc;

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

    @Autowired
    private ClassificationService classificationService;

    @Autowired
    private tools.jackson.databind.ObjectMapper objectMapper;

    @DynamicPropertySource
    static void securityProperties(DynamicPropertyRegistry registry) {
        registry.add("citytech.security.public-key-path", PUBLIC_KEY_PATH::toString);
    }

    @BeforeEach
    void cleanDatabase() {
        processedEventRepository.deleteAllInBatch();
        suggestionRepository.deleteAllInBatch();
        outboxRepository.deleteAllInBatch();
        historyRepository.deleteAllInBatch();
        occurrenceRepository.deleteAllInBatch();
        categoryRepository.deleteAllInBatch();
    }

    @AfterAll
    static void deleteGeneratedPublicKey() throws Exception {
        Files.deleteIfExists(PUBLIC_KEY_PATH);
    }

    @Test
    void unauthenticatedRequestUsesStandardErrorEnvelope() throws Exception {
        mockMvc.perform(get("/api/v1/categories"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.traceId").isNotEmpty());
    }

    @Test
    void citizenCannotManageCategories() throws Exception {
        mockMvc.perform(post("/api/v1/categories")
                        .with(user(UUID.randomUUID(), "CIDADAO"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"VIAS","name":"Vias","description":null}
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("FORBIDDEN"));
    }

    @Test
    void managerCanCreateAndDeactivateCategory() throws Exception {
        var result = mockMvc.perform(post("/api/v1/categories")
                        .with(user(UUID.randomUUID(), "GESTOR"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"vias","name":"Vias e buracos","description":"Pavimentação"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", org.hamcrest.Matchers.startsWith(
                        "/api/v1/categories/")))
                .andExpect(jsonPath("$.code").value("VIAS"))
                .andReturn();
        var id = com.jayway.jsonpath.JsonPath
                .parse(result.getResponse().getContentAsString())
                .read("$.id", String.class);

        mockMvc.perform(delete("/api/v1/categories/{id}", id)
                        .with(user(UUID.randomUUID(), "GESTOR")))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/api/v1/categories?includeInactive=true")
                        .with(user(UUID.randomUUID(), "GESTOR")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].active").value(false));
    }

    @Test
    void invalidOccurrenceBodyReturnsFieldErrors() throws Exception {
        mockMvc.perform(post("/api/v1/occurrences")
                        .with(user(UUID.randomUUID(), "CIDADAO"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"x","description":"curta","categoryId":null,"address":null}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.errors").isArray());
    }

    @Test
    void ownerCreatesListsAndReadsOccurrenceWhileOtherCitizenGets404() throws Exception {
        var owner = UUID.randomUUID();
        var category = category();
        var id = createOccurrence(owner, category.getId());

        mockMvc.perform(get("/api/v1/occurrences")
                        .with(user(owner, "CIDADAO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].id").value(id.toString()));
        mockMvc.perform(get("/api/v1/occurrences/{id}", id)
                        .with(user(UUID.randomUUID(), "CIDADAO")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOT_FOUND"));
    }

    @Test
    void updateRequiresCurrentVersionAndOpenStatus() throws Exception {
        var owner = UUID.randomUUID();
        var category = category();
        var id = createOccurrence(owner, category.getId());

        mockMvc.perform(put("/api/v1/occurrences/{id}", id)
                        .with(user(owner, "CIDADAO"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateBody(category.getId(), 99)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONCURRENT_MODIFICATION"));
        mockMvc.perform(put("/api/v1/occurrences/{id}", id)
                        .with(user(owner, "CIDADAO"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateBody(category.getId(), 0)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Título atualizado"))
                .andExpect(jsonPath("$.version").value(1));
    }

    @Test
    void managerTransitionsStatusAndHistoryIsAppendOnly() throws Exception {
        var owner = UUID.randomUUID();
        var manager = UUID.randomUUID();
        var id = createOccurrence(owner, category().getId());

        mockMvc.perform(patch("/api/v1/occurrences/{id}/status", id)
                        .with(user(manager, "GESTOR"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"version":0,"status":"EM_TRIAGEM","note":"Triagem iniciada."}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("EM_TRIAGEM"))
                .andExpect(jsonPath("$.version").value(1));
        mockMvc.perform(get("/api/v1/occurrences/{id}/history", id)
                        .with(user(manager, "GESTOR")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.items[0].action").value("CRIACAO"))
                .andExpect(jsonPath("$.items[1].action").value("TRANSICAO"));
    }

    @Test
    void managerTriageRecordsPreviousAndNewStatus() throws Exception {
        var owner = UUID.randomUUID();
        var manager = UUID.randomUUID();
        var category = category();
        var id = createOccurrence(owner, category.getId());

        mockMvc.perform(patch("/api/v1/occurrences/{id}/triage", id)
                        .with(user(manager, "GESTOR"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"version":0,"categoryId":"%s","priority":"CRITICA","note":"Risco imediato."}
                                """.formatted(category.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("EM_TRIAGEM"))
                .andExpect(jsonPath("$.priority").value("CRITICA"))
                .andExpect(jsonPath("$.version").value(1));
        mockMvc.perform(get("/api/v1/occurrences/{id}/history", id)
                        .with(user(manager, "GESTOR")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.items[1].action").value("TRIAGEM"))
                .andExpect(jsonPath("$.items[1].fromStatus").value("ABERTA"))
                .andExpect(jsonPath("$.items[1].toStatus").value("EM_TRIAGEM"))
                .andExpect(jsonPath("$.items[1].note").value("Risco imediato."));
    }

    @Test
    void cancelRequiresVersionAndEnforcesCitizenTransitionPolicy() throws Exception {
        var owner = UUID.randomUUID();
        var category = category();
        var id = createOccurrence(owner, category.getId());

        mockMvc.perform(delete("/api/v1/occurrences/{id}", id)
                        .queryParam("version", "9")
                        .queryParam("reason", "Registro duplicado")
                        .with(user(owner, "CIDADAO")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONCURRENT_MODIFICATION"));
        mockMvc.perform(delete("/api/v1/occurrences/{id}", id)
                        .queryParam("version", "0")
                        .queryParam("reason", "Registro duplicado")
                        .with(user(owner, "CIDADAO")))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/api/v1/occurrences/{id}", id)
                        .with(user(owner, "CIDADAO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELADA"));
    }

    @Test
    void invalidPaginationAndSortReturn400() throws Exception {
        mockMvc.perform(get("/api/v1/occurrences")
                        .queryParam("size", "101")
                        .with(user(UUID.randomUUID(), "GESTOR")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        mockMvc.perform(get("/api/v1/occurrences")
                        .queryParam("sort", "citizenId,asc")
                        .with(user(UUID.randomUUID(), "GESTOR")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void indicatorsAreManagerOnlyAndAggregatePersistedOccurrences() throws Exception {
        createOccurrence(UUID.randomUUID(), category().getId());

        mockMvc.perform(get("/api/v1/manager/indicators")
                        .with(user(UUID.randomUUID(), "CIDADAO")))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/manager/indicators")
                        .with(user(UUID.randomUUID(), "GESTOR")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalOccurrences").value(1))
                .andExpect(jsonPath("$.byStatus.ABERTA").value(1))
                .andExpect(jsonPath("$.byCategory.VIAS").value(1));
    }

    @Test
    void publicHealthAndOpenApiEndpointsAreAvailable() throws Exception {
        mockMvc.perform(get("/health/live"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
        mockMvc.perform(get("/health/ready"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.checks.oracle.status").value("UP"));
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.openapi").isNotEmpty());
    }

    @Test
    void localCorsAllowsLoopbackPortsAndAnyHeaderButRejectsExternalOrigin() throws Exception {
        var allowedOrigin = "http://localhost:8082";

        mockMvc.perform(options("/api/v1/categories")
                        .header(HttpHeaders.ORIGIN, allowedOrigin)
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                        .header(
                                HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS,
                                "Authorization, Content-Type, Idempotency-Key, X-Local-Debug"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, allowedOrigin))
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS,
                        org.hamcrest.Matchers.containsString("POST")))
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS,
                        org.hamcrest.Matchers.containsString("X-Local-Debug")));

        mockMvc.perform(get("/api/v1/categories")
                        .with(user(UUID.randomUUID(), "GESTOR"))
                        .header(HttpHeaders.ORIGIN, allowedOrigin))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, allowedOrigin))
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_EXPOSE_HEADERS,
                        org.hamcrest.Matchers.containsString("Retry-After")));

        mockMvc.perform(options("/api/v1/categories")
                        .header(HttpHeaders.ORIGIN, "https://not-allowed.example")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN));
    }

    @Test
    void creationWritesOutboxAndConsumerFallbackIsIdempotent() throws Exception {
        var occurrenceId = createOccurrence(UUID.randomUUID(), category().getId());
        var outbox = outboxRepository.findAll().getFirst();
        var event = objectMapper.readValue(outbox.getPayload(), OccurrenceCreatedEvent.class);

        org.junit.jupiter.api.Assertions.assertEquals(occurrenceId, event.occurrenceId());
        org.junit.jupiter.api.Assertions.assertEquals("OccurrenceCreated", event.eventType());
        org.junit.jupiter.api.Assertions.assertEquals(0, outbox.getAttempts());

        classificationService.process(event);
        classificationService.process(event);

        var suggestion = suggestionRepository.findByOccurrenceId(occurrenceId).orElseThrow();
        org.junit.jupiter.api.Assertions.assertEquals(
                AiSuggestionStatus.FALHOU,
                suggestion.getStatus());
        org.junit.jupiter.api.Assertions.assertEquals(
                "MODEL_NOT_CONFIGURED",
                suggestion.getErrorCode());
        org.junit.jupiter.api.Assertions.assertEquals(1, processedEventRepository.count());
    }

    @Test
    void ownerCanAcceptReadySuggestionWithHumanReview() throws Exception {
        var owner = UUID.randomUUID();
        var category = category();
        var occurrenceId = createOccurrence(owner, category.getId());
        var occurrence = occurrenceRepository.findById(occurrenceId).orElseThrow();
        var suggestion = new AiSuggestion(occurrence);
        suggestion.ready(
                category,
                br.com.fiap.citytech.occurrence.Priority.CRITICA,
                "Buraco com risco para pedestres.",
                "O relato menciona proximidade da faixa de pedestres.",
                "[\"citytech-corpus/taxonomia.md#vias\"]",
                "modelo-controlado",
                "rag-v1");
        suggestionRepository.saveAndFlush(suggestion);

        mockMvc.perform(post("/api/v1/occurrences/{id}/ai-suggestion/review", occurrenceId)
                        .with(user(owner, "CIDADAO"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"version":0,"decision":"ACEITAR","note":"Classificação confirmada."}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("EM_TRIAGEM"))
                .andExpect(jsonPath("$.priority").value("CRITICA"))
                .andExpect(jsonPath("$.aiSuggestion.status").value("ACEITA"))
                .andExpect(jsonPath("$.aiSuggestion.decision").value("ACEITAR"))
                .andExpect(jsonPath("$.aiSuggestion.sources[0]")
                        .value("citytech-corpus/taxonomia.md#vias"));
        mockMvc.perform(get("/api/v1/occurrences/{id}/history", occurrenceId)
                        .with(user(owner, "CIDADAO")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.items[1].action").value("REVISAO_IA"))
                .andExpect(jsonPath("$.items[1].fromStatus").value("ABERTA"))
                .andExpect(jsonPath("$.items[1].toStatus").value("EM_TRIAGEM"))
                .andExpect(jsonPath("$.items[1].note").value("Classificação confirmada."));
    }

    private Category category() {
        return categoryRepository.saveAndFlush(
                new Category("VIAS", "Vias e buracos", null));
    }

    private UUID createOccurrence(UUID owner, UUID categoryId) throws Exception {
        var result = mockMvc.perform(post("/api/v1/occurrences")
                        .with(user(owner, "CIDADAO"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody(categoryId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("ABERTA"))
                .andExpect(jsonPath("$.version").value(0))
                .andExpect(jsonPath("$.createdAt").isNotEmpty())
                .andExpect(jsonPath("$.updatedAt").isNotEmpty())
                .andReturn();
        return UUID.fromString(com.jayway.jsonpath.JsonPath
                .parse(result.getResponse().getContentAsString())
                .read("$.id", String.class));
    }

    private static org.springframework.test.web.servlet.request.RequestPostProcessor user(
            UUID id,
            String role) {
        return jwt()
                .jwt(builder -> builder
                        .subject(id.toString())
                        .claim("roles", java.util.List.of(role)))
                .authorities(new SimpleGrantedAuthority("ROLE_" + role));
    }

    private static String createBody(UUID categoryId) {
        return """
                {
                  "title":"Buraco na faixa direita",
                  "description":"Buraco profundo próximo à faixa de pedestres.",
                  "categoryId":"%s",
                  "priority":"ALTA",
                  "address":{
                    "street":"Rua Exemplo","number":"100","district":"Centro",
                    "city":"São Paulo","state":"SP","postalCode":"01000-000"
                  }
                }
                """.formatted(categoryId);
    }

    private static String updateBody(UUID categoryId, long version) {
        return """
                {
                  "version":%d,
                  "title":"Título atualizado",
                  "description":"Descrição atualizada com tamanho suficiente para validação.",
                  "categoryId":"%s",
                  "priority":"MEDIA",
                  "address":{
                    "street":"Rua Exemplo","number":"101","district":"Centro",
                    "city":"São Paulo","state":"SP","postalCode":"01000-000"
                  }
                }
                """.formatted(version, categoryId);
    }

    private static Path createPublicKey() {
        try {
            var generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            var publicKey = generator.generateKeyPair().getPublic();
            var directory = Path.of("target", "test-keys");
            Files.createDirectories(directory);
            var path = directory.resolve("api-integration-public.pem").toAbsolutePath();
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
