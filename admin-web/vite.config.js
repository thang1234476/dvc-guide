import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'ADMIN_');
  const proxy = {
    '/api': {
      target: env.ADMIN_API_TARGET || 'http://127.0.0.1:8080',
      // Preserve Host so same-origin browser writes pass Spring's CORS check.
      changeOrigin: false,
    },
  };
  return { server: { proxy }, preview: { proxy } };
});
