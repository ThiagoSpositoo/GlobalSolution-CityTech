package br.com.fiap.citytech.classification;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

import br.com.fiap.citytech.messaging.OccurrenceCreatedEvent;
import br.com.fiap.citytech.occurrence.Priority;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.model.ChatModel;

class ClassificationTests {

    @Test
    void retrieverReturnsVersionedRelevantChunks() {
        var event = new OccurrenceCreatedEvent(
                UUID.randomUUID(),
                "OccurrenceCreated",
                1,
                Instant.now(),
                UUID.randomUUID(),
                UUID.randomUUID(),
                UUID.randomUUID(),
                "Poste apagado",
                "A praça está sem iluminação durante a noite.",
                Priority.MEDIA,
                new OccurrenceCreatedEvent.AddressData("Centro", "São Paulo", "SP"));

        var chunks = new CorpusRetriever().retrieve(event, 3);

        assertEquals(3, chunks.size());
        assertTrue(chunks.getFirst().id().contains("iluminacao"));
    }

    @Test
    void springAiAdapterParsesStructuredOutputAndPreservesSources() {
        var chatModel = org.mockito.Mockito.mock(ChatModel.class);
        when(chatModel.call(anyString())).thenReturn("""
                {
                  "categoryCode":"VIAS",
                  "priority":"ALTA",
                  "summary":"Buraco com risco para pedestres.",
                  "justification":"O trecho recuperado relaciona buracos à categoria VIAS.",
                  "sources":["citytech-corpus/taxonomia.md#vias"]
                }
                """);
        var classifier = new SpringAiGenerativeClassifier(
                chatModel,
                tools.jackson.databind.json.JsonMapper.builder().build(),
                "modelo-controlado");
        var context = java.util.List.of(new CorpusRetriever.Chunk(
                "citytech-corpus/taxonomia.md#vias",
                "## VIAS\nBuracos e pavimento danificado.",
                java.util.Set.of("vias", "buracos", "pavimento")));

        var result = classifier.classify(
                "Buraco na via",
                "Buraco profundo próximo à faixa.",
                context);

        assertEquals("VIAS", result.categoryCode());
        assertEquals(Priority.ALTA, result.priority());
        assertEquals("modelo-controlado", result.model());
        assertEquals(context.getFirst().id(), result.sources().getFirst());
    }
}
