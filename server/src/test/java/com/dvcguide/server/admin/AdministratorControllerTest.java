package com.dvcguide.server.admin;

import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.common.model.AdminRole;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdministratorControllerTest {
    private static final String PATH = "/api/v1/admin/accounts";
    private static final String PASSWORD = "admin-test-password-123";
    private static final String ME = "/api/v1/admin/me";
    private static final String NEW_PASSWORD = "new-admin-password-456";

    @Autowired private MockMvc mvc;
    @Autowired private AdministratorRepository admins;
    @Autowired private PasswordEncoder passwords;
    @Autowired private ObjectMapper json;

    @Test
    void createsAnActiveAdminWhoCanAuthenticateAndRejectsDuplicateEmail() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        String newEmail = "New-" + UUID.randomUUID() + "@example.test";
        String body = json.writeValueAsString(Map.of("email", newEmail, "displayName", "Admin mới", "password", PASSWORD));

        mvc.perform(post(PATH).with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.email").value(newEmail.toLowerCase(java.util.Locale.ROOT)))
                .andExpect(jsonPath("$.data.role").value("admin"))
                .andExpect(jsonPath("$.data.active").value(true))
                .andExpect(jsonPath("$.data.password").doesNotExist())
                .andExpect(jsonPath("$.data.matKhauHash").doesNotExist());

        var created = admins.findByEmailIgnoreCase(newEmail).orElseThrow();
        assertThat(created.getMatKhauHash()).isNotEqualTo(PASSWORD);
        assertThat(passwords.matches(PASSWORD, created.getMatKhauHash())).isTrue();
        mvc.perform(get(PATH).with(httpBasic(newEmail, PASSWORD))).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].matKhauHash").doesNotExist());
        mvc.perform(post(PATH).with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict());
    }

    @Test
    void requiresAnExistingAdministratorForAccountManagement() throws Exception {
        String editor = seedAdmin(AdminRole.bien_tap);
        mvc.perform(get(PATH)).andExpect(status().isUnauthorized());
        mvc.perform(get(PATH).with(httpBasic(editor, PASSWORD))).andExpect(status().isForbidden());
        mvc.perform(post(PATH).with(httpBasic(editor, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"other@example.test\",\"password\":\"admin-test-password-123\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void rejectsPasswordOverTheBcryptByteLimit() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        String email = UUID.randomUUID() + "@example.test";
        mvc.perform(post(PATH).with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("email", email, "password", "ậ".repeat(25)))))
                .andExpect(status().isBadRequest());
        assertThat(admins.findByEmailIgnoreCase(email)).isEmpty();
    }

    @Test
    void updatesOnlyTheAuthenticatedAccountDisplayName() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        String other = seedAdmin(AdminRole.admin);
        var otherBefore = admins.findByEmailIgnoreCase(other).orElseThrow();
        mvc.perform(put(ME).with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("displayName", "  Nguyễn An  ", "email", other,
                                "id", otherBefore.getId(), "role", "bien_tap", "active", false))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.displayName").value("Nguyễn An"))
                .andExpect(jsonPath("$.data.email").value(owner))
                .andExpect(jsonPath("$.data.role").value("admin"))
                .andExpect(jsonPath("$.data.active").value(true))
                .andExpect(jsonPath("$.data.matKhauHash").doesNotExist());

        assertThat(admins.findByEmailIgnoreCase(other).orElseThrow().getTenHienThi()).isNull();
        mvc.perform(get(ME).with(httpBasic(owner, PASSWORD))).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.displayName").value("Nguyễn An"));
    }

    @Test
    void editorsCanEditTheirOwnProfileAndChangeTheirOwnPassword() throws Exception {
        String editor = seedAdmin(AdminRole.bien_tap);
        mvc.perform(put(ME).with(httpBasic(editor, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Biên tập viên A\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.role").value("bien_tap"));
        mvc.perform(post(ME + "/password").with(httpBasic(editor, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content(passwordBody(PASSWORD, NEW_PASSWORD, NEW_PASSWORD)))
                .andExpect(status().isNoContent());
        mvc.perform(get(ME).with(httpBasic(editor, NEW_PASSWORD))).andExpect(status().isOk());
    }

    @Test
    void changingPasswordRejectsOldCredentialsAndKeepsOtherAccountsUnchanged() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        String other = seedAdmin(AdminRole.admin);
        mvc.perform(post(ME + "/password").with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content(passwordBody(PASSWORD, NEW_PASSWORD, NEW_PASSWORD)))
                .andExpect(status().isNoContent()).andExpect(content().string(""));
        mvc.perform(get(ME).with(httpBasic(owner, PASSWORD))).andExpect(status().isUnauthorized());
        mvc.perform(get(ME).with(httpBasic(owner, NEW_PASSWORD))).andExpect(status().isOk());
        mvc.perform(get(ME).with(httpBasic(other, PASSWORD))).andExpect(status().isOk());
        assertThat(passwords.matches(NEW_PASSWORD, admins.findByEmailIgnoreCase(owner).orElseThrow().getMatKhauHash())).isTrue();
    }

    @Test
    void rejectsWrongCurrentPasswordWithoutChangingCredentials() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        mvc.perform(post(ME + "/password").with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content(passwordBody("wrong-password", NEW_PASSWORD, NEW_PASSWORD)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Mật khẩu hiện tại không đúng."));
        mvc.perform(get(ME).with(httpBasic(owner, PASSWORD))).andExpect(status().isOk());
    }

    @Test
    void rejectsInvalidNewPasswordAndBlankDisplayName() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        for (String body : List.of(passwordBody(PASSWORD, NEW_PASSWORD, "different-password"),
                passwordBody(PASSWORD, "short", "short"), passwordBody(PASSWORD, "ậ".repeat(25), "ậ".repeat(25)),
                passwordBody("ậ".repeat(25), NEW_PASSWORD, NEW_PASSWORD))) {
            mvc.perform(post(ME + "/password").with(httpBasic(owner, PASSWORD))
                            .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest());
        }
        mvc.perform(put(ME).with(httpBasic(owner, PASSWORD))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"   \"}"))
                .andExpect(status().isBadRequest());
        mvc.perform(get(ME).with(httpBasic(owner, PASSWORD))).andExpect(status().isOk());
    }

    @Test
    void profileChangesRequireAnActiveAdminLogin() throws Exception {
        mvc.perform(put(ME).contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Name\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post(ME + "/password").contentType(MediaType.APPLICATION_JSON)
                        .content(passwordBody(PASSWORD, NEW_PASSWORD, NEW_PASSWORD)))
                .andExpect(status().isUnauthorized());
        mvc.perform(put(ME).with(user("app-user").roles("USER"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Name\"}"))
                .andExpect(status().isForbidden());
        String inactive = seedAdmin(AdminRole.admin);
        var account = admins.findByEmailIgnoreCase(inactive).orElseThrow();
        account.setHoatDong(false);
        admins.saveAndFlush(account);
        mvc.perform(get(ME).with(httpBasic(inactive, PASSWORD))).andExpect(status().isUnauthorized());
    }

    @Test
    void onlyOneConcurrentChangeCanUseTheSameCurrentPassword() throws Exception {
        String owner = seedAdmin(AdminRole.admin);
        var start = new CountDownLatch(1);
        var executor = Executors.newFixedThreadPool(2);
        try {
            var attempts = List.of(NEW_PASSWORD, "another-admin-password-789").stream()
                    .map(next -> executor.submit(() -> {
                        if (!start.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("Change did not start");
                        return mvc.perform(post(ME + "/password").with(httpBasic(owner, PASSWORD))
                                        .contentType(MediaType.APPLICATION_JSON).content(passwordBody(PASSWORD, next, next)))
                                .andReturn().getResponse().getStatus();
                    })).toList();
            start.countDown();
            var statuses = List.of(attempts.get(0).get(15, TimeUnit.SECONDS), attempts.get(1).get(15, TimeUnit.SECONDS));
            assertThat(statuses).filteredOn(status -> status == 204).hasSize(1);
            assertThat(statuses).allMatch(status -> status == 204 || status == 400 || status == 401);
        } finally {
            executor.shutdownNow();
        }
    }

    private String passwordBody(String current, String next, String confirmation) throws Exception {
        return json.writeValueAsString(Map.of("currentPassword", current, "newPassword", next, "confirmPassword", confirmation));
    }

    private String seedAdmin(AdminRole role) {
        var admin = new Administrator();
        admin.setEmail(UUID.randomUUID() + "@example.test");
        admin.setMatKhauHash(passwords.encode(PASSWORD));
        admin.setVaiTro(role);
        admins.saveAndFlush(admin);
        return admin.getEmail();
    }
}
