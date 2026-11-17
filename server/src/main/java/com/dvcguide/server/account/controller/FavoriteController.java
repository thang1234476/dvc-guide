package com.dvcguide.server.account.controller;

import com.dvcguide.server.account.entity.FavoriteProcedure;
import com.dvcguide.server.account.repository.UserAccountRepository;
import com.dvcguide.server.account.service.SessionService.UserSession;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import com.dvcguide.server.procedure.service.ProcedureService;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users/me/favorites")
@RequiredArgsConstructor
public class FavoriteController {
    private final UserAccountRepository users;
    private final ProcedureService procedures;
    private final EntityManager db;

    @PutMapping("/{procedureId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void save(@PathVariable int procedureId, @AuthenticationPrincipal UserSession principal) {
        lockUser(principal);
        procedures.findPublished(procedureId);
        if (db.find(FavoriteProcedure.class, new FavoriteProcedure.Key(principal.userId(), procedureId)) == null) {
            var favorite = new FavoriteProcedure();
            favorite.setNguoiDungId(principal.userId());
            favorite.setThuTucId(procedureId);
            db.persist(favorite);
        }
    }

    @DeleteMapping("/{procedureId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void remove(@PathVariable int procedureId, @AuthenticationPrincipal UserSession principal) {
        lockUser(principal);
        var favorite = db.find(FavoriteProcedure.class, new FavoriteProcedure.Key(principal.userId(), procedureId));
        if (favorite != null) {
            db.remove(favorite);
        }
    }

    private void lockUser(UserSession principal) {
        users.lockById(principal.userId()).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản."));
    }
}
