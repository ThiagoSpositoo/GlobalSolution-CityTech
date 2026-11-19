package br.com.fiap.citytech.history;

import br.com.fiap.citytech.occurrence.Occurrence;
import br.com.fiap.citytech.occurrence.OccurrenceStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "status_history")
public class StatusHistory {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "occurrence_id", nullable = false, updatable = false)
    private Occurrence occurrence;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, updatable = false)
    private HistoryAction action;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_status", length = 20, updatable = false)
    private OccurrenceStatus fromStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "to_status", length = 20, updatable = false)
    private OccurrenceStatus toStatus;

    @Column(name = "actor_id", nullable = false, updatable = false)
    private UUID actorId;

    @Enumerated(EnumType.STRING)
    @Column(name = "actor_role", nullable = false, length = 10, updatable = false)
    private ActorRole actorRole;

    @Column(length = 500, updatable = false)
    private String note;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected StatusHistory() {
    }

    public StatusHistory(
            Occurrence occurrence,
            HistoryAction action,
            OccurrenceStatus fromStatus,
            OccurrenceStatus toStatus,
            UUID actorId,
            ActorRole actorRole,
            String note) {
        this.id = UUID.randomUUID();
        this.occurrence = java.util.Objects.requireNonNull(occurrence);
        this.action = java.util.Objects.requireNonNull(action);
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.actorId = java.util.Objects.requireNonNull(actorId);
        this.actorRole = java.util.Objects.requireNonNull(actorRole);
        this.note = note == null || note.isBlank() ? null : note.trim();
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

    public HistoryAction getAction() {
        return action;
    }

    public OccurrenceStatus getFromStatus() {
        return fromStatus;
    }

    public OccurrenceStatus getToStatus() {
        return toStatus;
    }

    public UUID getActorId() {
        return actorId;
    }

    public ActorRole getActorRole() {
        return actorRole;
    }

    public String getNote() {
        return note;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
