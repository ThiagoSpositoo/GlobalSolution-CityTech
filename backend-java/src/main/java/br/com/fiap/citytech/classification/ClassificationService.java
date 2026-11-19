package br.com.fiap.citytech.classification;

import br.com.fiap.citytech.category.CategoryRepository;
import br.com.fiap.citytech.messaging.OccurrenceCreatedEvent;
import br.com.fiap.citytech.occurrence.OccurrenceRepository;
import java.util.HashSet;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ClassificationService {

    private final ProcessedEventRepository processedRepository;
    private final AiSuggestionRepository suggestionRepository;
    private final OccurrenceRepository occurrenceRepository;
    private final CategoryRepository categoryRepository;
    private final CorpusRetriever retriever;
    private final ObjectProvider<GenerativeClassifier> classifierProvider;
    private final tools.jackson.databind.ObjectMapper objectMapper;

    public ClassificationService(
            ProcessedEventRepository processedRepository,
            AiSuggestionRepository suggestionRepository,
            OccurrenceRepository occurrenceRepository,
            CategoryRepository categoryRepository,
            CorpusRetriever retriever,
            ObjectProvider<GenerativeClassifier> classifierProvider,
            tools.jackson.databind.ObjectMapper objectMapper) {
        this.processedRepository = processedRepository;
        this.suggestionRepository = suggestionRepository;
        this.occurrenceRepository = occurrenceRepository;
        this.categoryRepository = categoryRepository;
        this.retriever = retriever;
        this.classifierProvider = classifierProvider;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public void process(OccurrenceCreatedEvent event) {
        validate(event);
        if (processedRepository.existsById(event.eventId())) {
            return;
        }
        var occurrence = occurrenceRepository.findById(event.occurrenceId())
                .orElseThrow(() -> new IllegalStateException("Ocorrência do evento não encontrada."));
        var suggestion = suggestionRepository.findByOccurrenceId(event.occurrenceId())
                .orElseGet(() -> new AiSuggestion(occurrence));
        var context = retriever.retrieve(event, 3);
        var classifier = classifierProvider.getIfAvailable();
        if (classifier == null) {
            suggestion.fail("MODEL_NOT_CONFIGURED");
        } else {
            try {
                var result = classifier.classify(event.title(), event.description(), context);
                var category = categoryRepository.findByCodeIgnoreCase(result.categoryCode())
                        .filter(br.com.fiap.citytech.category.Category::isActive)
                        .orElseThrow(() -> new IllegalArgumentException("Categoria sugerida inválida."));
                var allowedSources = context.stream()
                        .map(CorpusRetriever.Chunk::id)
                        .collect(java.util.stream.Collectors.toSet());
                if (result.sources() == null
                        || result.sources().isEmpty()
                        || !allowedSources.containsAll(new HashSet<>(result.sources()))) {
                    throw new IllegalArgumentException("Fontes sugeridas inválidas.");
                }
                suggestion.ready(
                        category,
                        result.priority(),
                        result.summary(),
                        result.justification(),
                        objectMapper.writeValueAsString(result.sources()),
                        result.model(),
                        "rag-v1");
            } catch (RuntimeException exception) {
                suggestion.fail("MODEL_OUTPUT_INVALID");
            }
        }
        suggestionRepository.save(suggestion);
        processedRepository.save(new ProcessedEvent(event.eventId()));
    }

    private static void validate(OccurrenceCreatedEvent event) {
        if (event == null
                || event.eventId() == null
                || event.occurrenceId() == null
                || !"OccurrenceCreated".equals(event.eventType())
                || event.schemaVersion() != 1) {
            throw new IllegalArgumentException("Evento incompatível.");
        }
    }
}
