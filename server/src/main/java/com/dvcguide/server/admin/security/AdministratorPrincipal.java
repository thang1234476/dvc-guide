package com.dvcguide.server.admin.security;

import com.dvcguide.server.admin.entity.Administrator;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;

public final class AdministratorPrincipal extends User {
    private final int administratorId;
    private final String passwordVersion;

    public AdministratorPrincipal(Administrator admin) {
        super(admin.getEmail(), admin.getMatKhauHash(), Boolean.TRUE.equals(admin.getHoatDong()),
                true, true, true, List.of(new SimpleGrantedAuthority(authority(admin))));
        administratorId = admin.getId();
        passwordVersion = version(admin.getMatKhauHash());
    }

    public int administratorId() {
        return administratorId;
    }

    public boolean isCurrent(Administrator admin) {
        return Boolean.TRUE.equals(admin.getHoatDong()) && getUsername().equals(admin.getEmail())
                && passwordVersion.equals(version(admin.getMatKhauHash()))
                && getAuthorities().contains(new SimpleGrantedAuthority(authority(admin)));
    }

    private static String authority(Administrator admin) {
        return "ROLE_" + admin.getVaiTro().name().toUpperCase(Locale.ROOT);
    }

    private static String version(String hash) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(hash.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
