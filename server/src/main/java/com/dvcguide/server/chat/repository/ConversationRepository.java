package com.dvcguide.server.chat.repository;

import com.dvcguide.server.chat.entity.Conversation;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, String> {
    Page<Conversation> findByNguoiDungIdOrderByCapNhatLucDescIdDesc(String userId, Pageable pageable);

    Optional<Conversation> findByIdAndNguoiDungId(String id, String userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from Conversation c where c.id = :id and c.nguoiDungId = :userId")
    Optional<Conversation> lockOwned(String id, String userId);

    @Modifying
    @Query("delete from Conversation c where c.nguoiDungId = :userId")
    void deleteOwned(String userId);
}
