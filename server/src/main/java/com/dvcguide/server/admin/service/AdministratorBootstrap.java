package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.common.model.AdminRole;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Component
public class AdministratorBootstrap implements ApplicationRunner {
    private final AdministratorRepository admins;
    private final PasswordEncoder passwords;
    private final String email;
    private final String password;

    public AdministratorBootstrap(AdministratorRepository admins, PasswordEncoder passwords,
                                  @Value("${ADMIN_BOOTSTRAP_EMAIL:}") String email,
                                  @Value("${ADMIN_BOOTSTRAP_PASSWORD:}") String password) {
        this.admins = admins;
        this.passwords = passwords;
        this.email = email.strip().toLowerCase(Locale.ROOT);
        this.password = password;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (email.isEmpty() || admins.count() > 0) {
            return;
        }
        if (!email.matches("[^@\\s]+@[^@\\s]+") || email.length() > 255
                || password.isBlank() || password.length() < 12
                || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalStateException("Set a valid bootstrap email and a password of 12 characters to 72 UTF-8 bytes.");
        }
        var admin = new Administrator();
        admin.setEmail(email);
        admin.setVaiTro(AdminRole.admin);
        admin.setMatKhauHash(passwords.encode(password));
        admins.save(admin);
    }
}
