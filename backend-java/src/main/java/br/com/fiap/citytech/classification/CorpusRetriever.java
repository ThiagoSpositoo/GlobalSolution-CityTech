package br.com.fiap.citytech.classification;

import br.com.fiap.citytech.messaging.OccurrenceCreatedEvent;
import java.nio.charset.StandardCharsets;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Component
public class CorpusRetriever {

    private static final List<String> SOURCES = List.of(
            "citytech-corpus/taxonomia.md",
            "citytech-corpus/prioridade.md");

    private final List<Chunk> chunks;

    public CorpusRetriever() {
        this.chunks = SOURCES.stream().flatMap(source -> load(source).stream()).toList();
    }

    public List<Chunk> retrieve(OccurrenceCreatedEvent event, int topK) {
        var terms = terms(event.title() + " " + event.description());
        return chunks.stream()
                .map(chunk -> new ScoredChunk(
                        chunk,
                        terms.stream().filter(chunk.terms()::contains).count()))
                .sorted(Comparator
                        .comparingLong(ScoredChunk::score)
                        .reversed()
                        .thenComparing(value -> value.chunk().id()))
                .limit(Math.max(1, topK))
                .map(ScoredChunk::chunk)
                .toList();
    }

    private static List<Chunk> load(String source) {
        try {
            var resource = new ClassPathResource(source);
            var text = resource.getContentAsString(StandardCharsets.UTF_8);
            var sections = text.split("(?m)(?=^## )");
            return java.util.stream.IntStream.range(0, sections.length)
                    .filter(index -> !sections[index].isBlank())
                    .mapToObj(index -> {
                        var content = sections[index].trim();
                        var heading = content.lines()
                                .findFirst()
                                .orElse("documento")
                                .replaceFirst("^#+\\s*", "")
                                .toLowerCase(Locale.ROOT)
                                .replaceAll("[^a-z0-9]+", "-")
                                .replaceAll("(^-|-$)", "");
                        return new Chunk(source + "#" + heading, content, terms(content));
                    })
                    .toList();
        } catch (java.io.IOException exception) {
            throw new IllegalStateException("Corpus não pôde ser carregado: " + source, exception);
        }
    }

    private static Set<String> terms(String text) {
        return java.util.Arrays.stream(text
                        .toLowerCase(Locale.ROOT)
                        .replaceAll("[^\\p{L}\\p{N}]+", " ")
                        .split("\\s+"))
                .filter(term -> term.length() >= 4)
                .collect(java.util.stream.Collectors.toSet());
    }

    public record Chunk(String id, String content, Set<String> terms) {
    }

    private record ScoredChunk(Chunk chunk, long score) {
    }
}
