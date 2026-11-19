package br.com.fiap.citytech.occurrence;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import br.com.fiap.citytech.category.Category;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class OccurrenceTests {

    @Test
    void constructorCreatesOpenOccurrenceWithDefaultPriority() {
        var occurrence = occurrence(null);

        assertEquals(OccurrenceStatus.ABERTA, occurrence.getStatus());
        assertEquals(Priority.MEDIA, occurrence.getPriority());
        assertNotNull(occurrence.getId());
    }

    @Test
    void editIsAllowedOnlyWhileOpen() {
        var occurrence = occurrence(Priority.BAIXA);
        occurrence.transitionTo(OccurrenceStatus.EM_TRIAGEM, null);

        assertThrows(
                IllegalStateException.class,
                () -> occurrence.edit(
                        category(),
                        "Novo título",
                        "Descrição suficientemente longa para o teste.",
                        Priority.ALTA,
                        address()));
    }

    @Test
    void triageStartsFromOpenStatusAndKeepsLaterStatus() {
        var occurrence = occurrence(Priority.MEDIA);

        occurrence.triage(category(), Priority.ALTA);

        assertEquals(OccurrenceStatus.EM_TRIAGEM, occurrence.getStatus());
        assertEquals(Priority.ALTA, occurrence.getPriority());

        occurrence.triage(null, Priority.CRITICA);

        assertEquals(OccurrenceStatus.EM_TRIAGEM, occurrence.getStatus());
        assertEquals(Priority.CRITICA, occurrence.getPriority());
    }

    @Test
    void managerWorkflowFollowsStateMachine() {
        var occurrence = occurrence(Priority.MEDIA);

        occurrence.transitionTo(OccurrenceStatus.EM_TRIAGEM, null);
        occurrence.transitionTo(OccurrenceStatus.EM_ANDAMENTO, null);
        occurrence.transitionTo(OccurrenceStatus.RESOLVIDA, null);
        occurrence.transitionTo(OccurrenceStatus.ENCERRADA, null);

        assertEquals(OccurrenceStatus.ENCERRADA, occurrence.getStatus());
        assertTrue(occurrence.isTerminal());
    }

    @Test
    void resolvedOccurrenceCanBeReopened() {
        var occurrence = occurrence(Priority.MEDIA);
        occurrence.transitionTo(OccurrenceStatus.EM_TRIAGEM, null);
        occurrence.transitionTo(OccurrenceStatus.EM_ANDAMENTO, null);
        occurrence.transitionTo(OccurrenceStatus.RESOLVIDA, null);

        occurrence.transitionTo(OccurrenceStatus.EM_ANDAMENTO, null);

        assertEquals(OccurrenceStatus.EM_ANDAMENTO, occurrence.getStatus());
    }

    @Test
    void invalidTransitionIsRejected() {
        var occurrence = occurrence(Priority.MEDIA);

        assertThrows(
                IllegalStateException.class,
                () -> occurrence.transitionTo(OccurrenceStatus.RESOLVIDA, null));
    }

    @Test
    void cancellationRequiresReasonAndStoresAuditData() {
        var occurrence = occurrence(Priority.MEDIA);
        assertThrows(
                IllegalArgumentException.class,
                () -> occurrence.transitionTo(OccurrenceStatus.CANCELADA, " "));

        occurrence.transitionTo(OccurrenceStatus.CANCELADA, " Solicitação do cidadão ");

        assertEquals(OccurrenceStatus.CANCELADA, occurrence.getStatus());
        assertEquals("Solicitação do cidadão", occurrence.getCancellationReason());
        assertNotNull(occurrence.getCancelledAt());
    }

    @Test
    void optionalAddressFieldsAreNormalized() {
        var address = new Address(
                " Rua A ",
                " 10 ",
                " ",
                " Centro ",
                " São Paulo ",
                "sp",
                null);

        assertEquals("Rua A", address.getStreet());
        assertEquals("SP", address.getState());
        assertNull(address.getComplement());
    }

    private static Occurrence occurrence(Priority priority) {
        return new Occurrence(
                UUID.randomUUID(),
                category(),
                "Buraco na faixa direita",
                "Buraco profundo próximo à faixa de pedestres.",
                priority,
                address());
    }

    private static Category category() {
        return new Category("VIAS", "Vias", null);
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
