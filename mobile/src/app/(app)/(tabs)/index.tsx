import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router, useFocusEffect } from 'expo-router';
import { useCallback, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { followupsApi } from '@/api/followupsApi';
import { managerApi, occurrencesApi } from '@/api/occurrencesApi';
import type { ManagerIndicators, OccurrenceSummary } from '@/api/types';
import { useAuth } from '@/auth/AuthContext';
import { Button } from '@/components/Button';
import { OccurrenceCard } from '@/components/OccurrenceCard';
import { Screen } from '@/components/Screen';
import { ErrorState, LoadingState } from '@/components/StateFeedback';
import { colors, radii, spacing, typography } from '@/styles/tokens';

export default function DashboardScreen() {
  const { user, logout } = useAuth();
  const [recent, setRecent] = useState<OccurrenceSummary[]>([]);
  const [followups, setFollowups] = useState(0);
  const [indicators, setIndicators] = useState<ManagerIndicators>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>();
  const load = useCallback(async () => {
    setLoading(true);
    setError(undefined);
    try {
      const [occurrencePage, followupPage] = await Promise.all([
        occurrencesApi.list({ page: 0, size: 3, sort: 'createdAt,desc' }),
        followupsApi.list(0, 1),
      ]);
      setRecent(occurrencePage.items);
      setFollowups(followupPage.totalElements);
      if (user?.role === 'GESTOR') setIndicators(await managerApi.indicators());
      else
        setIndicators({
          totalOccurrences: occurrencePage.totalElements,
          byStatus: {},
          byCategory: {},
        });
    } catch (cause) {
      setError(cause);
    } finally {
      setLoading(false);
    }
  }, [user]);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  if (loading)
    return (
      <Screen>
        <LoadingState label="Carregando resumo real..." />
      </Screen>
    );
  if (error)
    return (
      <Screen>
        <ErrorState error={error} onRetry={() => void load()} />
      </Screen>
    );
  return (
    <Screen>
      <View style={styles.top}>
        <View>
          <Text style={styles.eyebrow}>
            {user?.role === 'GESTOR' ? 'PAINEL DO GESTOR' : 'AREA DO CIDADAO'}
          </Text>
          <Text style={styles.title}>Ola, {user?.name.split(' ')[0]}</Text>
        </View>
        <Pressable accessibilityLabel="Sair" onPress={() => void logout()}>
          <MaterialCommunityIcons name="logout" size={25} color={colors.danger} />
        </Pressable>
      </View>
      <View style={styles.grid}>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{indicators?.totalOccurrences ?? 0}</Text>
          <Text style={styles.metricLabel}>
            {user?.role === 'GESTOR' ? 'ocorrencias na cidade' : 'minhas ocorrencias'}
          </Text>
        </View>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{followups}</Text>
          <Text style={styles.metricLabel}>acompanhamentos</Text>
        </View>
      </View>
      {user?.role === 'GESTOR' ? (
        <Button label="Abrir gestao e indicadores" onPress={() => router.push('/(app)/manager')} />
      ) : (
        <Button
          label="Registrar nova ocorrencia"
          onPress={() => router.push('/(app)/(tabs)/new-occurrence')}
        />
      )}
      <View style={styles.section}>
        <Text style={styles.heading}>Ocorrencias recentes</Text>
        {recent.map((item) => (
          <OccurrenceCard
            key={item.id}
            item={item}
            onPress={() =>
              router.push({ pathname: '/(app)/occurrences/[id]', params: { id: item.id } })
            }
          />
        ))}
      </View>
      <Button label="Sobre o App" variant="ghost" onPress={() => router.push('/about')} />
    </Screen>
  );
}
const styles = StyleSheet.create({
  top: {
    marginTop: spacing.sm,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  eyebrow: { ...typography.caption, fontWeight: '800', color: colors.success },
  title: { ...typography.display, color: colors.text },
  grid: { flexDirection: 'row', gap: spacing.md },
  metric: {
    flex: 1,
    padding: spacing.lg,
    borderRadius: radii.lg,
    backgroundColor: colors.primaryDark,
  },
  metricValue: { ...typography.display, color: colors.surface },
  metricLabel: { ...typography.caption, color: colors.primarySoft },
  section: { gap: spacing.md },
  heading: { ...typography.heading, color: colors.text },
});
