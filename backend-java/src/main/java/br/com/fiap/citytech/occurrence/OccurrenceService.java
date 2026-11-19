package br.com.fiap.citytech.occurrence;

import br.com.fiap.citytech.category.CategoryService;
import br.com.fiap.citytech.classification.AiDecision;
import br.com.fiap.citytech.classification.AiSuggestionRepository;
import br.com.fiap.citytech.classification.AiSuggestionStatus;
import br.com.fiap.citytech.common.ApiException;
import br.com.fiap.citytech.common.PageResponse;
import br.com.fiap.citytech.history.ActorRole;
import br.com.fiap.citytech.history.HistoryAction;
import br.com.fiap.citytech.history.HistoryResponse;
import br.com.fiap.citytech.history.StatusHistory;
import br.com.fiap.citytech.history.StatusHistoryRepository;
import br.com.fiap.citytech.messaging.OccurrenceCreatedEvent;
import br.com.fiap.citytech.messaging.OutboxEvent;
import br.com.fiap.citytech.messaging.OutboxEventRepository;
import br.com.fiap.citytech.security.AuthenticatedUser;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OccurrenceService {

    private static final Set<String> SORT_FIELDS =
            Set.of("createdAt", "updatedAt", "priority", "status", "title");

    private final OccurrenceRepository repository;
    private final StatusHistoryRepository historyRepository;
    private final CategoryService categoryService;
    private final OutboxEventRepository outboxRepository;
    private final tools.jackson.databind.ObjectMapper objectMapper;
    private final AiSuggestionRepository suggestionRepository;

    public OccurrenceService(
            OccurrenceRepository repository,
            StatusHistoryRepository historyRepository,
            CategoryService categoryService,
            OutboxEventRepository outboxRepository,
            tools.jackson.databind.ObjectMapper objectMapper,
            AiSuggestionRepository suggestionRepository) {
        this.repository = repository;
        this.historyRepository = historyRepository;
        this.categoryService = categoryService;
        this.outboxRepository = outboxRepository;
        this.objectMapper = objectMapper;
        this.suggestionRepository = suggestionRepository;
    }

    @Transactional
    public OccurrenceContracts.Response create(
            OccurrenceContracts.CreateRequest request,
            AuthenticatedUser user) {
        var category = categoryService.active(request.categoryId());
        var occurrence = repository.save(new Occurrence(
                user.id(),
                category,
                request.title(),
                request.description(),
                request.priority(),
                request.address().toEntity()));
        historyRepository.save(history(
                occurrence,
                HistoryAction.CRIACAO,
                null,
                OccurrenceStatus.ABERTA,
                user,
                null));
        var eventId = UUID.randomUUID();
        var occurredAt = Instant.now();
        var event = OccurrenceCreatedEvent.from(eventId, occurredAt, occurrence);
        outboxRepository.save(new OutboxEvent(
                eventId,
                occurrence.getId(),
                event.eventType(),
                event.schemaVersion(),
                objectMapper.writeValueAsString(event),
                occurredAt));
        repository.flush();
        return OccurrenceContracts.Response.from(occurrence);
    }

    @Transactional(readOnly = true)
    public PageResponse<OccurrenceContracts.Summary> list(
            OccurrenceStatus status,
            UUID categoryId,
            Priority priority,
            String text,
            int page,
            int size,
            String sort,
            AuthenticatedUser user) {
        var pageable = pageRequest(page, size, sort);
        Specification<Occurrence> specification = Specification
                .where(OccurrenceSpecifications.visibleTo(user.isManager() ? null : user.id()))
                .and(OccurrenceSpecifications.status(status))
                .and(OccurrenceSpecifications.category(categoryId))
                .and(OccurrenceSpecifications.priority(priority))
                .and(OccurrenceSpecifications.text(text));
        return PageResponse.from(repository.findAll(specification, pageable)
                .map(OccurrenceContracts.Summary::from));
    }

    @Transactional(readOnly = true)
    public OccurrenceContracts.Response get(UUID id, AuthenticatedUser user) {
        var occurrence = visible(id, user);
        var suggestion = suggestionRepository.findByOccurrenceId(id).orElse(null);
        return OccurrenceContracts.Response.from(occurrence, suggestion, objectMapper);
    }

    @Transactional
    public OccurrenceContracts.Response update(
            UUID id,
            OccurrenceContracts.UpdateRequest request,
            AuthenticatedUser user) {
        var occurrence = visible(id, user);
        requireOwner(occurrence, user);
        requireVersion(occurrence, request.version());
        var category = categoryService.active(request.categoryId());
        try {
            occurrence.edit(
                    category,
                    request.title(),
                    request.description(),
                    request.priority(),
                    request.address().toEntity());
        } catch (IllegalStateException exception) {
            throw invalidTransition(exception.getMessage());
        }
        historyRepository.save(history(
                occurrence,
                HistoryAction.EDICAO,
                occurrence.getStatus(),
                occurrence.getStatus(),
                user,
                null));
        repository.flush();
        return OccurrenceContracts.Response.from(occurrence);
    }

    @Transactional
    public OccurrenceContracts.Response triage(
            UUID id,
            OccurrenceContracts.TriageRequest request,
            AuthenticatedUser user) {
        if (request.categoryId() == null
                && request.priority() == null
                && (request.note() == null || request.note().isBlank())) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "Requisição inválida",
                    "Informe categoria, prioridade ou nota.");
        }
        var occurrence = visible(id, user);
        requireVersion(occurrence, request.version());
        var category = request.categoryId() == null
                ? null
                : categoryService.active(request.categoryId());
        var before = occurrence.getStatus();
        try {
            occurrence.triage(category, request.priority());
        } catch (IllegalStateException exception) {
            throw invalidTransition(exception.getMessage());
        }
        historyRepository.save(history(
                occurrence,
                HistoryAction.TRIAGEM,
                before,
                occurrence.getStatus(),
                user,
                request.note()));
        repository.flush();
        return OccurrenceContracts.Response.from(occurrence);
    }

    @Transactional
    public OccurrenceContracts.Response transition(
            UUID id,
            OccurrenceContracts.StatusRequest request,
            AuthenticatedUser user) {
        var occurrence = visible(id, user);
        requireVersion(occurrence, request.version());
        authorizeTransition(occurrence, request.status(), user);
        var before = occurrence.getStatus();
        try {
            occurrence.transitionTo(request.status(), request.reason());
        } catch (IllegalArgumentException exception) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "Requisição inválida",
                    exception.getMessage());
        } catch (IllegalStateException exception) {
            throw invalidTransition(exception.getMessage());
        }
        var action = request.status() == OccurrenceStatus.CANCELADA
                ? HistoryAction.CANCELAMENTO
                : HistoryAction.TRANSICAO;
        var note = request.status() == OccurrenceStatus.CANCELADA
                ? request.reason()
                : request.note();
        historyRepository.save(history(
                occurrence,
                action,
                before,
                request.status(),
                user,
                note));
        repository.flush();
        return OccurrenceContracts.Response.from(occurrence);
    }

    @Transactional
    public void cancel(UUID id, long version, String reason, AuthenticatedUser user) {
        var occurrence = visible(id, user);
        requireVersion(occurrence, version);
        authorizeTransition(occurrence, OccurrenceStatus.CANCELADA, user);
        var before = occurrence.getStatus();
        try {
            occurrence.transitionTo(OccurrenceStatus.CANCELADA, reason);
        } catch (IllegalArgumentException exception) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "Requisição inválida",
                    exception.getMessage());
        } catch (IllegalStateException exception) {
            throw invalidTransition(exception.getMessage());
        }
        historyRepository.save(history(
                occurrence,
                HistoryAction.CANCELAMENTO,
                before,
                OccurrenceStatus.CANCELADA,
                user,
                reason));
    }

    @Transactional(readOnly = true)
    public PageResponse<HistoryResponse> history(
            UUID id,
            int page,
            int size,
            AuthenticatedUser user) {
        visible(id, user);
        validatePage(page, size);
        return PageResponse.from(historyRepository
                .findAllByOccurrenceIdOrderByCreatedAtAsc(
                        id,
                        PageRequest.of(page, size))
                .map(HistoryResponse::from));
    }

    @Transactional
    public OccurrenceContracts.Response reviewSuggestion(
            UUID id,
            OccurrenceContracts.ReviewRequest request,
            AuthenticatedUser user) {
        var occurrence = visible(id, user);
        requireVersion(occurrence, request.version());
        var suggestion = suggestionRepository.findByOccurrenceId(id)
                .orElseThrow(() -> new ApiException(
                        HttpStatus.CONFLICT,
                        "AI_SUGGESTION_NOT_READY",
                        "Sugestão indisponível",
                        "Não existe sugestão pronta para revisão."));
        if (suggestion.getStatus() != AiSuggestionStatus.PRONTA) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    suggestion.getReviewedAt() == null
                            ? "AI_SUGGESTION_NOT_READY"
                            : "ALREADY_REVIEWED",
                    "Sugestão indisponível",
                    "A sugestão não está pronta para revisão.");
        }
        var before = occurrence.getStatus();
        if (request.decision() == AiDecision.ACEITAR) {
            try {
                occurrence.triage(
                        suggestion.getSuggestedCategory(),
                        suggestion.getSuggestedPriority());
            } catch (IllegalStateException exception) {
                throw invalidTransition(exception.getMessage());
            }
        }
        suggestion.review(request.decision(), user.id(), request.note());
        historyRepository.save(history(
                occurrence,
                HistoryAction.REVISAO_IA,
                before,
                occurrence.getStatus(),
                user,
                request.note()));
        repository.flush();
        return OccurrenceContracts.Response.from(occurrence, suggestion, objectMapper);
    }

    private Occurrence visible(UUID id, AuthenticatedUser user) {
        var occurrence = repository.findById(id).orElseThrow(OccurrenceService::notFound);
        if (!user.isManager() && !occurrence.isOwner(user.id())) {
            throw notFound();
        }
        return occurrence;
    }

    private static void requireOwner(Occurrence occurrence, AuthenticatedUser user) {
        if (!occurrence.isOwner(user.id())) {
            throw notFound();
        }
    }

    private static void requireVersion(Occurrence occurrence, long version) {
        if (occurrence.getVersion() != version) {
            throw new ApiException(
                    HttpStatus.CONFLICT,
                    "CONCURRENT_MODIFICATION",
                    "Conflito de alteração",
                    "A versão informada está desatualizada.");
        }
    }

    private static void authorizeTransition(
            Occurrence occurrence,
            OccurrenceStatus target,
            AuthenticatedUser user) {
        if (user.isManager()) {
            return;
        }
        if (!occurrence.isOwner(user.id())) {
            throw notFound();
        }
        var allowedCitizen = (occurrence.getStatus() == OccurrenceStatus.ABERTA
                        && target == OccurrenceStatus.CANCELADA)
                || (occurrence.getStatus() == OccurrenceStatus.RESOLVIDA
                        && (target == OccurrenceStatus.ENCERRADA
                                || target == OccurrenceStatus.EM_ANDAMENTO));
        if (!allowedCitizen) {
            throw new ApiException(
                    HttpStatus.FORBIDDEN,
                    "FORBIDDEN",
                    "Acesso negado",
                    "O papel atual não pode realizar esta transição.");
        }
    }

    private static StatusHistory history(
            Occurrence occurrence,
            HistoryAction action,
            OccurrenceStatus from,
            OccurrenceStatus to,
            AuthenticatedUser user,
            String note) {
        return new StatusHistory(
                occurrence,
                action,
                from,
                to,
                user.id(),
                user.isManager() ? ActorRole.GESTOR : ActorRole.CIDADAO,
                note);
    }

    private static PageRequest pageRequest(int page, int size, String sortValue) {
        validatePage(page, size);
        var parts = (sortValue == null ? "createdAt,desc" : sortValue).split(",", -1);
        if (parts.length != 2
                || !SORT_FIELDS.contains(parts[0])
                || !(parts[1].equals("asc") || parts[1].equals("desc"))) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "Requisição inválida",
                    "Ordenação inválida.");
        }
        var direction = parts[1].equals("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        return PageRequest.of(page, size, Sort.by(direction, parts[0]));
    }

    private static void validatePage(int page, int size) {
        if (page < 0 || size < 1 || size > 100) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "Requisição inválida",
                    "Paginação inválida.");
        }
    }

    private static ApiException invalidTransition(String detail) {
        return new ApiException(
                HttpStatus.CONFLICT,
                "INVALID_TRANSITION",
                "Transição inválida",
                detail);
    }

    private static ApiException notFound() {
        return new ApiException(
                HttpStatus.NOT_FOUND,
                "NOT_FOUND",
                "Não encontrado",
                "A ocorrência não existe ou não está visível.");
    }
}
