import { Redirect, Stack } from 'expo-router';
import { useAuth } from '@/auth/AuthContext';
import { StaticScreen } from '@/components/Screen';
import { LoadingState } from '@/components/StateFeedback';

export default function AppLayout() {
  const { authenticated, loading } = useAuth();
  if (loading)
    return (
      <StaticScreen>
        <LoadingState />
      </StaticScreen>
    );
  if (!authenticated) return <Redirect href="/(public)/login" />;
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="occurrences/[id]" options={{ title: 'Detalhes da ocorrencia' }} />
      <Stack.Screen name="occurrences/[id]/edit" options={{ title: 'Editar ocorrencia' }} />
      <Stack.Screen name="manager/index" options={{ title: 'Gestao urbana' }} />
    </Stack>
  );
}
