package br.com.fiap.citytech.occurrence;

import br.com.fiap.citytech.category.CategoryContracts;
import br.com.fiap.citytech.classification.AiDecision;
import br.com.fiap.citytech.classification.AiSuggestion;
import br.com.fiap.citytech.classification.AiSuggestionStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public final class OccurrenceContracts {

    private OccurrenceContracts() {
    }

    public record AddressRequest(
            @NotBlank @Size(max = 160) String street,
            @NotBlank @Size(max = 20) String number,
            @Size(max = 80) String complement,
            @NotBlank @Size(max = 100) String district,
            @NotBlank @Size(max = 100) String city,
            @NotBlank @Pattern(regexp = "^[A-Za-z]{2}$") String state,
            @Pattern(regexp = "^\\d{5}-\\d{3}$") String postalCode) {

        Address toEntity() {
            return new Address(
                    street,
                    number,
                    complement,
                    district,
                    city,
                    state,
                    postalCode);
        }
    }

    public record CreateRequest(
            @NotBlank @Size(min = 5, max = 120) String title,
            @NotBlank @Size(min = 20, max = 2000) String description,
            @NotNull UUID categoryId,
            Priority priority,
            @NotNull @Valid AddressRequest address) {
    }

    public record UpdateRequest(
            @NotNull Long version,
            @NotBlank @Size(min = 5, max = 120) String title,
            @NotBlank @Size(min = 20, max = 2000) String description,
            @NotNull UUID categoryId,
            Priority priority,
            @NotNull @Valid AddressRequest address) {
    }

    public record TriageRequest(
            @NotNull Long version,
            UUID categoryId,
            Priority priority,
            @Size(max = 500) String note) {
    }

    public record StatusRequest(
            @NotNull Long version,
            @NotNull OccurrenceStatus status,
            @Size(max = 500) String note,
            @Size(max = 255) String reason) {
    }

    public record ReviewRequest(
            @NotNull Long version,
            @NotNull AiDecision decision,
            @Size(max = 500) String note) {
    }

    public record AiSuggestionResponse(
            AiSuggestionStatus status,
            CategoryContracts.Summary suggestedCategory,
            Priority suggestedPriority,
            String summary,
            String justification,
            java.util.List<String> sources,
            String model,
            String promptVersion,
            String errorCode,
            Instant reviewedAt,
            AiDecision decision) {

        static AiSuggestionResponse from(
                AiSuggestion suggestion,
                tools.jackson.databind.ObjectMapper objectMapper) {
            java.util.List<String> sources = null;
            if (suggestion.getSourcesJson() != null) {
                sources = objectMapper.readValue(
                        suggestion.getSourcesJson(),
                        objectMapper.getTypeFactory()
                                .constructCollectionType(java.util.List.class, String.class));
            }
            return new AiSuggestionResponse(
                    suggestion.getStatus(),
                    suggestion.getSuggestedCategory() == null
                            ? null
                            : CategoryContracts.Summary.from(suggestion.getSuggestedCategory()),
                    suggestion.getSuggestedPriority(),
                    suggestion.getSummary(),
                    suggestion.getJustification(),
                    sources,
                    suggestion.getModel(),
                    suggestion.getPromptVersion(),
                    suggestion.getErrorCode(),
                    suggestion.getReviewedAt(),
                    suggestion.getDecision());
        }
    }

    public record AddressResponse(
            String street,
            String number,
            String complement,
            String district,
            String city,
            String state,
            String postalCode) {

        static AddressResponse from(Address address) {
            return new AddressResponse(
                    address.getStreet(),
                    address.getNumber(),
                    address.getComplement(),
                    address.getDistrict(),
                    address.getCity(),
                    address.getState(),
                    address.getPostalCode());
        }
    }

    public record Response(
            UUID id,
            UUID citizenId,
            String title,
            String description,
            CategoryContracts.Summary category,
            Priority priority,
            OccurrenceStatus status,
            AddressResponse address,
            long version,
            Instant createdAt,
            Instant updatedAt,
            AiSuggestionResponse aiSuggestion) {

        public static Response from(Occurrence occurrence) {
            return new Response(
                    occurrence.getId(),
                    occurrence.getCitizenId(),
                    occurrence.getTitle(),
                    occurrence.getDescription(),
                    CategoryContracts.Summary.from(occurrence.getCategory()),
                    occurrence.getPriority(),
                    occurrence.getStatus(),
                    AddressResponse.from(occurrence.getAddress()),
                    occurrence.getVersion(),
                    occurrence.getCreatedAt(),
                    occurrence.getUpdatedAt(),
                    null);
        }

        public static Response from(
                Occurrence occurrence,
                AiSuggestion suggestion,
                tools.jackson.databind.ObjectMapper objectMapper) {
            var base = from(occurrence);
            return new Response(
                    base.id(),
                    base.citizenId(),
                    base.title(),
                    base.description(),
                    base.category(),
                    base.priority(),
                    base.status(),
                    base.address(),
                    base.version(),
                    base.createdAt(),
                    base.updatedAt(),
                    suggestion == null ? null : AiSuggestionResponse.from(suggestion, objectMapper));
        }
    }

    public record Summary(
            UUID id,
            String title,
            CategoryContracts.Summary category,
            Priority priority,
            OccurrenceStatus status,
            AddressSummary address,
            Instant createdAt,
            Instant updatedAt,
            String aiSuggestionStatus) {

        public static Summary from(Occurrence occurrence) {
            var address = occurrence.getAddress();
            return new Summary(
                    occurrence.getId(),
                    occurrence.getTitle(),
                    CategoryContracts.Summary.from(occurrence.getCategory()),
                    occurrence.getPriority(),
                    occurrence.getStatus(),
                    new AddressSummary(
                            address.getDistrict(),
                            address.getCity(),
                            address.getState()),
                    occurrence.getCreatedAt(),
                    occurrence.getUpdatedAt(),
                    null);
        }
    }

    public record AddressSummary(String district, String city, String state) {
    }
}
