import { Redirect } from 'expo-router';
import { useAuth } from '@/auth/AuthContext';
import { StaticScreen } from '@/components/Screen';
import { LoadingState } from '@/components/StateFeedback';

export default function Index() {
  const { loading, authenticated } = useAuth();
  if (loading)
    return (
      <StaticScreen>
        <LoadingState label="Restaurando sessao segura..." />
      </StaticScreen>
    );
  return <Redirect href={authenticated ? '/(app)/(tabs)' : '/(public)/welcome'} />;
}
