package br.com.fiap.citytech.common;

import java.sql.Connection;
import javax.sql.DataSource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    private final DataSource dataSource;

    public HealthController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/")
    public java.util.Map<String, String> root() {
        return java.util.Map.of("service", "citytech-java", "status", "ok");
    }

    @GetMapping("/health/live")
    public java.util.Map<String, String> live() {
        return java.util.Map.of("status", "UP");
    }

    @GetMapping("/health/ready")
    public ResponseEntity<java.util.Map<String, Object>> ready() {
        try (Connection connection = dataSource.getConnection()) {
            var valid = connection.isValid(2);
            var body = java.util.Map.<String, Object>of(
                    "status", valid ? "UP" : "DOWN",
                    "checks", java.util.Map.of(
                            "oracle", java.util.Map.of("status", valid ? "UP" : "DOWN")));
            return valid
                    ? ResponseEntity.ok(body)
                    : ResponseEntity.status(503).body(body);
        } catch (Exception exception) {
            return ResponseEntity.status(503).body(java.util.Map.of(
                    "status", "DOWN",
                    "checks", java.util.Map.of(
                            "oracle", java.util.Map.of("status", "DOWN"))));
        }
    }
}
