package br.com.fiap.citytech.messaging;

import br.com.fiap.citytech.occurrence.Occurrence;
import br.com.fiap.citytech.occurrence.Priority;
import java.time.Instant;
import java.util.UUID;

public record OccurrenceCreatedEvent(
        UUID eventId,
        String eventType,
        int schemaVersion,
        Instant occurredAt,
        UUID occurrenceId,
        UUID citizenId,
        UUID categoryId,
        String title,
        String description,
        Priority priority,
        AddressData address) {

    public static OccurrenceCreatedEvent from(UUID eventId, Instant occurredAt, Occurrence occurrence) {
        var address = occurrence.getAddress();
        return new OccurrenceCreatedEvent(
                eventId,
                "OccurrenceCreated",
                1,
                occurredAt,
                occurrence.getId(),
                occurrence.getCitizenId(),
                occurrence.getCategory().getId(),
                occurrence.getTitle(),
                occurrence.getDescription(),
                occurrence.getPriority(),
                new AddressData(address.getDistrict(), address.getCity(), address.getState()));
    }

    public record AddressData(String district, String city, String state) {
    }
}
