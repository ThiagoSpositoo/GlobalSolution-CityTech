package br.com.fiap.citytech.messaging;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "outbox_events")
public class OutboxEvent {

    @Id
    private UUID id;

    @Column(name = "aggregate_id", nullable = false, updatable = false)
    private UUID aggregateId;

    @Column(name = "event_type", nullable = false, length = 80, updatable = false)
    private String eventType;

    @Column(name = "schema_version", nullable = false, updatable = false)
    private int schemaVersion;

    @Lob
    @Column(nullable = false, updatable = false)
    private String payload;

    @Column(name = "occurred_at", nullable = false, updatable = false)
    private Instant occurredAt;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Column(nullable = false)
    private int attempts;

    @Column(name = "last_error", length = 120)
    private String lastError;

    protected OutboxEvent() {
    }

    public OutboxEvent(
            UUID id,
            UUID aggregateId,
            String eventType,
            int schemaVersion,
            String payload,
            Instant occurredAt) {
        this.id = java.util.Objects.requireNonNull(id);
        this.aggregateId = java.util.Objects.requireNonNull(aggregateId);
        this.eventType = java.util.Objects.requireNonNull(eventType);
        this.schemaVersion = schemaVersion;
        this.payload = java.util.Objects.requireNonNull(payload);
        this.occurredAt = java.util.Objects.requireNonNull(occurredAt);
    }

    public void markPublished(Instant instant) {
        publishedAt = java.util.Objects.requireNonNull(instant);
        attempts++;
        lastError = null;
    }

    public void markFailed(String errorCode) {
        attempts++;
        lastError = errorCode == null ? "PUBLISH_FAILED" : errorCode.substring(
                0,
                Math.min(errorCode.length(), 120));
    }

    public UUID getId() {
        return id;
    }

    public UUID getAggregateId() {
        return aggregateId;
    }

    public String getEventType() {
        return eventType;
    }

    public int getSchemaVersion() {
        return schemaVersion;
    }

    public String getPayload() {
        return payload;
    }

    public Instant getOccurredAt() {
        return occurredAt;
    }

    public Instant getPublishedAt() {
        return publishedAt;
    }

    public int getAttempts() {
        return attempts;
    }

    public String getLastError() {
        return lastError;
    }
}
