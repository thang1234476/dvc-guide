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
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.UUID;
import java.util.Base64;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdministratorSessionTest {
    private static final String AUTH = "/api/v1/admin/auth";
    private static final String ME = "/api/v1/admin/me";
    private static final String PASSWORD = "admin-session-password-123";
    @Autowired private MockMvc mvc;
    @Autowired private AdministratorRepository admins;
    @Autowired private PasswordEncoder passwords;
    @Autowired private ObjectMapper json;

    @Test
    void loginPersistsAcrossRequestsRotatesTheSessionIdAndErasesCredentials() throws Exception {
        String email = seed(AdminRole.admin);
        var csrf = csrf(null);
        var session = (MockHttpSession) csrf.getRequest().getSession(false);
        String oldId = session.getId();
        mvc.perform(post(AUTH + "/login").session(session).header("X-CSRF-TOKEN", token(csrf))
                        .contentType(MediaType.APPLICATION_JSON).content(loginBody(email, PASSWORD)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.email").value(email))
                .andExpect(jsonPath("$.data.password").doesNotExist());
        assertThat(session.getId()).isNotEqualTo(oldId);
        var context = (SecurityContext) session.getAttribute(HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY);
        assertThat(context.getAuthentication().getCredentials()).isNull();
        assertThat(((UserDetails) context.getAuthentication().getPrincipal()).getPassword()).isNull();
        for (int i = 0; i < 2; i++) {
            mvc.perform(get(ME).session(session)).andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.email").value(email));
        }
    }

    @Test
    void failedLoginDoesNotAuthenticateTheSession() throws Exception {
        String email = seed(AdminRole.admin);
        var csrf = csrf(null);
        var session = (MockHttpSession) csrf.getRequest().getSession(false);
        mvc.perform(post(AUTH + "/login").session(session).header("X-CSRF-TOKEN", token(csrf))
                        .contentType(MediaType.APPLICATION_JSON).content(loginBody(email, "wrong-password")))
                .andExpect(status().isUnauthorized());
        mvc.perform(get(ME).session(session)).andExpect(status().isUnauthorized());
    }

    @Test
    void loginAndCookieAuthenticatedWritesRequireCsrfProtection() throws Exception {
        String email = seed(AdminRole.admin);
        mvc.perform(post(AUTH + "/login").contentType(MediaType.APPLICATION_JSON).content(loginBody(email, PASSWORD)))
                .andExpect(status().isForbidden());
        var session = login(email, PASSWORD);
        mvc.perform(put(ME).session(session).contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Changed\"}"))
                .andExpect(status().isForbidden());
        String forgedBasic = "Basic " + Base64.getEncoder().encodeToString((email + ":wrong-password")
                .getBytes(StandardCharsets.UTF_8));
        mvc.perform(put(ME).session(session).header("Authorization", forgedBasic)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Changed\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(post(AUTH + "/logout").session(session)).andExpect(status().isForbidden());
        mvc.perform(get(ME).session(session)).andExpect(status().isOk());
        var csrf = csrf(session);
        mvc.perform(put(ME).session(session).header("X-CSRF-TOKEN", token(csrf))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Changed\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.displayName").value("Changed"));
    }

    @Test
    void logoutInvalidatesTheSessionAndClearsTheBrowserCookie() throws Exception {
        var session = login(seed(AdminRole.admin), PASSWORD);
        var csrf = csrf(session);
        mvc.perform(post(AUTH + "/logout").session(session).header("X-CSRF-TOKEN", token(csrf)))
                .andExpect(status().isNoContent())
                .andExpect(header().string("Set-Cookie", containsString("DVC_ADMIN_SESSION=")))
                .andExpect(header().string("Set-Cookie", containsString("Max-Age=0")))
                .andExpect(header().string("Set-Cookie", containsString("HttpOnly")));
        assertThat(session.isInvalid()).isTrue();
        mvc.perform(get(ME)).andExpect(status().isUnauthorized());
    }

    @Test
    void changingPasswordRevokesAllExistingSessionsForThatAccount() throws Exception {
        String email = seed(AdminRole.admin);
        var first = login(email, PASSWORD);
        var second = login(email, PASSWORD);
        var other = login(seed(AdminRole.admin), PASSWORD);
        var csrf = csrf(first);
        String next = "new-admin-session-password-456";
        mvc.perform(post(ME + "/password").session(first).header("X-CSRF-TOKEN", token(csrf))
                        .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of(
                                "currentPassword", PASSWORD, "newPassword", next, "confirmPassword", next))))
                .andExpect(status().isNoContent());
        assertThat(first.isInvalid()).isTrue();
        mvc.perform(get(ME).session(second)).andExpect(status().isUnauthorized());
        assertThat(second.isInvalid()).isTrue();
        mvc.perform(get(ME).session(other)).andExpect(status().isOk());
        var renewed = login(email, next);
        mvc.perform(get(ME).session(renewed)).andExpect(status().isOk());
        var oldCsrf = csrf(null);
        mvc.perform(post(AUTH + "/login").session((MockHttpSession) oldCsrf.getRequest().getSession(false))
                        .header("X-CSRF-TOKEN", token(oldCsrf)).contentType(MediaType.APPLICATION_JSON).content(loginBody(email, PASSWORD)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void disablingAnAccountRevokesItsCookieSession() throws Exception {
        String email = seed(AdminRole.admin);
        var session = login(email, PASSWORD);
        var account = admins.findByEmailIgnoreCase(email).orElseThrow();
        account.setHoatDong(false);
        admins.saveAndFlush(account);
        mvc.perform(get(ME).session(session)).andExpect(status().isUnauthorized());
        assertThat(session.isInvalid()).isTrue();
    }

    @Test
    void roleChangesRequireLoginAgainAndEditorsCannotManageAccounts() throws Exception {
        String email = seed(AdminRole.admin);
        var session = login(email, PASSWORD);
        var account = admins.findByEmailIgnoreCase(email).orElseThrow();
        account.setVaiTro(AdminRole.bien_tap);
        admins.saveAndFlush(account);
        mvc.perform(get("/api/v1/admin/accounts").session(session)).andExpect(status().isUnauthorized());
        var renewed = login(email, PASSWORD);
        mvc.perform(get(ME).session(renewed)).andExpect(status().isOk());
        mvc.perform(get("/api/v1/admin/accounts").session(renewed)).andExpect(status().isForbidden());
    }

    @Test
    void administratorCookiesDoNotAuthenticatePublicAppUsers() throws Exception {
        var session = login(seed(AdminRole.admin), PASSWORD);
        mvc.perform(get("/api/v1/users/me").session(session)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/health")).andExpect(status().isOk());
    }

    private MvcResult csrf(MockHttpSession session) throws Exception {
        var request = get(AUTH + "/csrf");
        if (session != null) request.session(session);
        return mvc.perform(request).andExpect(status().isOk()).andReturn();
    }

    private String token(MvcResult csrf) throws Exception {
        return json.readTree(csrf.getResponse().getContentAsString()).path("data").path("token").asText();
    }

    private MockHttpSession login(String email, String password) throws Exception {
        var csrf = csrf(null);
        return (MockHttpSession) mvc.perform(post(AUTH + "/login")
                        .session((MockHttpSession) csrf.getRequest().getSession(false)).header("X-CSRF-TOKEN", token(csrf))
                        .contentType(MediaType.APPLICATION_JSON).content(loginBody(email, password)))
                .andExpect(status().isOk()).andReturn().getRequest().getSession(false);
    }

    private String loginBody(String email, String password) throws Exception {
        return json.writeValueAsString(Map.of("email", email, "password", password));
    }

    private String seed(AdminRole role) {
        var account = new Administrator();
        account.setEmail(UUID.randomUUID() + "@example.test");
        account.setMatKhauHash(passwords.encode(PASSWORD));
        account.setVaiTro(role);
        return admins.saveAndFlush(account).getEmail();
    }
}
