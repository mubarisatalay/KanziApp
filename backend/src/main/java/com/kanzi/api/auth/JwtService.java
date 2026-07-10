package com.kanzi.api.auth;

import com.kanzi.api.config.AppProperties;
import com.kanzi.api.user.User;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class JwtService {

    private final JwtEncoder encoder;
    private final AppProperties props;

    public JwtService(JwtEncoder encoder, AppProperties props) {
        this.encoder = encoder;
        this.props = props;
    }

    public String issueAccessToken(User user) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("kanzi-api")
                .issuedAt(now)
                .expiresAt(now.plus(props.jwt().accessTokenTtl()))
                .subject(user.getId().toString())
                .claim("username", user.getUsername())
                .build();
        return encoder.encode(JwtEncoderParameters.from(claims)).getTokenValue();
    }

    public long accessTokenTtlSeconds() {
        return props.jwt().accessTokenTtl().toSeconds();
    }
}
