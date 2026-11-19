package br.com.fiap.citytech.classification;

import br.com.fiap.citytech.category.Category;
import br.com.fiap.citytech.occurrence.Occurrence;
import br.com.fiap.citytech.occurrence.Priority;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_suggestions")
public class AiSuggestion {

    @Id
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "occurrence_id", nullable = false, unique = true, updatable = false)
    private Occurrence occurrence;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private AiSuggestionStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suggested_category_id")
    private Category suggestedCategory;

    @Enumerated(EnumType.STRING)
    @Column(name = "suggested_priority", length = 10)
    private Priority suggestedPriority;

    @Column(length = 500)
    private String summary;

    @Column(length = 2000)
    private String justification;

    @Lob
    @Column(name = "sources_json")
    private String sourcesJson;

    @Column(length = 100)
    private String model;

    @Column(name = "prompt_version", length = 40)
    private String promptVersion;

    @Column(name = "error_code", length = 60)
    private String errorCode;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    @Column(name = "reviewed_by")
    private UUID reviewedBy;

    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private AiDecision decision;

    @Column(name = "review_note", length = 500)
    private String reviewNote;

    protected AiSuggestion() {
    }

    public AiSuggestion(Occurrence occurrence) {
        this.id = UUID.randomUUID();
        this.occurrence = java.util.Objects.requireNonNull(occurrence);
        this.status = AiSuggestionStatus.PENDENTE;
    }

    public void ready(
            Category category,
            Priority priority,
            String summary,
            String justification,
            String sourcesJson,
            String model,
            String promptVersion) {
        this.suggestedCategory = java.util.Objects.requireNonNull(category);
        this.suggestedPriority = java.util.Objects.requireNonNull(priority);
        this.summary = required(summary, 500);
        this.justification = required(justification, 2000);
        this.sourcesJson = java.util.Objects.requireNonNull(sourcesJson);
        this.model = required(model, 100);
        this.promptVersion = required(promptVersion, 40);
        this.errorCode = null;
        this.status = AiSuggestionStatus.PRONTA;
    }

    public void fail(String errorCode) {
        this.errorCode = required(errorCode, 60);
        this.status = AiSuggestionStatus.FALHOU;
    }

    public void review(AiDecision decision, UUID userId, String note) {
        if (status != AiSuggestionStatus.PRONTA) {
            throw new IllegalStateException("A sugestão não está pronta para revisão.");
        }
        this.decision = java.util.Objects.requireNonNull(decision);
        this.reviewedBy = java.util.Objects.requireNonNull(userId);
        this.reviewedAt = Instant.now();
        this.reviewNote = note == null || note.isBlank() ? null : note.trim();
        this.status = decision == AiDecision.ACEITAR
                ? AiSuggestionStatus.ACEITA
                : AiSuggestionStatus.REJEITADA;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public Occurrence getOccurrence() {
        return occurrence;
    }

    public AiSuggestionStatus getStatus() {
        return status;
    }

    public Category getSuggestedCategory() {
        return suggestedCategory;
    }

    public Priority getSuggestedPriority() {
        return suggestedPriority;
    }

    public String getSummary() {
        return summary;
    }

    public String getJustification() {
        return justification;
    }

    public String getSourcesJson() {
        return sourcesJson;
    }

    public String getModel() {
        return model;
    }

    public String getPromptVersion() {
        return promptVersion;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getReviewedAt() {
        return reviewedAt;
    }

    public UUID getReviewedBy() {
        return reviewedBy;
    }

    public AiDecision getDecision() {
        return decision;
    }

    public String getReviewNote() {
        return reviewNote;
    }

    private static String required(String value, int max) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Texto obrigatório.");
        }
        var normalized = value.trim();
        if (normalized.length() > max) {
            throw new IllegalArgumentException("Texto excede o limite.");
        }
        return normalized;
    }
}
