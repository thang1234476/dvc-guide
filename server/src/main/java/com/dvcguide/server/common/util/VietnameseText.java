package com.dvcguide.server.common.util;

import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Pattern;

public final class VietnameseText {
    private static final Pattern DIACRITICS = Pattern.compile("\\p{M}+");

    private VietnameseText() {}

    public static String forSearch(String text) {
        String lower = text.strip().toLowerCase(Locale.ROOT).replace('đ', 'd');
        return DIACRITICS.matcher(Normalizer.normalize(lower, Normalizer.Form.NFD)).replaceAll("");
    }

    public static String containsPattern(String text) {
        return "%" + text.replace("!", "!!").replace("%", "!%").replace("_", "!_") + "%";
    }
}
