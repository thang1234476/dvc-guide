package com.dvcguide.server.admin;

import com.dvcguide.server.admin.dto.ProcedureImportModels.*;
import com.dvcguide.server.admin.dto.ProcedureWriteRequest;
import com.dvcguide.server.admin.entity.*;
import com.dvcguide.server.admin.repository.*;
import com.dvcguide.server.admin.service.*;
import com.dvcguide.server.chat.service.RagCatalogService;
import com.dvcguide.server.common.model.*;
import com.dvcguide.server.integration.ai.AiServiceClient;
import com.dvcguide.server.integration.rag.RagSyncClient;
import com.dvcguide.server.procedure.repository.ProcedureRepository;
import com.dvcguide.server.procedure.service.ProcedureService;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.nio.file.*;
import java.time.Instant;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:import_rag;DB_CLOSE_DELAY=-1;MODE=MySQL")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProcedureImportAndRagTest {
    @Autowired private ProcedureImportService imports;
    @Autowired private AdministratorRepository admins;
    @Autowired private PasswordEncoder passwords;
    @Autowired private ProcedureRepository procedures;
    @Autowired private ProcedureService reader;
    @Autowired private AdminProcedureService editor;
    @Autowired private RagSyncJobRepository jobs;
    @Autowired private RagSyncService sync;
    @Autowired private RagSyncWorker worker;
    @Autowired private RagCatalogService catalog;
    @Autowired private ObjectMapper json;
    @Autowired private EntityManager db;
    @Autowired private PlatformTransactionManager manager;
    @MockBean private RagSyncClient client;
    @Autowired private MockMvc mvc;

    @Test
    void exposesProtectedPreviewFileAndVersionCheckedRetryApis() throws Exception {
        String code = code(); String actor = actor();
        var body = json.writeValueAsBytes(request(sample(code)));
        mvc.perform(post("/api/v1/admin/imports/preview").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/admin/imports/preview").with(httpBasic(actor, "admin-test-password-123"))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.createCount").value(1));
        var file = new MockMultipartFile("file", "clean.json", "application/json", json.writeValueAsBytes(List.of(sample(code))));
        mvc.perform(multipart("/api/v1/admin/imports/preview-file").file(file).with(httpBasic(actor, "admin-test-password-123")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.invalidCount").value(0));
        imports.confirm(new Confirmation(request(sample(code)), Map.of(code, 0)), actor);
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        var history = mvc.perform(get("/api/v1/admin/change-logs").with(httpBasic(actor, "admin-test-password-123"))
                        .param("tableName", "thu_tuc").param("recordId", row.getId().toString()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].action").value("tao")).andReturn();
        long changeId = json.readTree(history.getResponse().getContentAsString()).at("/data/items/0/id").asLong();
        mvc.perform(get("/api/v1/admin/change-logs/" + changeId).with(httpBasic(actor, "admin-test-password-123")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.after.ma_thu_tuc").value(code))
                .andExpect(jsonPath("$.data.after.ho_so[0].mau_don.length()").value(2));
        mvc.perform(post("/api/v1/admin/rag/sync").with(httpBasic(actor, "admin-test-password-123"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"targets\":[{\"procedureId\":" + row.getId() + ",\"expectedVersion\":99}]}"))
                .andExpect(status().isConflict());
        mvc.perform(get("/api/v1/admin/rag/sources").with(httpBasic(actor, "admin-test-password-123")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.items").isArray());
    }

    @Test
    void importsLongDocumentsAllFormsAndUnknownValuesThenQueuesRag() {
        String code = code();
        var raw = sample(code);
        var request = request(raw);
        assertThat(imports.preview(request).createCount()).isEqualTo(1);
        var result = imports.confirm(new Confirmation(request, Map.of(code, 0)), actor());
        assertThat(result.failedCount()).isZero();
        assertThat(result.createdCount()).isEqualTo(1);
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        var detail = reader.detailAdmin(row.getId());
        assertThat(detail.documents().get(0).name()).hasSize(1200);
        assertThat(detail.documents().get(0).forms()).hasSize(2);
        assertThat(detail.documents().get(0).originals()).isNull();
        assertThat(detail.submissions().get(0).fees().get(0).amount()).isNull();
        assertThat(detail.submissions().get(0).fees().get(0).free()).isFalse();
        assertThat(jobs.findById(row.getId()).orElseThrow().getStatus()).isEqualTo(RagSyncJob.Status.PENDING);
        var payload = sync.claim(row.getId()).payload();
        assertThat(payload.procedure().path("extra_original_field").asText()).isEqualTo("preserved");
        assertThat(payload.procedure().path("ho_so").get(0).path("mau_don")).hasSize(2);
    }

    @Test
    void stalePreviewCannotOverwriteAnEditedProcedureAndSkipDoesNotChangeVersion() {
        String code = code();
        var request = request(sample(code));
        String actor = actor();
        imports.confirm(new Confirmation(request, Map.of(code, 0)), actor);
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        var detail = reader.detailAdmin(row.getId());
        editor.update(row.getId(), edit(detail.procedure().code(), "Tên đã sửa", 1), actor);
        var result = imports.confirm(new Confirmation(request, Map.of(code, 1)), actor);
        assertThat(result.failedCount()).isEqualTo(1);
        assertThat(procedures.findById(row.getId()).orElseThrow().getTen()).isEqualTo("Tên đã sửa");
        var skip = new Request(request.procedures(), DuplicatePolicy.SKIP_EXISTING, ProcedureStatus.dang_dung);
        assertThat(imports.confirm(new Confirmation(skip, Map.of(code, 2)), actor).skippedCount()).isEqualTo(1);
        assertThat(procedures.findById(row.getId()).orElseThrow().getPhienBan()).isEqualTo(2);
    }

    @Test
    void oldAcknowledgementCannotMarkANewerVersionAsSynced() {
        String code = code(); String actor = actor();
        imports.confirm(new Confirmation(request(sample(code)), Map.of(code, 0)), actor);
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        var first = sync.claim(row.getId());
        editor.update(row.getId(), edit(code + "R", "Tên mới", 1), actor);
        sync.acknowledge(first, success(first.id(), first.payload()));
        var state = jobs.findById(row.getId()).orElseThrow();
        assertThat(state.getDesiredVersion()).isEqualTo(2);
        assertThat(state.getIndexedVersion()).isEqualTo(1);
        assertThat(state.getStatus()).isEqualTo(RagSyncJob.Status.PENDING);
        assertThat(sync.claim(row.getId()).payload().code()).isEqualTo(code + "R");
    }

    @Test
    void failureKeepsDatabaseDataAndWorkerRetriesSuccessfully() {
        String code = code();
        imports.confirm(new Confirmation(request(sample(code)), Map.of(code, 0)), actor());
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        given(client.sync(anyInt(), any())).willThrow(new RuntimeException("offline"));
        for (int i = 0; i <= jobs.count() / 20 + 1; i++) worker.runOnce();
        var failed = jobs.findById(row.getId()).orElseThrow();
        assertThat(failed.getStatus()).isEqualTo(RagSyncJob.Status.FAILED);
        assertThat(procedures.existsById(row.getId())).isTrue();
        failed.setNextAttemptAt(Instant.EPOCH); jobs.saveAndFlush(failed);
        org.mockito.Mockito.doAnswer(call -> success(call.getArgument(0), call.getArgument(1))).when(client).sync(anyInt(), any());
        worker.runOnce();
        assertThat(jobs.findById(row.getId()).orElseThrow().getStatus()).isEqualTo(RagSyncJob.Status.SYNCED);
    }

    @Test
    void retiringRemovesSourceFromCatalogImmediatelyAndSendsTombstone() {
        String code = code(); String actor = actor();
        imports.confirm(new Confirmation(request(sample(code)), Map.of(code, 0)), actor);
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        var before = new AiServiceClient.Query("Hỏi", List.of(), List.of(), catalog.published());
        editor.retire(row.getId(), 1, actor);
        assertThat(catalog.published()).noneMatch(v -> v.procedureId() == row.getId());
        var response = new AiServiceClient.Answer("Nội dung cũ", List.of(code), AnswerStatus.answered, 10, "test");
        assertThat(catalog.validateCurrent(before, response).sourceCodes()).isEmpty();
        var claim = sync.claim(row.getId());
        assertThat(claim.payload().active()).isFalse();
        assertThat(claim.payload().procedure()).isNull();
        assertThat(claim.payload().version()).isEqualTo(2);
    }

    @Test
    void rollbackAlsoRollsBackTheQueueEntry() {
        String code = code(); String actor = actor();
        assertThatThrownBy(() -> new TransactionTemplate(manager).execute(status -> {
            var created = editor.create(edit(code, "Thủ tục sẽ rollback", null), actor);
            assertThat(jobs.existsById(created.procedure().id())).isTrue();
            throw new IllegalStateException("rollback");
        })).isInstanceOf(IllegalStateException.class);
        assertThat(procedures.findByMaThuTuc(code)).isEmpty();
    }

    @Test
    void expiredProcessingLeaseCanBeRecoveredAfterRestart() {
        String code = code();
        imports.confirm(new Confirmation(request(sample(code)), Map.of(code, 0)), actor());
        var row = procedures.findByMaThuTuc(code).orElseThrow();
        assertThat(sync.claim(row.getId())).isNotNull();
        assertThat(sync.claim(row.getId())).isNull();
        var abandoned = jobs.findById(row.getId()).orElseThrow();
        abandoned.setLeaseUntil(Instant.EPOCH); jobs.saveAndFlush(abandoned);
        assertThat(sync.claim(row.getId())).isNotNull();
        assertThat(jobs.findById(row.getId()).orElseThrow().getAttempts()).isEqualTo(2);
    }

    @Test
    void previewsAndImportsTheActual198ProcedureDatasetWithoutTruncation() throws Exception {
        Path file = Path.of("../ai-service/data/clean.json");
        org.junit.jupiter.api.Assumptions.assumeTrue(Files.isRegularFile(file));
        var nodes = json.readTree(file.toFile());
        var raw = new ArrayList<JsonNode>(); nodes.forEach(raw::add);
        var request = new Request(raw, DuplicatePolicy.UPDATE_EXISTING, ProcedureStatus.dang_dung);
        var preview = imports.preview(request);
        assertThat(preview.invalidCount()).withFailMessage("%s", preview.rows().stream().filter(r -> r.action() == RowAction.INVALID).toList()).isZero();
        var expected = new HashMap<String, Integer>(); preview.rows().forEach(r -> expected.put(r.code(), r.existingVersion() == null ? 0 : r.existingVersion()));
        var result = imports.confirm(new Confirmation(request, expected), actor());
        assertThat(result.failedCount()).withFailMessage("%s", result.issues()).isZero();
        assertThat(result.createdCount() + result.updatedCount()).isEqualTo(nodes.size());
    }

    private Request request(JsonNode raw) { return new Request(List.of(raw), DuplicatePolicy.UPDATE_EXISTING, ProcedureStatus.dang_dung); }
    private RagSyncClient.Result success(int id, RagSyncClient.Payload p) { return new RagSyncClient.Result(id, p.version(), p.code(), p.active(), p.active() ? 7 : 0, true); }
    private ProcedureWriteRequest edit(String code, String name, Integer version) {
        return new ProcedureWriteRequest(code, name, null, ProcedureStatus.dang_dung, version, null, null, null, null, null, List.of());
    }
    private ObjectNode sample(String code) {
        var p = json.createObjectNode().put("ma_thu_tuc", code).put("ten", "Thủ tục kiểm thử " + code).put("extra_original_field", "preserved");
        p.putArray("linh_vuc").addObject().put("id", "019d2bbb-69ee-7079-a6b2-8497120b2333").put("ten", "Hộ tịch");
        p.putArray("trinh_tu").add("Nộp hồ sơ");
        var d = p.putArray("ho_so").addObject().put("ten", "A".repeat(1200)).putNull("so_ban_chinh");
        var forms = d.putArray("mau_don");
        forms.addObject().put("file_id", "form-one").put("ten", "Tờ khai.docx").put("url", "https://example.test/form.docx");
        forms.addObject().put("file_id", "form-two").put("ten", "Tờ khai.pdf").put("url", "https://example.test/form.pdf");
        var s = p.putArray("cach_thuc").addObject().put("hinh_thuc", "truc_tiep");
        s.putObject("thoi_han").putNull("so").putNull("don_vi").putNull("goc");
        s.putArray("le_phi").addObject().putNull("so_tien").putNull("tien_te").put("mien_phi", false);
        return p;
    }
    private String code() { return "T-" + UUID.randomUUID().toString().substring(0, 12); }
    private String actor() {
        var admin = new Administrator(); admin.setEmail(UUID.randomUUID() + "@example.test");
        admin.setMatKhauHash(passwords.encode("admin-test-password-123")); admin.setVaiTro(AdminRole.admin);
        return admins.saveAndFlush(admin).getEmail();
    }
}
