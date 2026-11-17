package com.dvcguide.server.account.service;

import com.dvcguide.server.account.entity.LoginSession;
import com.dvcguide.server.account.repository.LoginSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class SessionService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private final LoginSessionRepository sessions;

    public record IssuedToken(String token, Instant expiresAt) {}
    public record UserSession(String userId, String sessionId) {}

    @Transactional
    public IssuedToken issue(String userId, String device) {
        byte[] random = new byte[32];
        RANDOM.nextBytes(random);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(random);
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);
        LoginSession session = new LoginSession();
        session.setNguoiDungId(userId);
        session.setTokenHash(hash(token));
        session.setThietBi(device);
        session.setTaoLuc(now);
        session.setHetHanLuc(now.plusDays(30));
        sessions.save(session);
        return new IssuedToken(token, session.getHetHanLuc().toInstant(ZoneOffset.UTC));
    }

    public Optional<UserSession> authenticate(String token) {
        if (!token.matches("[A-Za-z0-9_-]{43}")) {
            return Optional.empty();
        }
        return sessions.findByTokenHashAndDangXuatLucIsNullAndHetHanLucAfter(
                        hash(token), LocalDateTime.now(ZoneOffset.UTC))
                .map(session -> new UserSession(session.getNguoiDungId(), session.getId()));
    }

    @Transactional
    public void revoke(UserSession principal) {
        sessions.findById(principal.sessionId())
                .ifPresent(session -> session.setDangXuatLuc(LocalDateTime.now(ZoneOffset.UTC)));
    }

    private static String hash(String token) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
