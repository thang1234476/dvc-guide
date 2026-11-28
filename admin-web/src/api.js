async function readResponse(response) {
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

export async function api(path, { body, method = 'GET', signal, download = false } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  if (path.startsWith('/admin/') && !['GET', 'HEAD', 'OPTIONS'].includes(method.toUpperCase())) {
    const csrfResponse = await fetch('/api/v1/admin/auth/csrf', {
      credentials: 'same-origin', cache: 'no-store', headers: { Accept: 'application/json' }, signal,
    });
    const csrf = await readResponse(csrfResponse);
    headers[csrf.headerName] = csrf.token;
  }

  const response = await fetch(`/api/v1${path}`, {
    credentials: 'same-origin',
    cache: 'no-store',
    headers,
    method,
    signal,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (download && response.ok) {
    const disposition = response.headers.get('Content-Disposition') ?? '';
    const filename = /filename="([a-zA-Z0-9._-]+)"/.exec(disposition)?.[1];
    return { blob: await response.blob(), filename };
  }
  return readResponse(response);
}
