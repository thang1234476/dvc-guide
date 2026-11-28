package com.dvcguide.server.admin.service;

import com.dvcguide.server.admin.dto.AdministratorResponse;
import com.dvcguide.server.admin.dto.ChangeAdministratorPasswordRequest;
import com.dvcguide.server.admin.dto.CreateAdministratorRequest;
import com.dvcguide.server.admin.dto.UpdateAdministratorProfileRequest;
import com.dvcguide.server.admin.entity.Administrator;
import com.dvcguide.server.admin.repository.AdministratorRepository;
import com.dvcguide.server.common.model.AdminRole;
import com.dvcguide.server.common.response.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdministratorService {
    private final AdministratorRepository admins;
    private final PasswordEncoder passwords;

    public PageResponse<AdministratorResponse> list(int page, int size) {
        return PageResponse.from(admins.findAll(PageRequest.of(page, size, Sort.by("id")))
                .map(AdministratorResponse::from));
    }

    @Transactional
    public AdministratorResponse create(CreateAdministratorRequest request) {
        String email = request.email().toLowerCase(Locale.ROOT);
        if (admins.findByEmailIgnoreCase(email).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email quản trị đã được sử dụng.");
        }
        Administrator admin = new Administrator();
        admin.setEmail(email);
        admin.setTenHienThi(request.displayName() == null ? null : request.displayName().strip());
        admin.setMatKhauHash(passwords.encode(request.password()));
        admin.setVaiTro(AdminRole.admin);
        admin.setHoatDong(true);
        return AdministratorResponse.from(admins.saveAndFlush(admin));
    }

    @Transactional
    public AdministratorResponse updateProfile(String email, UpdateAdministratorProfileRequest request) {
        Administrator admin = currentForUpdate(email);
        admin.setTenHienThi(request.displayName().strip());
        return AdministratorResponse.from(admins.saveAndFlush(admin));
    }

    @Transactional
    public void changePassword(String email, ChangeAdministratorPasswordRequest request) {
        Administrator admin = currentForUpdate(email);
        if (!passwords.matches(request.currentPassword(), admin.getMatKhauHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mật khẩu hiện tại không đúng.");
        }
        admin.setMatKhauHash(passwords.encode(request.newPassword()));
        admins.saveAndFlush(admin);
    }

    private Administrator currentForUpdate(String email) {
        return admins.lockByEmail(email)
                .filter(admin -> Boolean.TRUE.equals(admin.getHoatDong()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Vui lòng đăng nhập lại."));
    }
}
