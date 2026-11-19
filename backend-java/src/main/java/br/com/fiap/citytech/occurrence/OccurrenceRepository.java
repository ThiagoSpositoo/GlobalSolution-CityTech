package br.com.fiap.citytech.occurrence;

import java.util.UUID;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;

public interface OccurrenceRepository
        extends JpaRepository<Occurrence, UUID>, JpaSpecificationExecutor<Occurrence> {

    @Query("select o.status, count(o) from Occurrence o group by o.status")
    List<Object[]> countGroupedByStatus();

    @Query("select o.category.code, count(o) from Occurrence o group by o.category.code")
    List<Object[]> countGroupedByCategory();
}
