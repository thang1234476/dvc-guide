package com.dvcguide.server.admin;

import com.dvcguide.server.admin.dto.ProcedureWriteRequest;
import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.entity.RagSyncJob;
import com.dvcguide.server.admin.repository.*;
import com.dvcguide.server.admin.service.*;
import com.dvcguide.server.catalog.entity.ProcedureField;
import com.dvcguide.server.common.model.*;
import com.dvcguide.server.integration.rag.RagSyncClient;
import com.dvcguide.server.procedure.service.ProcedureService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.doAnswer;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:full_procedure;DB_CLOSE_DELAY=-1;MODE=MySQL")
@AutoConfigureMockMvc @ActiveProfiles("test") @Transactional
class FullProcedureContentTest {
    static final String PATH = "/api/v1/admin/procedures", PASSWORD = "temporary-admin-test-password";
    static final String FIELD_SOURCE = "019d2bbb-69ee-7079-a6b4-536173b5e483";
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired EntityManager db;
    @Autowired AdministratorRepository admins;
    @Autowired PasswordEncoder passwords;
    @Autowired AdminProcedureService editor;
    @Autowired ProcedureService reader;
    @Autowired ProcedureExportService exports;
    @Autowired RagSyncJobRepository jobs;
    @Autowired RagSyncWorker worker;
    @MockBean RagSyncClient client;

    @Test void fullCreateReadAndJsonDownloadPreserveNestedContentAndSourceIds() throws Exception {
        var actor=actor(); int field=field(); var raw=sample();
        var result=mvc.perform(post(PATH).with(httpBasic(actor,PASSWORD)).contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsBytes(input(raw,field,null,ProcedureStatus.dang_dung))))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.documents[0].forms.length()").value(2))
                .andExpect(jsonPath("$.data.cleanData.co_quan.tham_quyen").value("Cơ quan thẩm quyền")).andReturn();
        int id=json.readTree(result.getResponse().getContentAsByteArray()).at("/data/procedure/id").asInt();
        assertThat(json.readTree(exports.one(id)).get(0)).isEqualTo(raw);
        mvc.perform(get(PATH+"/"+id+"/export").with(httpBasic(actor,PASSWORD))).andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition","attachment; filename=\"thu-tuc-"+id+".json\""))
                .andExpect(content().contentType(MediaType.APPLICATION_JSON)).andExpect(jsonPath("$[0].linh_vuc[0].id").value(FIELD_SOURCE));
        mvc.perform(get("/api/v1/procedures/"+id)).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cleanData.cach_thuc[0].mo_ta").value("Mô tả cách nộp"));
    }

    @Test void nestedEditsDoNotChangeSharedFormsOrLegalTitlesOfOtherProcedures() throws Exception {
        var actor=actor(); int field=field(); var original=sample();
        var first=editor.create(input(original,field,null,ProcedureStatus.dang_dung),actor);
        var another=sample(); var second=editor.create(input(another,field,null,ProcedureStatus.dang_dung),actor);
        var changed=original.deepCopy();
        ((ObjectNode)changed.at("/ho_so/0/mau_don/0")).put("url","https://drive.google.com/new-form");
        ((ObjectNode)changed.at("/cach_thuc/0/le_phi/0")).put("so_tien",25000);
        ((ObjectNode)changed.at("/can_cu/0")).put("ten","Tên căn cứ đã hiệu đính cho thủ tục này");
        changed.putArray("trinh_tu").add("Bước đã sửa").add("Bước mới"); changed.withArray("ho_so").remove(1);
        var updated=editor.update(first.procedure().id(),input(changed,field,1,ProcedureStatus.dang_dung),actor);
        assertThat(updated.procedure().version()).isEqualTo(2); assertThat(updated.steps()).hasSize(2); assertThat(updated.documents()).hasSize(1);
        assertThat(updated.documents().get(0).forms().get(0).docxUrl()).isEqualTo("https://drive.google.com/new-form");
        assertThat(updated.submissions().get(0).fees().get(0).amount()).isEqualByComparingTo("25000");
        assertThat(updated.legalBases().get(0).name()).isEqualTo("Tên căn cứ đã hiệu đính cho thủ tục này");
        var untouched=reader.detailAdmin(second.procedure().id());
        assertThat(untouched.documents().get(0).forms().get(0).docxUrl()).isEqualTo("https://drive.google.com/old-form");
        assertThat(untouched.legalBases().get(0).name()).isEqualTo("Văn bản kiểm thử");
        assertThat(json.readTree(exports.one(first.procedure().id())).get(0)).isEqualTo(changed);
    }

    @Test void noOpAndMetadataOnlyUpdatesPreserveVersionOrUnchangedDocumentIds() throws Exception {
        var actor=actor(); int field=field(); var raw=sample();
        var first=editor.create(input(raw,field,null,ProcedureStatus.dang_dung),actor); int id=first.procedure().id();
        assertThat(editor.update(id,input(raw,field,1,ProcedureStatus.dang_dung),actor).procedure().version()).isEqualTo(1);
        raw.put("so_quyet_dinh","QĐ-MỚI");
        var updated=editor.update(id,input(raw,field,1,ProcedureStatus.dang_dung),actor);
        assertThat(updated.procedure().version()).isEqualTo(2);
        assertThat(updated.documents().get(0).id()).isEqualTo(first.documents().get(0).id());
    }

    @Test void offlineAiKeepsSavedContentAndManualRetrySendsLatestVersion() throws Exception {
        var actor=actor(); int field=field(); var raw=sample();
        int id=editor.create(input(raw,field,null,ProcedureStatus.dang_dung),actor).procedure().id();
        given(client.sync(anyInt(),any())).willThrow(new IllegalStateException("AI-service chưa chạy")); worker.runOnce();
        assertThat(jobs.findById(id).orElseThrow().getStatus()).isEqualTo(RagSyncJob.Status.FAILED);
        assertThat(json.readTree(exports.one(id)).get(0)).isEqualTo(raw);
        raw.put("so_quyet_dinh","QĐ-PHIÊN-BẢN-2"); editor.update(id,input(raw,field,1,ProcedureStatus.dang_dung),actor);
        doAnswer(call->{
            var p=call.getArgument(1,RagSyncClient.Payload.class);
            assertThat(p.version()).isEqualTo(2); assertThat(p.procedure().path("so_quyet_dinh").asText()).isEqualTo("QĐ-PHIÊN-BẢN-2");
            return new RagSyncClient.Result(id,p.version(),p.code(),true,12,true);
        }).when(client).sync(eq(id),any());
        mvc.perform(post("/api/v1/admin/rag/sync").with(httpBasic(actor,PASSWORD)).contentType(MediaType.APPLICATION_JSON)
                .content("{\"targets\":[{\"procedureId\":"+id+",\"expectedVersion\":2}]}" )).andExpect(status().isAccepted());
        worker.runOnce(); assertThat(jobs.findById(id).orElseThrow().getStatus()).isEqualTo(RagSyncJob.Status.SYNCED);
        assertThat(jobs.findById(id).orElseThrow().getIndexedVersion()).isEqualTo(2);
    }

    @Test void exportsRequireAuthenticationAndRespectExplicitAllOrActiveScope() throws Exception {
        var actor=actor(); int field=field();
        for(var state:ProcedureStatus.values()) editor.create(input(sample(),field,null,state),actor);
        mvc.perform(get(PATH+"/export")).andExpect(status().isUnauthorized());
        mvc.perform(get(PATH+"/export").with(user("app-user").roles("USER"))).andExpect(status().isForbidden());
        mvc.perform(get(PATH+"/export").with(httpBasic(actor,PASSWORD))).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(3));
        mvc.perform(get(PATH+"/export").param("activeOnly","true").with(httpBasic(actor,PASSWORD))).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1));
        mvc.perform(get(PATH+"/999999/export").with(httpBasic(actor,PASSWORD))).andExpect(status().isNotFound());
    }

    @Test void invalidContentAndStaleVersionDoNotPartiallyUpdateData() throws Exception {
        var actor=actor(); int field=field(); var raw=sample(); int id=editor.create(input(raw,field,null,ProcedureStatus.dang_dung),actor).procedure().id();
        mvc.perform(put(PATH+"/"+id).with(httpBasic(actor,PASSWORD)).contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsBytes(input(raw,field,99,ProcedureStatus.dang_dung)))).andExpect(status().isConflict());
        var wrongId=raw.deepCopy().put("id","changed-source"); var invalid=raw.deepCopy(); ((ObjectNode)invalid.at("/ho_so/0")).put("so_ban_chinh",-1);
        for(var value:List.of(wrongId,invalid)) mvc.perform(put(PATH+"/"+id).with(httpBasic(actor,PASSWORD)).contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsBytes(input(value,field,1,ProcedureStatus.dang_dung)))).andExpect(status().isBadRequest());
        assertThat(reader.detailAdmin(id).procedure().version()).isEqualTo(1); assertThat(json.readTree(exports.one(id)).get(0)).isEqualTo(raw);
    }

    String actor(){var a=new Administrator();a.setEmail(UUID.randomUUID()+"@example.test");a.setMatKhauHash(passwords.encode(PASSWORD));a.setVaiTro(AdminRole.admin);return admins.saveAndFlush(a).getEmail();}
    int field(){var f=new ProcedureField();f.setMa(ProcedureContentWriter.key(FIELD_SOURCE,28));f.setTen("Hộ tịch");db.persist(f);db.flush();return f.getId();}
    ProcedureWriteRequest input(ObjectNode raw,int field,Integer version,ProcedureStatus status){return new ProcedureWriteRequest(raw.path("ma_thu_tuc").asText(),raw.path("ten").asText(),null,status,version,raw.at("/co_quan/thuc_hien").asText(),raw.path("doi_tuong").asText(),raw.path("yeu_cau_dieu_kien").asText(),null,null,List.of(field),raw);}
    ObjectNode sample() throws Exception {
        var raw=(ObjectNode)json.readTree("""
          {"schema_version":"1.0","id":"source-123","ma_thu_tuc":"PLACEHOLDER","ten":"Đăng ký giám sát việc giám hộ",
          "so_quyet_dinh":"QĐ-123","cap_thuc_hien":"","loai_thu_tuc":"OTHER","doi_tuong":"Công dân Việt Nam",
          "linh_vuc":[{"id":"019d2bbb-69ee-7079-a6b4-536173b5e483","ten":"Hộ tịch"}],
          "co_quan":{"thuc_hien":"Cơ quan thực hiện","tham_quyen":"Cơ quan thẩm quyền","dia_chi_tiep_nhan":"Địa chỉ tiếp nhận","uy_quyen":"Đơn vị ủy quyền","phoi_hop":"Đơn vị phối hợp"},
          "trinh_tu":["Nộp hồ sơ"],"cach_thuc":[{"hinh_thuc":"truc_tiep","hinh_thuc_goc":"DIRECT","thoi_han":{"so":3,"don_vi":"khac","goc":"3 OTHER"},"mo_ta":"Mô tả cách nộp","le_phi":[{"so_tien":15000,"tien_te":"VND","mien_phi":false,"ghi_chu":"Ghi chú mức thu"}]}],
          "ho_so":[{"nhom":"nop","truong_hop":"Giấy tờ phải nộp:","ten":"Tờ khai","so_ban_chinh":1,"so_ban_sao":0,"mau_don":[{"ten":"Tờ khai.docx","file_id":"form-shared","url":"https://drive.google.com/old-form"},{"ten":"Tờ khai.pdf","file_id":"form-pdf","url":"https://drive.google.com/form-pdf"}]},
          {"nhom":"nop","truong_hop":"Lưu ý:","ten":"Giữ nguyên lưu ý nguồn","so_ban_chinh":0,"so_ban_sao":0,"mau_don":[]}],
          "can_cu":[{"ma":"VB-123","ten":"Văn bản kiểm thử"}],"yeu_cau_dieu_kien":"Điều kiện nguồn","ket_qua":[{"ten":"Trích lục","ma":"KQ-123"}],"tu_khoa":["giám hộ"],"nguon":{"id_noi_bo":"source-123"},"extra_metadata":{"preserved":true}}
          """);raw.put("ma_thu_tuc","FULL-"+UUID.randomUUID());return raw;
    }
}
