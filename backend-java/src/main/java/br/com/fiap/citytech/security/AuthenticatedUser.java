package br.com.fiap.citytech.security;

import br.com.fiap.citytech.common.ApiException;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;

public record AuthenticatedUser(UUID id, Set<String> roles) {

    public static AuthenticatedUser from(Jwt jwt) {
        try {
            return new AuthenticatedUser(
                    UUID.fromString(jwt.getSubject()),
                    Set.copyOf(jwt.getClaimAsStringList("roles")));
        } catch (RuntimeException exception) {
            throw new ApiException(
                    HttpStatus.UNAUTHORIZED,
                    "UNAUTHORIZED",
                    "Não autorizado",
                    "Token inválido.");
        }
    }

    public boolean isManager() {
        return roles.contains("GESTOR");
    }

    public boolean isCitizen() {
        return roles.contains("CIDADAO");
    }
}
