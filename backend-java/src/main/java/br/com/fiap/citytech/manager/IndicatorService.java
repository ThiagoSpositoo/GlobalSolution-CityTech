package br.com.fiap.citytech.manager;

import br.com.fiap.citytech.occurrence.OccurrenceRepository;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class IndicatorService {

    private final OccurrenceRepository repository;

    public IndicatorService(OccurrenceRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Indicators indicators() {
        return new Indicators(
                repository.count(),
                toMap(repository.countGroupedByStatus()),
                toMap(repository.countGroupedByCategory()));
    }

    private static Map<String, Long> toMap(java.util.List<Object[]> rows) {
        var result = new LinkedHashMap<String, Long>();
        rows.forEach(row -> result.put(row[0].toString(), (Long) row[1]));
        return result;
    }

    public record Indicators(
            long totalOccurrences,
            Map<String, Long> byStatus,
            Map<String, Long> byCategory) {
    }
}
