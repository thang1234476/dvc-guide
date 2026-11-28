package com.dvcguide.server.admin;

import com.dvcguide.server.admin.dto.ProcedureWriteRequest;
import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.entity.ChangeLog;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.admin.repository.ChangeLogRepository;
import com.dvcguide.server.admin.service.AdminProcedureService;
import com.dvcguide.server.common.model.AdminRole;
import com.dvcguide.server.common.model.ChangeAction;
import com.dvcguide.server.common.model.ProcedureStatus;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:change_logs;DB_CLOSE_DELAY=-1;MODE=MySQL")
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ChangeLogControllerTest {
    private static final String PATH = "/api/v1/admin/change-logs";
    private static final String PASSWORD = "admin-test-password-123";
    private static final Instant TIME = Instant.parse("2026-11-28T03:00:00Z");

    @Autowired MockMvc mvc;
    @Autowired AdministratorRepository admins;
    @Autowired ChangeLogRepository logs;
    @Autowired AdminProcedureService editor;
    @Autowired PasswordEncoder passwords;
    @Autowired ObjectMapper json;
    @Autowired EntityManager db;

    @Test
    void requiresAnActiveAdminOrEditorForAllReadEndpointsAndDoesNotAllowWrites() throws Exception {
        var actor = actor(AdminRole.bien_tap, "Biên tập viên");
        var log = log(actor.getId(), "thu_tuc", "1", ChangeAction.sua, TIME);
        for (String path : List.of(PATH, PATH + "/" + log.getId(), PATH + "/administrators")) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
            mvc.perform(get(path).with(user("app-user").roles("USER"))).andExpect(status().isForbidden());
            mvc.perform(get(path).with(httpBasic(actor.getEmail(), PASSWORD))).andExpect(status().isOk());
        }
        mvc.perform(delete(PATH + "/" + log.getId()).with(httpBasic(actor.getEmail(), PASSWORD)))
                .andExpect(status().isMethodNotAllowed());
        actor.setHoatDong(false);
        admins.saveAndFlush(actor);
        mvc.perform(get(PATH).with(httpBasic(actor.getEmail(), PASSWORD))).andExpect(status().isUnauthorized());
    }

    @Test
    void pagesNewestFirstWithStableTiesAndDoesNotIncludeSnapshotsInTheList() throws Exception {
        var actor = actor(AdminRole.admin, "Nguyễn An");
        var first = log(actor.getId(), "thu_tuc", "1", ChangeAction.tao, TIME);
        var second = log(null, "thu_tuc", "2", ChangeAction.sua, TIME);
        var newest = log(actor.getId(), "thu_tuc", "3", ChangeAction.xoa, TIME.plusSeconds(1));
        mvc.perform(as(actor).param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(3))
                .andExpect(jsonPath("$.data.totalPages").value(2))
                .andExpect(jsonPath("$.data.items[0].id").value(newest.getId()))
                .andExpect(jsonPath("$.data.items[0].administratorName").value("Nguyễn An"))
                .andExpect(jsonPath("$.data.items[1].id").value(second.getId()))
                .andExpect(jsonPath("$.data.items[1].administratorName").isEmpty())
                .andExpect(jsonPath("$.data.items[0].before").doesNotExist())
                .andExpect(jsonPath("$.data.items[0].after").doesNotExist())
                .andExpect(jsonPath("$.data.items[0].matKhauHash").doesNotExist());
        mvc.perform(as(actor).param("size", "2").param("page", "1"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.items[0].id").value(first.getId()));
    }

    @Test
    void combinesExactFiltersAndIncludesBothTimeBoundaries() throws Exception {
        var actor = actor(AdminRole.admin, "Admin A");
        var other = actor(AdminRole.bien_tap, "Admin B");
        var target = log(actor.getId(), "thu_tuc", "42", ChangeAction.sua, TIME);
        log(other.getId(), "thu_tuc", "42", ChangeAction.sua, TIME);
        log(actor.getId(), "thu_tuc", "420", ChangeAction.sua, TIME);
        log(actor.getId(), "other_table", "42", ChangeAction.sua, TIME);
        log(actor.getId(), "thu_tuc", "42", ChangeAction.tao, TIME);
        log(actor.getId(), "thu_tuc", "42", ChangeAction.sua, TIME.minusSeconds(1));
        log(actor.getId(), "thu_tuc", "42", ChangeAction.sua, TIME.plusSeconds(1));
        mvc.perform(as(actor).param("administratorId", actor.getId().toString()).param("tableName", " thu_tuc ")
                        .param("recordId", "42").param("action", "sua").param("from", TIME.toString()).param("to", TIME.toString()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].id").value(target.getId()));
        mvc.perform(as(actor).param("recordId", "not-found"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.items").isEmpty());
        mvc.perform(as(actor).param("action", "tao").param("from", TIME.toString()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.totalElements").value(1));
        mvc.perform(as(actor).param("tableName", " ").param("recordId", " "))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.totalElements").value(7));
    }

    @Test
    void returnsCompleteNestedSnapshotsAndHandlesMissingOrNamelessActors() throws Exception {
        var actor = actor(AdminRole.admin, " ");
        var log = log(actor.getId(), "thu_tuc", "99", ChangeAction.sua, TIME);
        mvc.perform(as(actor).param("recordId", "99"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.items[0].administratorName").value(actor.getEmail()));
        mvc.perform(get(PATH + "/" + log.getId()).with(httpBasic(actor.getEmail(), PASSWORD)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.administratorName").value(actor.getEmail()))
                .andExpect(jsonPath("$.data.before.procedure.name").value("Tên cũ"))
                .andExpect(jsonPath("$.data.after.procedure.name").value("Tên mới"))
                .andExpect(jsonPath("$.data.after.documents[0].name").value("Tờ khai"));
        var orphan = log(null, "thu_tuc", "100", ChangeAction.tao, TIME);
        mvc.perform(get(PATH + "/" + orphan.getId()).with(httpBasic(actor.getEmail(), PASSWORD)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.administratorName").isEmpty());
        mvc.perform(get(PATH + "/9223372036854775807").with(httpBasic(actor.getEmail(), PASSWORD)))
                .andExpect(status().isNotFound());
    }

    @Test
    void actorFilterListsOnlyPeopleWithHistoryIncludingInactiveEditors() throws Exception {
        var owner = actor(AdminRole.admin, "Admin");
        var editor = actor(AdminRole.bien_tap, "Biên tập");
        actor(AdminRole.admin, "Chưa ghi nhật ký");
        log(owner.getId(), "thu_tuc", "1", ChangeAction.tao, TIME);
        log(owner.getId(), "thu_tuc", "2", ChangeAction.sua, TIME);
        log(editor.getId(), "thu_tuc", "3", ChangeAction.sua, TIME);
        log(null, "thu_tuc", "4", ChangeAction.xoa, TIME);
        editor.setHoatDong(false);
        admins.saveAndFlush(editor);
        mvc.perform(get(PATH + "/administrators").with(httpBasic(owner.getEmail(), PASSWORD)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].id").value(owner.getId()))
                .andExpect(jsonPath("$.data[1].id").value(editor.getId()))
                .andExpect(jsonPath("$.data[0].email").doesNotExist())
                .andExpect(jsonPath("$.data[0].matKhauHash").doesNotExist());
    }

    @Test
    void rejectsInvalidDatesActionsIdsAndPageSizes() throws Exception {
        var actor = actor(AdminRole.admin, "Admin");
        for (String[] pair : List.of(new String[]{"page", "-1"}, new String[]{"size", "101"},
                new String[]{"page", "100001"}, new String[]{"size", "0"},
                new String[]{"administratorId", "0"}, new String[]{"action", "invalid"},
                new String[]{"from", "invalid-date"}, new String[]{"tableName", "x".repeat(65)},
                new String[]{"recordId", "x".repeat(65)})) {
            mvc.perform(as(actor).param(pair[0], pair[1])).andExpect(status().isBadRequest());
        }
        mvc.perform(as(actor).param("from", TIME.plusSeconds(1).toString()).param("to", TIME.toString()))
                .andExpect(status().isBadRequest());
        mvc.perform(get(PATH + "/0").with(httpBasic(actor.getEmail(), PASSWORD))).andExpect(status().isBadRequest());
    }

    @Test
    void showsHistoryWrittenByRealProcedureCreateUpdateAndRetireOperations() throws Exception {
        var actor = actor(AdminRole.admin, "Người sửa thủ tục");
        String code = "LOG-" + UUID.randomUUID();
        var created = editor.create(write(code, "Tên ban đầu", null), actor.getEmail());
        int id = created.procedure().id();
        var updated = editor.update(id, write(code, "Tên đã sửa", created.procedure().version()), actor.getEmail());
        editor.retire(id, updated.procedure().version(), actor.getEmail());
        db.flush();
        var result = mvc.perform(as(actor).param("tableName", "thu_tuc").param("recordId", Integer.toString(id)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.totalElements").value(3))
                .andExpect(jsonPath("$.data.items[0].action").value("xoa"))
                .andExpect(jsonPath("$.data.items[1].action").value("sua"))
                .andExpect(jsonPath("$.data.items[2].action").value("tao"))
                .andReturn();
        long changeId = json.readTree(result.getResponse().getContentAsString()).at("/data/items/1/id").asLong();
        mvc.perform(get(PATH + "/" + changeId).with(httpBasic(actor.getEmail(), PASSWORD)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.before.procedure.name").value("Tên ban đầu"))
                .andExpect(jsonPath("$.data.after.procedure.name").value("Tên đã sửa"));
    }

    private MockHttpServletRequestBuilder as(Administrator actor) {
        return get(PATH).with(httpBasic(actor.getEmail(), PASSWORD));
    }

    private Administrator actor(AdminRole role, String name) {
        var actor = new Administrator();
        actor.setEmail(UUID.randomUUID() + "@example.test");
        actor.setTenHienThi(name);
        actor.setMatKhauHash(passwords.encode(PASSWORD));
        actor.setVaiTro(role);
        return admins.saveAndFlush(actor);
    }

    private ChangeLog log(Integer actor, String table, String record, ChangeAction action, Instant time) throws Exception {
        var log = new ChangeLog();
        log.setQuanTriId(actor);
        log.setBang(table);
        log.setBanGhiId(record);
        log.setHanhDong(action);
        log.setDuLieuTruoc(json.readTree("{\"procedure\":{\"name\":\"Tên cũ\"}}"));
        log.setDuLieuSau(json.readTree("{\"procedure\":{\"name\":\"Tên mới\"},\"documents\":[{\"name\":\"Tờ khai\"}]}"));
        logs.saveAndFlush(log);
        db.createQuery("update ChangeLog l set l.taoLuc = :time where l.id = :id")
                .setParameter("time", time).setParameter("id", log.getId()).executeUpdate();
        db.refresh(log);
        return log;
    }

    private ProcedureWriteRequest write(String code, String name, Integer version) {
        return new ProcedureWriteRequest(code, name, null, ProcedureStatus.dang_dung, version,
                null, null, null, null, null, List.of());
    }
}
