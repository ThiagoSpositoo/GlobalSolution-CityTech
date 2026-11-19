package br.com.fiap.citytech.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.JwtValidationException;

class SecurityConfigTests {

    @Test
    void decoderAcceptsDotNetJwtContractAndRejectsWrongAudience() throws Exception {
        var keys = KeyPairGenerator.getInstance("RSA");
        keys.initialize(2048);
        var pair = keys.generateKeyPair();
        var publicKey = (RSAPublicKey) pair.getPublic();
        var privateKey = (RSAPrivateKey) pair.getPrivate();
        var path = Files.createTempFile("citytech-public-", ".pem");
        try {
            Files.writeString(path, pem(publicKey), StandardCharsets.US_ASCII);
            var properties = new SecurityProperties(
                    "citytech-identity",
                    "citytech-api",
                    "citytech-local-v1",
                    path.toString());
            var decoder = new SecurityConfig().jwtDecoder(properties);
            var subject = UUID.randomUUID();

            var decoded = decoder.decode(token(
                    privateKey,
                    subject,
                    "citytech-api",
                    "citytech-local-v1",
                    List.of("CIDADAO")));

            assertEquals(subject.toString(), decoded.getSubject());
            assertEquals(List.of("CIDADAO"), decoded.getClaimAsStringList("roles"));
            assertThrows(
                    JwtValidationException.class,
                    () -> decoder.decode(token(
                            privateKey,
                            subject,
                            "wrong-audience",
                            "citytech-local-v1",
                            List.of("CIDADAO"))));
        } finally {
            Files.deleteIfExists(path);
        }
    }

    @Test
    void decoderRejectsInvalidKidSubjectAndRole() throws Exception {
        var keys = KeyPairGenerator.getInstance("RSA");
        keys.initialize(2048);
        var pair = keys.generateKeyPair();
        var publicKey = (RSAPublicKey) pair.getPublic();
        var privateKey = (RSAPrivateKey) pair.getPrivate();
        var path = Files.createTempFile("citytech-public-", ".pem");
        try {
            Files.writeString(path, pem(publicKey), StandardCharsets.US_ASCII);
            var decoder = new SecurityConfig().jwtDecoder(new SecurityProperties(
                    "citytech-identity",
                    "citytech-api",
                    "citytech-local-v1",
                    path.toString()));

            assertThrows(
                    JwtValidationException.class,
                    () -> decoder.decode(token(
                            privateKey,
                            UUID.randomUUID(),
                            "citytech-api",
                            "wrong-kid",
                            List.of("CIDADAO"))));
            assertThrows(
                    JwtValidationException.class,
                    () -> decoder.decode(token(
                            privateKey,
                            null,
                            "citytech-api",
                            "citytech-local-v1",
                            List.of("ADMIN"))));
        } finally {
            Files.deleteIfExists(path);
        }
    }

    private static String token(
            RSAPrivateKey privateKey,
            UUID subject,
            String audience,
            String keyId,
            List<String> roles) throws Exception {
        var now = Instant.now();
        var claims = new JWTClaimsSet.Builder()
                .issuer("citytech-identity")
                .audience(audience)
                .subject(subject == null ? "not-a-uuid" : subject.toString())
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plusSeconds(300)))
                .jwtID(UUID.randomUUID().toString())
                .claim("roles", roles)
                .build();
        var jwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(keyId).build(),
                claims);
        jwt.sign(new RSASSASigner(privateKey));
        return jwt.serialize();
    }

    private static String pem(RSAPublicKey publicKey) {
        var encoded = Base64.getMimeEncoder(64, new byte[] {'\n'})
                .encodeToString(publicKey.getEncoded());
        return "-----BEGIN PUBLIC KEY-----\n"
                + encoded
                + "\n-----END PUBLIC KEY-----\n";
    }
}
