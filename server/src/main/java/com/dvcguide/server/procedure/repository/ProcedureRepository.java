package com.dvcguide.server.procedure.repository;

import com.dvcguide.server.procedure.entity.Procedure;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import com.dvcguide.server.common.model.ProcedureStatus;

public interface ProcedureRepository extends JpaRepository<Procedure, Integer> {
    Optional<Procedure> findByMaThuTuc(String code);
    List<Procedure> findByTrangThaiOrderById(ProcedureStatus status);

    @Query("""
            select p from Procedure p
            where p.trangThai = com.dvcguide.server.common.model.ProcedureStatus.dang_dung
              and (p.tenKhongDau like :pattern escape '!'
                or replace(lower(p.ten), 'đ', 'd') like :pattern escape '!'
                or lower(p.maThuTuc) like :codePattern escape '!')
              and (:allFields = true or exists (select 1 from ProcedureFieldLink f
                where f.thuTucId = p.id and f.linhVucId in :fieldIds))
              and (:savedOnly = false or exists (select 1 from FavoriteProcedure f
                where f.thuTucId = p.id and f.nguoiDungId = :userId))
            """)
    Page<Procedure> searchPublished(String pattern, String codePattern, boolean allFields,
                                    Collection<Integer> fieldIds, boolean savedOnly, String userId, Pageable page);

    @Query("""
            select p from Procedure p
            where p.tenKhongDau like :pattern escape '!'
                or replace(lower(p.ten), 'đ', 'd') like :pattern escape '!'
                or lower(p.maThuTuc) like :codePattern escape '!'
            """)
    Page<Procedure> searchAdmin(String pattern, String codePattern, Pageable page);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Procedure p where p.id = :id")
    Optional<Procedure> lockById(int id);
}
