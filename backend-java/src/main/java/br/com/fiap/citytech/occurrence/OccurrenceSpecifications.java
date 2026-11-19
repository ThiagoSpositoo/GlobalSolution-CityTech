package br.com.fiap.citytech.occurrence;

import java.util.UUID;
import org.springframework.data.jpa.domain.Specification;

final class OccurrenceSpecifications {

    private OccurrenceSpecifications() {
    }

    static Specification<Occurrence> visibleTo(UUID citizenId) {
        return (root, query, builder) ->
                citizenId == null ? builder.conjunction() : builder.equal(root.get("citizenId"), citizenId);
    }

    static Specification<Occurrence> status(OccurrenceStatus status) {
        return (root, query, builder) ->
                status == null ? builder.conjunction() : builder.equal(root.get("status"), status);
    }

    static Specification<Occurrence> category(UUID categoryId) {
        return (root, query, builder) -> categoryId == null
                ? builder.conjunction()
                : builder.equal(root.get("category").get("id"), categoryId);
    }

    static Specification<Occurrence> priority(Priority priority) {
        return (root, query, builder) ->
                priority == null ? builder.conjunction() : builder.equal(root.get("priority"), priority);
    }

    static Specification<Occurrence> text(String text) {
        return (root, query, builder) -> {
            if (text == null || text.isBlank()) {
                return builder.conjunction();
            }
            var pattern = "%" + text.trim().toLowerCase(java.util.Locale.ROOT) + "%";
            return builder.or(
                    builder.like(builder.lower(root.get("title")), pattern),
                    builder.like(builder.lower(root.get("description")), pattern));
        };
    }
}
