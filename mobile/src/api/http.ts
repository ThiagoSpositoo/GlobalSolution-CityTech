import { create, type AxiosInstance } from 'axios';
import { normalizeApiError } from './errors';

let token: string | null = null;
let unauthorizedHandler: (() => void) | null = null;
let handlingUnauthorized = false;
let sessionController = new AbortController();

export function setHttpSession(accessToken: string | null, onUnauthorized?: () => void) {
  if (token && !accessToken) {
    sessionController.abort();
    sessionController = new AbortController();
  }
  token = accessToken;
  unauthorizedHandler = onUnauthorized ?? unauthorizedHandler;
  if (accessToken) handlingUnauthorized = false;
}

export function createHttpClient(baseURL: string): AxiosInstance {
  const client = create({ baseURL: `${baseURL}/api/v1`, timeout: 15_000 });
  client.interceptors.request.use((config) => {
    config.timeout = config.method?.toLowerCase() === 'get' ? 10_000 : 15_000;
    config.signal ??= sessionController.signal;
    if (token && !config.url?.includes('/auth/login') && !config.url?.includes('/auth/register')) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });
  client.interceptors.response.use(
    (response) => response,
    (error: unknown) => {
      const normalized = normalizeApiError(error);
      if (normalized.status === 401 && token && !handlingUnauthorized) {
        handlingUnauthorized = true;
        unauthorizedHandler?.();
      }
      return Promise.reject(normalized);
    },
  );
  return client;
}
