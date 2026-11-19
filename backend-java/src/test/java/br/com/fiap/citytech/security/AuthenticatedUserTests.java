package br.com.fiap.citytech.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import br.com.fiap.citytech.common.ApiException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

class AuthenticatedUserTests {

    @Test
    void mapsCitizenClaims() {
        var id = UUID.randomUUID();
        var user = AuthenticatedUser.from(jwt(id.toString(), List.of("CIDADAO")));

        assertEquals(id, user.id());
        assertTrue(user.isCitizen());
        assertFalse(user.isManager());
    }

    @Test
    void mapsManagerClaims() {
        var user = AuthenticatedUser.from(jwt(
                UUID.randomUUID().toString(),
                List.of("GESTOR")));

        assertTrue(user.isManager());
        assertFalse(user.isCitizen());
    }

    @Test
    void rejectsInvalidSubject() {
        assertThrows(
                ApiException.class,
                () -> AuthenticatedUser.from(jwt("not-a-uuid", List.of("CIDADAO"))));
    }

    private static Jwt jwt(String subject, List<String> roles) {
        var now = Instant.now();
        return new Jwt(
                "token",
                now,
                now.plusSeconds(60),
                Map.of("alg", "RS256"),
                Map.of("sub", subject, "roles", roles));
    }
}
