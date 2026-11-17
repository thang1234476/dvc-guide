package com.dvcguide.server.catalog.controller;

import com.dvcguide.server.catalog.entity.Locality;
import com.dvcguide.server.catalog.entity.ProcedureField;
import com.dvcguide.server.common.model.AdministrativeLevel;
import com.dvcguide.server.common.response.ApiResponse;
import com.dvcguide.server.procedure.dto.ProcedureSummary.Field;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/catalog")
@RequiredArgsConstructor
public class CatalogController {
    private final EntityManager db;

    public record LocalityView(int id, String code, String name, AdministrativeLevel level, Integer parentId) {}

    @GetMapping("/fields")
    public ApiResponse<List<Field>> fields() {
        return ApiResponse.success(db.createQuery("select f from ProcedureField f order by f.ten, f.id", ProcedureField.class)
                .getResultList().stream().map(f -> new Field(f.getId(), f.getMa(), f.getTen())).toList());
    }

    @GetMapping("/localities")
    public ApiResponse<List<LocalityView>> localities(@RequestParam(required = false) Integer parentId) {
        return ApiResponse.success(db.createQuery("""
                select l from Locality l
                where (:parent is null and l.parentId is null) or l.parentId = :parent
                order by l.ten, l.id
                """, Locality.class).setParameter("parent", parentId).getResultList().stream()
                .map(l -> new LocalityView(l.getId(), l.getMa(), l.getTen(), l.getCap(), l.getParentId())).toList());
    }
}
