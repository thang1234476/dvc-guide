package com.dvcguide.server.admin.repository;

import com.dvcguide.server.admin.entity.Administrator;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface AdministratorRepository extends JpaRepository<Administrator, Integer> {
    Optional<Administrator> findByEmailIgnoreCase(String email);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Administrator a where lower(a.email) = lower(:email)")
    Optional<Administrator> lockByEmail(@Param("email") String email);
}
