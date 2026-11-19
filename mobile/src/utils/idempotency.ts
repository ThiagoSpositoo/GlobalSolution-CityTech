import * as Crypto from 'expo-crypto';
export function createIdempotencyKey() {
  return Crypto.randomUUID();
}
