import { dotnetClient } from './dotnetClient';
import type { Account, LoginRequest, LoginResponse, RegisterRequest, User } from './types';

export const authApi = {
  async register(input: RegisterRequest, idempotencyKey: string) {
    const { data } = await dotnetClient.post<Account>('/auth/register', input, {
      headers: { 'Idempotency-Key': idempotencyKey },
    });
    return data;
  },
  async login(input: LoginRequest) {
    const { data } = await dotnetClient.post<LoginResponse>('/auth/login', input);
    return data;
  },
  async me() {
    const { data } = await dotnetClient.get<User>('/auth/me');
    return data;
  },
};
