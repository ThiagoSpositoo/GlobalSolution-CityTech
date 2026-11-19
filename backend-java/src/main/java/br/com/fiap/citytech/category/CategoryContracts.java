package br.com.fiap.citytech.category;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public final class CategoryContracts {

    private CategoryContracts() {
    }

    public record CreateRequest(
            @NotBlank
            @Size(max = 40)
            @Pattern(regexp = "^[A-Za-z0-9_]+$")
            String code,
            @NotBlank @Size(max = 80) String name,
            @Size(max = 255) String description) {
    }

    public record UpdateRequest(
            @NotBlank
            @Size(max = 40)
            @Pattern(regexp = "^[A-Za-z0-9_]+$")
            String code,
            @NotBlank @Size(max = 80) String name,
            @Size(max = 255) String description) {
    }

    public record Response(
            UUID id,
            String code,
            String name,
            String description,
            boolean active,
            Instant createdAt,
            Instant updatedAt) {

        public static Response from(Category category) {
            return new Response(
                    category.getId(),
                    category.getCode(),
                    category.getName(),
                    category.getDescription(),
                    category.isActive(),
                    category.getCreatedAt(),
                    category.getUpdatedAt());
        }
    }

    public record Summary(UUID id, String code, String name) {

        public static Summary from(Category category) {
            return new Summary(category.getId(), category.getCode(), category.getName());
        }
    }
}
