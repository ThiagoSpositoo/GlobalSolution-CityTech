import { router, useFocusEffect } from 'expo-router';
import { useCallback, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { categoriesApi, occurrencesApi } from '@/api/occurrencesApi';
import type { Category, OccurrenceStatus, OccurrenceSummary, Priority } from '@/api/types';
import { Button } from '@/components/Button';
import { ChoiceChips } from '@/components/ChoiceChips';
import { OccurrenceCard } from '@/components/OccurrenceCard';
import { Screen } from '@/components/Screen';
import { EmptyState, ErrorState, LoadingState } from '@/components/StateFeedback';
import { TextField } from '@/components/TextField';
import { colors, spacing, typography } from '@/styles/tokens';

const statuses = [
  { value: 'ABERTA', label: 'Aberta' },
  { value: 'EM_TRIAGEM', label: 'Triagem' },
  { value: 'EM_ANDAMENTO', label: 'Em andamento' },
  { value: 'RESOLVIDA', label: 'Resolvida' },
  { value: 'ENCERRADA', label: 'Encerrada' },
  { value: 'CANCELADA', label: 'Cancelada' },
] as { value: OccurrenceStatus; label: string }[];
const priorities = [
  { value: 'BAIXA', label: 'Baixa' },
  { value: 'MEDIA', label: 'Media' },
  { value: 'ALTA', label: 'Alta' },
  { value: 'CRITICA', label: 'Critica' },
] as { value: Priority; label: string }[];
export default function OccurrencesScreen() {
  const [items, setItems] = useState<OccurrenceSummary[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [status, setStatus] = useState<OccurrenceStatus>();
  const [priority, setPriority] = useState<Priority>();
  const [categoryId, setCategoryId] = useState<string>();
  const [q, setQ] = useState('');
  const [page, setPage] = useState(0);
  const [last, setLast] = useState(true);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>();
  const load = useCallback(
    async (nextPage = 0) => {
      setLoading(true);
      setError(undefined);
      try {
        const [result, categoryList] = await Promise.all([
          occurrencesApi.list({
            status,
            priority,
            categoryId,
            q: q.trim() || undefined,
            page: nextPage,
            size: 10,
            sort: 'createdAt,desc',
          }),
          categoriesApi.list(),
        ]);
        setCategories(categoryList);
        setItems((current) => (nextPage ? [...current, ...result.items] : result.items));
        setPage(result.page);
        setLast(result.last);
      } catch (cause) {
        setError(cause);
      } finally {
        setLoading(false);
      }
    },
    [categoryId, priority, q, status],
  );
  useFocusEffect(
    useCallback(() => {
      void load(0);
    }, [load]),
  );
  return (
    <Screen refreshControl={undefined}>
      <View>
        <Text style={styles.eyebrow}>DADOS EM TEMPO REAL</Text>
        <Text style={styles.title}>Ocorrencias</Text>
      </View>
      <TextField
        label="Buscar por titulo ou descricao"
        value={q}
        onChangeText={setQ}
        returnKeyType="search"
        onSubmitEditing={() => void load(0)}
      />
      <ChoiceChips<OccurrenceStatus>
        choices={statuses}
        value={status}
        onChange={setStatus}
        includeAll
      />
      <ChoiceChips<Priority>
        choices={priorities}
        value={priority}
        onChange={setPriority}
        includeAll
      />
      <ChoiceChips<string>
        choices={categories.map((c) => ({ value: c.id, label: c.name }))}
        value={categoryId}
        onChange={setCategoryId}
        includeAll
      />
      {loading && !items.length ? (
        <LoadingState />
      ) : error ? (
        <ErrorState error={error} onRetry={() => void load(0)} />
      ) : !items.length ? (
        <EmptyState
          title="Nenhuma ocorrencia"
          message="Ajuste os filtros ou registre a primeira ocorrencia."
        />
      ) : (
        <View style={styles.list}>
          {items.map((item) => (
            <OccurrenceCard
              key={item.id}
              item={item}
              onPress={() =>
                router.push({ pathname: '/(app)/occurrences/[id]', params: { id: item.id } })
              }
            />
          ))}
          {!last ? (
            <Button
              label="Carregar mais"
              variant="secondary"
              loading={loading}
              onPress={() => void load(page + 1)}
            />
          ) : null}
        </View>
      )}
    </Screen>
  );
}
const styles = StyleSheet.create({
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  list: { gap: spacing.md },
});
