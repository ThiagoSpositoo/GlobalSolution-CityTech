package br.com.fiap.citytech.history;

import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StatusHistoryRepository extends JpaRepository<StatusHistory, UUID> {

    Page<StatusHistory> findAllByOccurrenceIdOrderByCreatedAtAsc(
            UUID occurrenceId,
            Pageable pageable);
}
