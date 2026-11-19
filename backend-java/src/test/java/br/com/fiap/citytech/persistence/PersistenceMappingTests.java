package br.com.fiap.citytech.persistence;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import br.com.fiap.citytech.category.Category;
import br.com.fiap.citytech.category.CategoryRepository;
import br.com.fiap.citytech.history.ActorRole;
import br.com.fiap.citytech.history.HistoryAction;
import br.com.fiap.citytech.history.StatusHistory;
import br.com.fiap.citytech.history.StatusHistoryRepository;
import br.com.fiap.citytech.occurrence.Address;
import br.com.fiap.citytech.occurrence.Occurrence;
import br.com.fiap.citytech.occurrence.OccurrenceRepository;
import br.com.fiap.citytech.occurrence.OccurrenceStatus;
import br.com.fiap.citytech.occurrence.Priority;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;

@DataJpaTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:citytech-jpa;MODE=Oracle;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.jpa.properties.hibernate.jdbc.time_zone=UTC"
})
class PersistenceMappingTests {

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private OccurrenceRepository occurrenceRepository;

    @Autowired
    private StatusHistoryRepository historyRepository;

    @Test
    void persistsRelationshipsAndAuditTimestamps() {
        var actorId = UUID.randomUUID();
        var category = categoryRepository.saveAndFlush(
                new Category("VIAS", "Vias e buracos", "Problemas de pavimentação"));
        var occurrence = occurrenceRepository.saveAndFlush(new Occurrence(
                actorId,
                category,
                "Buraco na faixa direita",
                "Buraco profundo próximo à faixa de pedestres.",
                Priority.ALTA,
                address()));
        historyRepository.saveAndFlush(new StatusHistory(
                occurrence,
                HistoryAction.CRIACAO,
                null,
                OccurrenceStatus.ABERTA,
                actorId,
                ActorRole.CIDADAO,
                null));

        var reloaded = occurrenceRepository.findById(occurrence.getId()).orElseThrow();
        var history = historyRepository
                .findAllByOccurrenceIdOrderByCreatedAtAsc(
                        occurrence.getId(),
                        org.springframework.data.domain.PageRequest.of(0, 20))
                .getContent();

        assertEquals(category.getId(), reloaded.getCategory().getId());
        assertEquals("Centro", reloaded.getAddress().getDistrict());
        assertEquals(1, history.size());
        assertEquals(reloaded.getId(), history.getFirst().getOccurrence().getId());
        assertNotNull(reloaded.getCreatedAt());
        assertNotNull(history.getFirst().getCreatedAt());
    }

    @Test
    void executesIndicatorQueriesAgainstMappedSchema() {
        var category = categoryRepository.saveAndFlush(
                new Category("ILUMINACAO", "Iluminação", null));
        occurrenceRepository.saveAndFlush(new Occurrence(
                UUID.randomUUID(),
                category,
                "Poste apagado na praça",
                "Poste sem iluminação durante todo o período noturno.",
                Priority.MEDIA,
                address()));

        var byStatus = occurrenceRepository.countGroupedByStatus();
        var byCategory = occurrenceRepository.countGroupedByCategory();

        assertEquals(OccurrenceStatus.ABERTA, byStatus.getFirst()[0]);
        assertEquals(1L, byStatus.getFirst()[1]);
        assertEquals("ILUMINACAO", byCategory.getFirst()[0]);
        assertEquals(1L, byCategory.getFirst()[1]);
    }

    private static Address address() {
        return new Address(
                "Rua Exemplo",
                "100",
                null,
                "Centro",
                "São Paulo",
                "SP",
                "01000-000");
    }
}
