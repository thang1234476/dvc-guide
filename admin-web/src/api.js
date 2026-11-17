export function basicCredentials(email, password) {
  const bytes = new TextEncoder().encode(`${email}:${password}`);
  return `Basic ${btoa(Array.from(bytes, (byte) => String.fromCharCode(byte)).join(''))}`;
}

export async function api(path, { authorization, body, method = 'GET', signal } = {}) {
  const headers = { Accept: 'application/json' };
  if (authorization) headers.Authorization = authorization;
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  const response = await fetch(`/api/v1${path}`, {
    credentials: 'omit',
    cache: 'no-store',
    headers,
    method,
    signal,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (response.status === 204) return undefined;

  const payload = await response.json().catch(() => null);
  if (!response.ok || payload?.success !== true) {
    const error = new Error(
      response.status === 401 ? 'Thông tin đăng nhập không hợp lệ hoặc phiên đã kết thúc.' :
      payload?.message || 'Không thể đọc phản hồi từ máy chủ.',
    );
    error.status = response.status;
    throw error;
  }
  return payload.data;
}
