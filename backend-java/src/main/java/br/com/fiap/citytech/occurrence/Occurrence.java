package br.com.fiap.citytech.occurrence;

import br.com.fiap.citytech.category.Category;
import jakarta.persistence.Column;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "occurrences")
public class Occurrence {

    @Id
    private UUID id;

    @Column(name = "citizen_id", nullable = false)
    private UUID citizenId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false, length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Priority priority;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OccurrenceStatus status;

    @Embedded
    private Address address;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    @Column(name = "cancellation_reason", length = 255)
    private String cancellationReason;

    protected Occurrence() {
    }

    public Occurrence(
            UUID citizenId,
            Category category,
            String title,
            String description,
            Priority priority,
            Address address) {
        this.id = UUID.randomUUID();
        this.citizenId = java.util.Objects.requireNonNull(citizenId);
        this.category = java.util.Objects.requireNonNull(category);
        this.title = required(title);
        this.description = required(description);
        this.priority = priority == null ? Priority.MEDIA : priority;
        this.status = OccurrenceStatus.ABERTA;
        this.address = java.util.Objects.requireNonNull(address);
    }

    public void edit(
            Category category,
            String title,
            String description,
            Priority priority,
            Address address) {
        requireStatus(OccurrenceStatus.ABERTA);
        this.category = java.util.Objects.requireNonNull(category);
        this.title = required(title);
        this.description = required(description);
        this.priority = priority == null ? Priority.MEDIA : priority;
        this.address = java.util.Objects.requireNonNull(address);
    }

    public void triage(Category category, Priority priority) {
        if (isTerminal()) {
            throw new IllegalStateException("Ocorrência terminal não pode ser triada.");
        }
        if (status == OccurrenceStatus.ABERTA) {
            transitionTo(OccurrenceStatus.EM_TRIAGEM, null);
        }
        if (category != null) {
            this.category = category;
        }
        if (priority != null) {
            this.priority = priority;
        }
    }

    public void transitionTo(OccurrenceStatus target, String reason) {
        if (!isAllowedTransition(status, target)) {
            throw new IllegalStateException("Transição de status não permitida.");
        }
        if (target == OccurrenceStatus.CANCELADA) {
            if (reason == null || reason.isBlank()) {
                throw new IllegalArgumentException("Motivo do cancelamento é obrigatório.");
            }
            cancelledAt = Instant.now();
            cancellationReason = reason.trim();
        }
        status = target;
    }

    public boolean isOwner(UUID userId) {
        return citizenId.equals(userId);
    }

    public boolean isTerminal() {
        return status == OccurrenceStatus.ENCERRADA || status == OccurrenceStatus.CANCELADA;
    }

    @PrePersist
    void onCreate() {
        var now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getCitizenId() {
        return citizenId;
    }

    public Category getCategory() {
        return category;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public Priority getPriority() {
        return priority;
    }

    public OccurrenceStatus getStatus() {
        return status;
    }

    public Address getAddress() {
        return address;
    }

    public long getVersion() {
        return version;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Instant getCancelledAt() {
        return cancelledAt;
    }

    public String getCancellationReason() {
        return cancellationReason;
    }

    private void requireStatus(OccurrenceStatus required) {
        if (status != required) {
            throw new IllegalStateException("Operação não permitida no estado atual.");
        }
    }

    private static boolean isAllowedTransition(OccurrenceStatus from, OccurrenceStatus to) {
        return switch (from) {
            case ABERTA -> to == OccurrenceStatus.EM_TRIAGEM
                    || to == OccurrenceStatus.CANCELADA;
            case EM_TRIAGEM -> to == OccurrenceStatus.EM_ANDAMENTO
                    || to == OccurrenceStatus.CANCELADA;
            case EM_ANDAMENTO -> to == OccurrenceStatus.RESOLVIDA
                    || to == OccurrenceStatus.CANCELADA;
            case RESOLVIDA -> to == OccurrenceStatus.ENCERRADA
                    || to == OccurrenceStatus.EM_ANDAMENTO;
            case ENCERRADA, CANCELADA -> false;
        };
    }

    private static String required(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Texto obrigatório.");
        }
        return value.trim();
    }
}
