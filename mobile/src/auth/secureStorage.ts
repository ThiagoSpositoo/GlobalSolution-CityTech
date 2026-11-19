import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';
import type { User } from '@/api/types';

const SESSION_KEY = 'citytech.session.v1';
let memorySession: string | null = null;

async function getStoredValue(): Promise<string | null> {
  if (Platform.OS !== 'web') return SecureStore.getItemAsync(SESSION_KEY);
  if (typeof window === 'undefined') return memorySession;

  try {
    return window.localStorage.getItem(SESSION_KEY) ?? memorySession;
  } catch {
    return memorySession;
  }
}

async function setStoredValue(value: string): Promise<void> {
  if (Platform.OS !== 'web') {
    await SecureStore.setItemAsync(SESSION_KEY, value, {
      keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    });
    return;
  }

  memorySession = value;
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(SESSION_KEY, value);
  } catch {
    // O fallback em memoria preserva a sessao enquanto esta aba permanecer aberta.
  }
}

async function deleteStoredValue(): Promise<void> {
  if (Platform.OS !== 'web') {
    await SecureStore.deleteItemAsync(SESSION_KEY);
    return;
  }

  memorySession = null;
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.removeItem(SESSION_KEY);
  } catch {
    // Nao ha armazenamento persistente a limpar quando localStorage esta indisponivel.
  }
}

export interface StoredSession {
  accessToken: string;
  expiresAt: number;
  user: User;
}

export async function readSession(): Promise<StoredSession | null> {
  const value = await getStoredValue();
  if (!value) return null;
  try {
    return JSON.parse(value) as StoredSession;
  } catch {
    await deleteStoredValue();
    return null;
  }
}
export async function writeSession(session: StoredSession) {
  await setStoredValue(JSON.stringify(session));
}
export async function clearStoredSession() {
  await deleteStoredValue();
}
