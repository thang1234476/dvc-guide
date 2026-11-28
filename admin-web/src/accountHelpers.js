export const roleLabels = { admin: 'Quản trị viên', bien_tap: 'Biên tập viên' };

export function validateNewPassword(password, confirmation) {
  if (password.length < 12 || !password.trim()) return 'Mật khẩu cần ít nhất 12 ký tự.';
  if (new TextEncoder().encode(password).length > 72) {
    return 'Mật khẩu quá dài, đặc biệt khi có ký tự tiếng Việt. Vui lòng dùng tối đa 72 byte UTF-8.';
  }
  if (password !== confirmation) return 'Xác nhận mật khẩu mới không khớp.';
  return '';
}
