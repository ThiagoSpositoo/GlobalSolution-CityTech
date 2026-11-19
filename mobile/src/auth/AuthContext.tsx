import { router } from 'expo-router';
import { createContext, useContext, useEffect, useState, type PropsWithChildren } from 'react';
import { authApi } from '@/api/authApi';
import { setHttpSession } from '@/api/http';
import type { LoginRequest, RegisterRequest, User } from '@/api/types';
import { createIdempotencyKey } from '@/utils/idempotency';
import { clearStoredSession, readSession, writeSession } from './secureStorage';

interface AuthValue {
  user: User | null;
  loading: boolean;
  authenticated: boolean;
  login(input: LoginRequest): Promise<void>;
  register(input: RegisterRequest): Promise<void>;
  logout(): Promise<void>;
}
const AuthContext = createContext<AuthValue | null>(null);

export function AuthProvider({ children }: PropsWithChildren) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  async function logout() {
    setHttpSession(null);
    setUser(null);
    await clearStoredSession();
    router.replace('/(public)/welcome');
  }
  async function persist(accessToken: string, expiresIn: number, nextUser: User) {
    const session = { accessToken, expiresAt: Date.now() + expiresIn * 1000, user: nextUser };
    await writeSession(session);
    setHttpSession(accessToken, () => {
      void logout();
    });
    setUser(nextUser);
  }
  async function login(input: LoginRequest) {
    const response = await authApi.login(input);
    await persist(response.accessToken, response.expiresIn, response.user);
    router.replace('/(app)/(tabs)');
  }
  async function register(input: RegisterRequest) {
    await authApi.register(input, createIdempotencyKey());
    await login({ email: input.email, password: input.password });
  }

  useEffect(() => {
    let active = true;
    async function restore() {
      const stored = await readSession();
      if (!active) return;
      if (!stored || stored.expiresAt <= Date.now()) {
        await clearStoredSession();
        setLoading(false);
        return;
      }
      setHttpSession(stored.accessToken, () => {
        void logout();
      });
      try {
        const current = await authApi.me();
        if (active) {
          setUser(current);
          await writeSession({ ...stored, user: current });
        }
      } catch {
        await clearStoredSession();
        setHttpSession(null);
      } finally {
        if (active) setLoading(false);
      }
    }
    void restore();
    return () => {
      active = false;
    };
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, loading, authenticated: Boolean(user), login, register, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
}
export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error('useAuth deve ser usado dentro de AuthProvider.');
  return value;
}
