package com.dvcguide.server.chat.repository;

import com.dvcguide.server.chat.entity.Message;
import com.dvcguide.server.common.model.MessageRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {
    Page<Message> findByHoiThoaiIdOrderByIdDesc(String conversationId, Pageable pageable);

    List<Message> findTop6ByHoiThoaiIdAndVaiTroInAndNoiDungIsNotNullOrderByIdDesc(
            String conversationId, List<MessageRole> roles);

    @Query("select max(m.id) from Message m where m.hoiThoaiId = :conversationId")
    Long latestId(String conversationId);

    boolean existsByIdAndHoiThoaiIdAndVaiTro(long id, String conversationId, MessageRole role);
}
