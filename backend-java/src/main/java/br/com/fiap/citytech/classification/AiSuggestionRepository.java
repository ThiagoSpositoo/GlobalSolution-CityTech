package br.com.fiap.citytech.classification;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiSuggestionRepository extends JpaRepository<AiSuggestion, UUID> {

    Optional<AiSuggestion> findByOccurrenceId(UUID occurrenceId);
}
