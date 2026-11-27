/// Vietnamese text utilities for search and normalization without external dependencies.
class VietnameseUtils {
  VietnameseUtils._();

  /// Removes Vietnamese diacritics and converts "đ/Đ" to "d/D".
  static String removeDiacritics(String str) {
    var result = str;

    // Convert special characters đ/Đ first
    result = result.replaceAll('đ', 'd').replaceAll('Đ', 'D');

    // Replacement map for Vietnamese accents
    const map = {
      'a': 'áàạảãâấầậẩẫăắằặẳẵ',
      'A': 'ÁÀẠẢÃÂẤẦẬẨẪĂẮẰẶẲẴ',
      'e': 'éèẹẻẽêếềệểễ',
      'E': 'ÉÈẸẺẼÊẾỀỆỂỄ',
      'o': 'óòọỏõôốồộổỗơớờợởỡ',
      'O': 'ÓÒỌỎÕÔỐỒỘỔỖƠỚỜỢỞỠ',
      'u': 'úùụủũưứừựửữ',
      'U': 'ÚÙỤỦŨƯỨỪỰỬỮ',
      'i': 'íìịỉĩ',
      'I': 'ÍÌỊỈĨ',
      'y': 'ýỳỵỷỹ',
      'Y': 'ÝỲỴỶỸ',
    };

    for (final entry in map.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        result = result.replaceAll(entry.value[i], entry.key);
      }
    }

    return result;
  }

  /// Normalizes a string for search: removes diacritics, converts to lowercase and trims.
  static String toSearchable(String input) {
    return removeDiacritics(input).toLowerCase().trim();
  }
}
