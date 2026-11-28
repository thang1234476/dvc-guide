package com.dvcguide.server.admin.repository;

import com.dvcguide.server.admin.entity.RagSyncJob;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface RagSyncJobRepository extends JpaRepository<RagSyncJob, Integer> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select j from RagSyncJob j where j.procedureId = :id")
    Optional<RagSyncJob> lockById(int id);

    @Query("select j.procedureId from RagSyncJob j where (j.status <> :synced "
            + "and j.nextAttemptAt <= :now) and (j.leaseUntil is null or j.leaseUntil < :now) order by j.nextAttemptAt, j.procedureId")
    List<Integer> due(Instant now, RagSyncJob.Status synced, Pageable limit);
}
