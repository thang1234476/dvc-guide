package com.dvcguide.server.admin.repository;

import com.dvcguide.server.admin.dto.ChangeLogModels.Actor;
import com.dvcguide.server.admin.dto.ChangeLogModels.Summary;
import com.dvcguide.server.admin.entity.ChangeLog;
import com.dvcguide.server.common.model.ChangeAction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface ChangeLogRepository extends JpaRepository<ChangeLog, Long> {
    @Query(value = """
            select new com.dvcguide.server.admin.dto.ChangeLogModels$Summary(
                l.id, l.quanTriId, coalesce(nullif(trim(a.tenHienThi), ''), a.email),
                l.bang, l.banGhiId, l.hanhDong, l.taoLuc)
            from ChangeLog l left join Administrator a on a.id = l.quanTriId
            where (:administratorId is null or l.quanTriId = :administratorId)
              and (:tableName is null or l.bang = :tableName)
              and (:recordId is null or l.banGhiId = :recordId)
              and (:action is null or l.hanhDong = :action)
              and (:fromTime is null or l.taoLuc >= :fromTime)
              and (:toTime is null or l.taoLuc <= :toTime)
            """, countQuery = """
            select count(l) from ChangeLog l
            where (:administratorId is null or l.quanTriId = :administratorId)
              and (:tableName is null or l.bang = :tableName)
              and (:recordId is null or l.banGhiId = :recordId)
              and (:action is null or l.hanhDong = :action)
              and (:fromTime is null or l.taoLuc >= :fromTime)
              and (:toTime is null or l.taoLuc <= :toTime)
            """)
    Page<Summary> search(@Param("administratorId") Integer administratorId,
                         @Param("tableName") String tableName, @Param("recordId") String recordId,
                         @Param("action") ChangeAction action, @Param("fromTime") Instant from,
                         @Param("toTime") Instant to, Pageable pageable);

    @Query("""
            select distinct new com.dvcguide.server.admin.dto.ChangeLogModels$Actor(
                a.id, coalesce(nullif(trim(a.tenHienThi), ''), a.email))
            from Administrator a where exists (select l.id from ChangeLog l where l.quanTriId = a.id)
            order by coalesce(nullif(trim(a.tenHienThi), ''), a.email), a.id
            """)
    List<Actor> findActors();
}
