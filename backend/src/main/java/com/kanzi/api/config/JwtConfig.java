package com.kanzi.api.config;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.UUID;

/**
 * JWT signing/verification.
 *
 * <p>We are the token <em>issuer</em> (not an external OIDC provider), so we expose both a
 * {@link JwtEncoder} (sign access tokens) and a {@link JwtDecoder} (verify incoming bearer
 * tokens). Spring Security's resource server auto-configuration backs off and uses this
 * {@code JwtDecoder} bean.
 *
 * <p><strong>DEV:</strong> an ephemeral RSA keypair is generated at startup — simplest possible
 * setup, but issued tokens stop verifying after a restart (fine for local dev).
 * <strong>PROD (later):</strong> load a fixed keypair from env/secret so tokens survive restarts
 * and can be rotated deliberately.
 */
@Configuration
public class JwtConfig {

    private final RSAKey rsaKey = generateRsaKey();

    private static RSAKey generateRsaKey() {
        try {
            KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            var pair = generator.generateKeyPair();
            return new RSAKey.Builder((RSAPublicKey) pair.getPublic())
                    .privateKey((RSAPrivateKey) pair.getPrivate())
                    .keyID(UUID.randomUUID().toString())
                    .build();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to generate RSA keypair for JWT signing", e);
        }
    }

    @Bean
    public JwtEncoder jwtEncoder() {
        JWKSource<SecurityContext> jwkSource = new ImmutableJWKSet<>(new JWKSet(rsaKey));
        return new NimbusJwtEncoder(jwkSource);
    }

    @Bean
    public JwtDecoder jwtDecoder() {
        try {
            return NimbusJwtDecoder.withPublicKey(rsaKey.toRSAPublicKey()).build();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to build JwtDecoder", e);
        }
    }
}
