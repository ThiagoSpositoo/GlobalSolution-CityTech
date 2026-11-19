package br.com.fiap.citytech.security;

import java.util.List;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@Profile("local")
@EnableConfigurationProperties(CorsProperties.class)
class CorsConfig {

    @Bean
    CorsConfigurationSource corsConfigurationSource(CorsProperties properties) {
        if (properties.allowedOrigins() == null || properties.allowedOrigins().isEmpty()) {
            throw new IllegalStateException("Configure citytech.cors.allowed-origins para o profile local.");
        }

        var configuration = new CorsConfiguration();
        var originPatterns = new java.util.ArrayList<>(properties.allowedOrigins());
        originPatterns.add("http://localhost:[*]");
        originPatterns.add("https://localhost:[*]");
        originPatterns.add("http://127.0.0.1:[*]");
        originPatterns.add("https://127.0.0.1:[*]");
        originPatterns.add("http://[::1]:[*]");
        originPatterns.add("https://[::1]:[*]");
        configuration.setAllowedOriginPatterns(originPatterns.stream().distinct().toList());
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setExposedHeaders(List.of(
                "Retry-After",
                "Idempotent-Replayed",
                "Location"));
        configuration.setAllowCredentials(false);
        configuration.setMaxAge(3600L);

        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}
