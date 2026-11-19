package br.com.fiap.citytech.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("citytech.security")
public record SecurityProperties(
        String issuer,
        String audience,
        String keyId,
        String publicKeyPath) {
}
