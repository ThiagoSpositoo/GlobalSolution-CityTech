package br.com.fiap.citytech.security;

import br.com.fiap.citytech.common.ApiError;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;
import tools.jackson.databind.ObjectMapper;

@Configuration
@EnableMethodSecurity
@EnableConfigurationProperties(SecurityProperties.class)
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            ObjectMapper objectMapper) throws Exception {
        http
                .cors(Customizer.withDefaults())
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers(
                                "/actuator/health/**",
                                "/health/**",
                                "/",
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/swagger-ui.html")
                        .permitAll()
                        .anyRequest()
                        .authenticated())
                .oauth2ResourceServer(resource -> resource
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                        .authenticationEntryPoint((request, response, exception) ->
                                writeSecurityError(
                                        response,
                                        objectMapper,
                                        request.getRequestURI(),
                                        401,
                                        "UNAUTHORIZED",
                                        "Não autorizado",
                                        "Informe um token JWT válido."))
                        .accessDeniedHandler((request, response, exception) ->
                                writeSecurityError(
                                        response,
                                        objectMapper,
                                        request.getRequestURI(),
                                        403,
                                        "FORBIDDEN",
                                        "Acesso negado",
                                        "O usuário não possui permissão para esta operação.")));
        return http.build();
    }

    @Bean
    JwtDecoder jwtDecoder(SecurityProperties properties) throws Exception {
        if (properties.publicKeyPath() == null || properties.publicKeyPath().isBlank()) {
            throw new IllegalStateException(
                    "Defina JWT_PUBLIC_KEY_PATH com a chave pública PEM emitida pelo .NET.");
        }
        var pem = Files.readString(Path.of(properties.publicKeyPath()))
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "");
        var encoded = java.util.Base64.getDecoder().decode(pem);
        var key = (RSAPublicKey) KeyFactory.getInstance("RSA")
                .generatePublic(new X509EncodedKeySpec(encoded));
        var decoder = NimbusJwtDecoder.withPublicKey(key).build();
        OAuth2TokenValidator<Jwt> validator = new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(properties.issuer()),
                audienceValidator(properties.audience()),
                contractValidator(properties.keyId()));
        decoder.setJwtValidator(validator);
        return decoder;
    }

    private static Converter<Jwt, ? extends org.springframework.security.authentication.AbstractAuthenticationToken>
            jwtAuthenticationConverter() {
        var authorities = new JwtGrantedAuthoritiesConverter();
        authorities.setAuthoritiesClaimName("roles");
        authorities.setAuthorityPrefix("ROLE_");
        var converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authorities);
        converter.setPrincipalClaimName("sub");
        return converter;
    }

    private static OAuth2TokenValidator<Jwt> audienceValidator(String audience) {
        return jwt -> jwt.getAudience().contains(audience)
                ? OAuth2TokenValidatorResult.success()
                : failure("invalid_audience", "Audiência inválida.");
    }

    private static OAuth2TokenValidator<Jwt> contractValidator(String keyId) {
        return jwt -> {
            var roles = jwt.getClaimAsStringList("roles");
            var validRole = roles != null
                    && !roles.isEmpty()
                    && roles.stream().allMatch(role ->
                            role.equals("CIDADAO") || role.equals("GESTOR"));
            var validSubject = true;
            try {
                UUID.fromString(jwt.getSubject());
            } catch (RuntimeException exception) {
                validSubject = false;
            }
            var validKey = keyId.equals(jwt.getHeaders().get("kid"));
            return validRole && validSubject && validKey
                    ? OAuth2TokenValidatorResult.success()
                    : failure("invalid_contract", "Claims ou kid inválidos.");
        };
    }

    private static OAuth2TokenValidatorResult failure(String code, String description) {
        return OAuth2TokenValidatorResult.failure(new OAuth2Error(code, description, null));
    }

    private static void writeSecurityError(
            jakarta.servlet.http.HttpServletResponse response,
            ObjectMapper objectMapper,
            String path,
            int status,
            String code,
            String title,
            String detail) throws java.io.IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        var body = new ApiError(
                "https://citytech.example/errors/" + code.toLowerCase().replace('_', '-'),
                title,
                status,
                detail,
                path,
                code,
                UUID.randomUUID().toString(),
                Instant.now(),
                null);
        objectMapper.writeValue(response.getOutputStream(), body);
    }
}
