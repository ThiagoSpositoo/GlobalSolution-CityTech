import { Redirect, Stack } from 'expo-router';
import { useAuth } from '@/auth/AuthContext';
export default function PublicLayout() {
  const { authenticated, loading } = useAuth();
  if (!loading && authenticated) return <Redirect href="/(app)/(tabs)" />;
  return <Stack screenOptions={{ headerShown: false }} />;
}
