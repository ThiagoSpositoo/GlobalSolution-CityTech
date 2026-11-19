package br.com.fiap.citytech.history;

import br.com.fiap.citytech.occurrence.OccurrenceStatus;
import java.time.Instant;
import java.util.UUID;

public record HistoryResponse(
        UUID id,
        HistoryAction action,
        OccurrenceStatus fromStatus,
        OccurrenceStatus toStatus,
        UUID actorId,
        ActorRole actorRole,
        String note,
        Instant createdAt) {

    public static HistoryResponse from(StatusHistory history) {
        return new HistoryResponse(
                history.getId(),
                history.getAction(),
                history.getFromStatus(),
                history.getToStatus(),
                history.getActorId(),
                history.getActorRole(),
                history.getNote(),
                history.getCreatedAt());
    }
}
