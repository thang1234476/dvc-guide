package com.dvcguide.server.account.service;

import com.dvcguide.server.account.entity.UserAccount;
import com.dvcguide.server.account.repository.UserAccountRepository;
import com.dvcguide.server.catalog.entity.Locality;
import com.dvcguide.server.common.exception.ResourceNotFoundException;
import jakarta.persistence.EntityManager;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Service
public class AccountService {
    private final UserAccountRepository users;
    private final SessionService sessions;
    private final PasswordEncoder passwords;
    private final EntityManager db;
    private final String dummyHash;

    public AccountService(UserAccountRepository users, SessionService sessions,
                          PasswordEncoder passwords, EntityManager db) {
        this.users = users;
        this.sessions = sessions;
        this.passwords = passwords;
        this.db = db;
        this.dummyHash = passwords.encode(java.util.UUID.randomUUID().toString());
    }

    public record Credentials(@NotBlank @Email @Size(max = 255) String email,
                              @NotBlank @Size(max = 72) String password,
                              @Size(max = 255) String device) {}

    public record Registration(@NotBlank @Email @Size(max = 255) String email,
                               @NotBlank @Size(min = 8, max = 72) String password,
                               @Size(max = 255) String displayName,
                               @Size(max = 255) String device) {}

    public record Profile(String id, String email, String displayName, Integer localityId,
                          boolean remindersEnabled) {
        static Profile from(UserAccount user) {
            return new Profile(user.getId(), user.getEmail(), user.getTenHienThi(),
                    user.getDiaPhuongId(), user.getBatNhacLich());
        }
    }

    public record Settings(@Size(max = 255) String displayName, Integer localityId,
                           @jakarta.validation.constraints.NotNull Boolean remindersEnabled) {}

    public record AuthResult(Profile user, SessionService.IssuedToken session) {}

    @Transactional
    public AuthResult register(Registration request) {
        checkPasswordLength(request.password());
        String email = request.email().toLowerCase(Locale.ROOT);
        if (users.findByEmailIgnoreCase(email).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email đã được sử dụng.");
        }
        UserAccount user = new UserAccount();
        user.setEmail(email);
        user.setTenHienThi(request.displayName());
        user.setMatKhauHash(passwords.encode(request.password()));
        users.saveAndFlush(user);
        return new AuthResult(Profile.from(user), sessions.issue(user.getId(), request.device()));
    }

    @Transactional
    public AuthResult login(Credentials request) {
        checkPasswordLength(request.password());
        UserAccount user = users.findByEmailIgnoreCase(request.email()).orElse(null);
        String hash = user == null ? null : user.getMatKhauHash();
        boolean matches = passwords.matches(request.password(), hash == null ? dummyHash : hash);
        if (!matches || hash == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Email hoặc mật khẩu không đúng.");
        }
        return new AuthResult(Profile.from(user), sessions.issue(user.getId(), request.device()));
    }

    public Profile profile(String userId) {
        return Profile.from(users.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản.")));
    }

    @Transactional
    public Profile update(String userId, Settings request) {
        UserAccount user = lockUser(userId);
        if (request.localityId() != null && db.find(Locality.class, request.localityId()) == null) {
            throw new ResourceNotFoundException("Không tìm thấy địa phương.");
        }
        user.setTenHienThi(request.displayName());
        user.setDiaPhuongId(request.localityId());
        user.setBatNhacLich(request.remindersEnabled());
        return Profile.from(user);
    }

    @Transactional
    public void clearPersonalData(String userId) {
        lockUser(userId);
        db.createQuery("delete from Dossier d where d.nguoiDungId = :user").setParameter("user", userId).executeUpdate();
        db.createQuery("delete from Conversation c where c.nguoiDungId = :user").setParameter("user", userId).executeUpdate();
        db.createQuery("delete from FavoriteProcedure f where f.nguoiDungId = :user").setParameter("user", userId).executeUpdate();
    }

    @Transactional
    public void delete(String userId) {
        users.delete(lockUser(userId));
    }

    private UserAccount lockUser(String id) {
        return users.lockById(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản."));
    }

    private void checkPasswordLength(String password) {
        if (password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu tối đa 72 byte UTF-8.");
        }
    }
}
