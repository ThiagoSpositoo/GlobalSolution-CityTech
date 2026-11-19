import { router, useFocusEffect } from 'expo-router';
import { useCallback, useState } from 'react';
import { Alert, StyleSheet, Text, View } from 'react-native';
import { normalizeApiError } from '@/api/errors';
import { followupsApi } from '@/api/followupsApi';
import { occurrencesApi } from '@/api/occurrencesApi';
import type { FollowUp, Occurrence } from '@/api/types';
import { Button } from '@/components/Button';
import { Screen } from '@/components/Screen';
import { EmptyState, ErrorState, LoadingState } from '@/components/StateFeedback';
import { TextField } from '@/components/TextField';
import { colors, radii, spacing, typography } from '@/styles/tokens';
import { formatDate, nullable } from '@/utils/formatters';

interface Row {
  followup: FollowUp;
  occurrence?: Occurrence;
  unavailable?: string;
}
export default function FollowupsScreen() {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>();
  const [occurrenceId, setOccurrenceId] = useState('');
  const [newNote, setNewNote] = useState('');
  const [editing, setEditing] = useState<string>();
  const [editNote, setEditNote] = useState('');
  const [message, setMessage] = useState<string>();
  const load = useCallback(async () => {
    setLoading(true);
    setError(undefined);
    try {
      const page = await followupsApi.list(0, 100);
      const hydrated: Row[] = [];
      for (let index = 0; index < page.items.length; index += 5) {
        const batch = page.items.slice(index, index + 5);
        hydrated.push(
          ...(await Promise.all(
            batch.map(async (followup): Promise<Row> => {
              try {
                return { followup, occurrence: await occurrencesApi.get(followup.occurrenceId) };
              } catch (cause) {
                return { followup, unavailable: normalizeApiError(cause).message };
              }
            }),
          )),
        );
      }
      setRows(hydrated);
    } catch (cause) {
      setError(cause);
    } finally {
      setLoading(false);
    }
  }, []);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  async function create() {
    if (!occurrenceId.trim()) {
      setMessage('Informe o UUID de uma ocorrencia visivel.');
      return;
    }
    setMessage(undefined);
    try {
      await followupsApi.create(
        { occurrenceId: occurrenceId.trim(), note: nullable(newNote) },
        (await import('@/utils/idempotency')).createIdempotencyKey(),
      );
      setOccurrenceId('');
      setNewNote('');
      await load();
    } catch (cause) {
      const normalized = normalizeApiError(cause);
      setMessage(
        normalized.code === 'FOLLOWUP_ALREADY_EXISTS'
          ? 'Esta ocorrencia ja esta nos seus acompanhamentos.'
          : normalized.message,
      );
    }
  }
  async function update(row: Row) {
    try {
      await followupsApi.update(row.followup.id, {
        version: row.followup.version,
        note: nullable(editNote),
      });
      setEditing(undefined);
      await load();
    } catch (cause) {
      setMessage(normalizeApiError(cause).message);
      if (normalizeApiError(cause).code === 'CONCURRENT_MODIFICATION') await load();
    }
  }
  function remove(row: Row) {
    Alert.alert(
      'Remover acompanhamento?',
      'A ocorrencia nao sera cancelada; apenas este acompanhamento sera removido.',
      [
        { text: 'Voltar', style: 'cancel' },
        {
          text: 'Remover',
          style: 'destructive',
          onPress: () =>
            void (async () => {
              try {
                await followupsApi.remove(row.followup.id);
                await load();
              } catch (cause) {
                setMessage(normalizeApiError(cause).message);
              }
            })(),
        },
      ],
    );
  }
  return (
    <Screen>
      <View>
        <Text style={styles.eyebrow}>INTEGRACAO .NET + JAVA</Text>
        <Text style={styles.title}>Meus acompanhamentos</Text>
        <Text style={styles.subtitle}>
          Notas persistidas no .NET; dados atuais consultados diretamente no Java.
        </Text>
      </View>
      <View style={styles.create}>
        <Text style={styles.heading}>Adicionar acompanhamento</Text>
        <TextField
          label="ID da ocorrencia (UUID)"
          value={occurrenceId}
          onChangeText={setOccurrenceId}
          autoCapitalize="none"
        />
        <TextField
          label="Nota opcional"
          value={newNote}
          onChangeText={setNewNote}
          maxLength={500}
        />
        <Button label="Acompanhar" onPress={() => void create()} />
      </View>
      {message ? (
        <Text accessibilityRole="alert" style={styles.error}>
          {message}
        </Text>
      ) : null}
      {loading ? (
        <LoadingState />
      ) : error ? (
        <ErrorState error={error} onRetry={() => void load()} />
      ) : !rows.length ? (
        <EmptyState
          title="Nenhum acompanhamento"
          message="Adicione uma ocorrencia pelo ID ou use o botao na tela de detalhes."
        />
      ) : (
        <View style={styles.list}>
          {rows.map((row) => (
            <View key={row.followup.id} style={styles.card}>
              {row.occurrence ? (
                <>
                  <Text style={styles.cardTitle}>{row.occurrence.title}</Text>
                  <Text style={styles.meta}>
                    {row.occurrence.category.name} · {row.occurrence.status}
                  </Text>
                  <Button
                    label="Abrir ocorrencia"
                    variant="ghost"
                    onPress={() =>
                      router.push({
                        pathname: '/(app)/occurrences/[id]',
                        params: { id: row.followup.occurrenceId },
                      })
                    }
                  />
                </>
              ) : (
                <>
                  <Text style={styles.cardTitle}>Ocorrencia indisponivel</Text>
                  <Text style={styles.error}>{row.unavailable}</Text>
                  <Text style={styles.meta}>{row.followup.occurrenceId}</Text>
                </>
              )}
              {editing === row.followup.id ? (
                <>
                  <TextField
                    label="Nota"
                    value={editNote}
                    onChangeText={setEditNote}
                    maxLength={500}
                  />
                  <Button label="Salvar nota" onPress={() => void update(row)} />
                  <Button
                    label="Cancelar edicao"
                    variant="ghost"
                    onPress={() => setEditing(undefined)}
                  />
                </>
              ) : (
                <>
                  <Text style={styles.note}>{row.followup.note || 'Sem nota pessoal.'}</Text>
                  <Text style={styles.meta}>
                    Atualizado em {formatDate(row.followup.updatedAt)} · v{row.followup.version}
                  </Text>
                  <Button
                    label="Editar nota"
                    variant="secondary"
                    onPress={() => {
                      setEditing(row.followup.id);
                      setEditNote(row.followup.note ?? '');
                    }}
                  />
                  <Button label="Remover" variant="danger" onPress={() => remove(row)} />
                </>
              )}
            </View>
          ))}
        </View>
      )}
    </Screen>
  );
}
const styles = StyleSheet.create({
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  subtitle: { ...typography.body, color: colors.textMuted },
  heading: { ...typography.heading, color: colors.text },
  create: {
    padding: spacing.lg,
    gap: spacing.md,
    borderRadius: radii.lg,
    backgroundColor: colors.primarySoft,
  },
  list: { gap: spacing.md },
  card: {
    padding: spacing.lg,
    gap: spacing.sm,
    borderRadius: radii.lg,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardTitle: { ...typography.heading, color: colors.text },
  meta: { ...typography.caption, color: colors.textMuted },
  note: { ...typography.body, color: colors.text },
  error: { ...typography.body, color: colors.danger },
});
