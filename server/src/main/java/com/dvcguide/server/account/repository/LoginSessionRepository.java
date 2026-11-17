package com.dvcguide.server.account.repository;

import com.dvcguide.server.account.entity.LoginSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

public interface LoginSessionRepository extends JpaRepository<LoginSession, String> {
    Optional<LoginSession> findByTokenHashAndDangXuatLucIsNullAndHetHanLucAfter(
            String tokenHash, LocalDateTime now);
}
