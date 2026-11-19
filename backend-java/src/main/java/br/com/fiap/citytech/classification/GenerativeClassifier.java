package br.com.fiap.citytech.classification;

import br.com.fiap.citytech.occurrence.Priority;
import java.util.List;

public interface GenerativeClassifier {

    Result classify(String title, String description, List<CorpusRetriever.Chunk> context);

    record Result(
            String categoryCode,
            Priority priority,
            String summary,
            String justification,
            List<String> sources,
            String model) {
    }
}
