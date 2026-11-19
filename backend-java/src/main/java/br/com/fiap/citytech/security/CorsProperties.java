package br.com.fiap.citytech.security;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("citytech.cors")
public record CorsProperties(List<String> allowedOrigins) {
}
