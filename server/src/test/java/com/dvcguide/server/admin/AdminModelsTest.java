package com.dvcguide.server.admin;

import com.dvcguide.server.admin.dto.ChangeLogModels;
import com.dvcguide.server.admin.dto.ChangeAdministratorPasswordRequest;
import com.dvcguide.server.admin.dto.AdministratorLoginRequest;
import com.dvcguide.server.admin.dto.CleanProcedureData;
import com.dvcguide.server.admin.dto.CreateAdministratorRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class AdminModelsTest {
    private final ObjectMapper json = new ObjectMapper();

    @Test
    void preservesVietnameseSourceFieldsAndUnknownAmounts() throws Exception {
        String input = """
                {
                  "schema_version": "1.0",
                  "id": "source-uuid",
                  "ma_thu_tuc": "DEMO-001",
                  "ten": "Đăng ký demo",
                  "ho_so": [{
                    "nhom": "nop",
                    "ten": "Tờ khai",
                    "truong_hop": null,
                    "so_ban_chinh": null,
                    "so_ban_sao": 1,
                    "mau_don": [{
                      "ten": "Tờ khai.docx", "file_id": "form-uuid", "url": null, "loi_tai": "Chưa có link"
                    }]
                  }],
                  "cach_thuc": [{
                    "hinh_thuc": "truc_tiep",
                    "thoi_han": {"so": null, "don_vi": null, "goc": null},
                    "le_phi": [{"so_tien": null, "tien_te": null, "mien_phi": false, "ghi_chu": null}]
                  }],
                  "nguon": {"ngay_cao": "2026-10-10T06:26:35+00:00"},
                  "chat_luong": {"canh_bao": ["Thiếu thời hạn"]}
                }
                """;
        CleanProcedureData row = json.readValue(input, CleanProcedureData.class);
        assertThat(row.sourceId()).isEqualTo("source-uuid");
        assertThat(row.code()).isEqualTo("DEMO-001");
        assertThat(row.documents().get(0).originals()).isNull();
        assertThat(row.documents().get(0).forms().get(0).downloadError()).isEqualTo("Chưa có link");
        assertThat(row.submissions().get(0).fees().get(0).amount()).isNull();
        assertThat(row.submissions().get(0).fees().get(0).free()).isFalse();
        var serialized = json.valueToTree(row);
        assertThat(serialized.path("ma_thu_tuc").asText()).isEqualTo("DEMO-001");
        assertThat(serialized.path("ho_so").get(0).path("so_ban_chinh").isNull()).isTrue();
        assertThat(serialized.path("nguon")).isEqualTo(json.readTree(input).path("nguon"));
        assertThat(serialized.has("code")).isFalse();
    }

    @Test
    void registrationAcceptsPasswordWithoutSerializingOrLoggingIt() throws Exception {
        var request = json.readValue("""
                {"email":"admin@example.test","displayName":"Admin","password":"private-demo-password"}
                """, CreateAdministratorRequest.class);
        assertThat(request.password()).isEqualTo("private-demo-password");
        assertThat(json.writeValueAsString(request)).doesNotContain("private-demo-password", "password");
        assertThat(request.toString()).doesNotContain("private-demo-password");
    }

    @Test
    void passwordChangesNeverSerializeOrLogSecrets() throws Exception {
        var request = json.readValue("""
                {"currentPassword":"private-old-password","newPassword":"private-new-password",
                 "confirmPassword":"private-new-password"}
                """, ChangeAdministratorPasswordRequest.class);
        assertThat(request.currentPassword()).isEqualTo("private-old-password");
        assertThat(json.writeValueAsString(request)).doesNotContain("private-old-password", "private-new-password");
        assertThat(request.toString()).doesNotContain("private-old-password", "private-new-password");
        var login = new AdministratorLoginRequest("admin@example.test", "private-login-password");
        assertThat(json.writeValueAsString(login)).doesNotContain("private-login-password");
        assertThat(login.toString()).doesNotContain("private-login-password");
    }

    @Test
    void validatesPasswordBytesAndChangeLogDateRange() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var validator = factory.getValidator();
            var password = new CreateAdministratorRequest("admin@example.test", "Admin", "ậ".repeat(25));
            assertThat(password.password().length()).isLessThan(72);
            assertThat(validator.validate(password)).isNotEmpty();
            var filter = new ChangeLogModels.Filter(null, "thu_tuc", null, null,
                    Instant.parse("2026-12-02T00:00:00Z"), Instant.parse("2026-12-01T00:00:00Z"));
            assertThat(validator.validate(filter)).isNotEmpty();
        }
    }
}
