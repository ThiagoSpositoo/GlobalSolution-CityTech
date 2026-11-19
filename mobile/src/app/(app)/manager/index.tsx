import { Redirect, router } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { managerApi, occurrencesApi } from '@/api/occurrencesApi';
import type { ManagerIndicators, OccurrenceSummary } from '@/api/types';
import { useAuth } from '@/auth/AuthContext';
import { OccurrenceCard } from '@/components/OccurrenceCard';
import { Screen } from '@/components/Screen';
import { ErrorState, LoadingState } from '@/components/StateFeedback';
import { colors, radii, spacing, typography } from '@/styles/tokens';

export default function ManagerScreen() {
  const { user } = useAuth();
  const [indicators, setIndicators] = useState<ManagerIndicators>();
  const [queue, setQueue] = useState<OccurrenceSummary[]>([]);
  const [error, setError] = useState<unknown>();
  const [loading, setLoading] = useState(true);
  async function load() {
    setLoading(true);
    setError(undefined);
    try {
      const [stats, page] = await Promise.all([
        managerApi.indicators(),
        occurrencesApi.list({ page: 0, size: 20, sort: 'createdAt,desc' }),
      ]);
      setIndicators(stats);
      setQueue(page.items);
    } catch (cause) {
      setError(cause);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    if (user?.role !== 'GESTOR') return;
    let active = true;
    Promise.all([
      managerApi.indicators(),
      occurrencesApi.list({ page: 0, size: 20, sort: 'createdAt,desc' }),
    ])
      .then(([stats, page]) => {
        if (active) {
          setIndicators(stats);
          setQueue(page.items);
        }
      })
      .catch((cause: unknown) => {
        if (active) setError(cause);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [user?.role]);
  if (user?.role !== 'GESTOR') return <Redirect href="/(app)/(tabs)" />;
  if (loading)
    return (
      <Screen>
        <LoadingState label="Carregando indicadores reais..." />
      </Screen>
    );
  if (error || !indicators)
    return (
      <Screen>
        <ErrorState error={error} onRetry={() => void load()} />
      </Screen>
    );
  return (
    <Screen>
      <View>
        <Text style={styles.eyebrow}>GESTAO URBANA</Text>
        <Text style={styles.title}>Visao operacional</Text>
        <Text style={styles.subtitle}>
          O endpoint real retorna totais por status e codigo de categoria.
        </Text>
      </View>
      <View style={styles.total}>
        <Text style={styles.totalValue}>{indicators.totalOccurrences}</Text>
        <Text style={styles.totalLabel}>ocorrencias cadastradas</Text>
      </View>
      <Text style={styles.heading}>Por status</Text>
      <View style={styles.grid}>
        {Object.entries(indicators.byStatus).map(([key, value]) => (
          <View key={key} style={styles.metric}>
            <Text style={styles.metricValue}>{value}</Text>
            <Text style={styles.metricLabel}>{key.replaceAll('_', ' ')}</Text>
          </View>
        ))}
      </View>
      <Text style={styles.heading}>Por categoria</Text>
      <View style={styles.grid}>
        {Object.entries(indicators.byCategory).map(([key, value]) => (
          <View key={key} style={styles.metric}>
            <Text style={styles.metricValue}>{value}</Text>
            <Text style={styles.metricLabel}>{key}</Text>
          </View>
        ))}
      </View>
      <Text style={styles.heading}>Fila de ocorrencias</Text>
      {queue.map((item) => (
        <OccurrenceCard
          key={item.id}
          item={item}
          onPress={() =>
            router.push({ pathname: '/(app)/occurrences/[id]', params: { id: item.id } })
          }
        />
      ))}
    </Screen>
  );
}
const styles = StyleSheet.create({
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  subtitle: { ...typography.body, color: colors.textMuted },
  heading: { ...typography.heading, color: colors.text },
  total: { backgroundColor: colors.primaryDark, padding: spacing.xl, borderRadius: radii.lg },
  totalValue: { ...typography.display, color: colors.surface },
  totalLabel: { ...typography.body, color: colors.primarySoft },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  metric: {
    minWidth: '30%',
    flexGrow: 1,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radii.md,
    padding: spacing.md,
  },
  metricValue: { ...typography.title, color: colors.primary },
  metricLabel: { ...typography.caption, color: colors.textMuted },
});
