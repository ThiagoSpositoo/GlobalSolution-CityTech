import { router, useFocusEffect, useLocalSearchParams } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { Alert, StyleSheet, Text, View } from 'react-native';
import { normalizeApiError } from '@/api/errors';
import { followupsApi } from '@/api/followupsApi';
import { occurrencesApi } from '@/api/occurrencesApi';
import type { FollowUp, HistoryItem, Occurrence, OccurrenceStatus, Priority } from '@/api/types';
import { useAuth } from '@/auth/AuthContext';
import { PriorityBadge, StatusBadge } from '@/components/Badge';
import { Button } from '@/components/Button';
import { ChoiceChips } from '@/components/ChoiceChips';
import { Screen } from '@/components/Screen';
import { ErrorState, LoadingState } from '@/components/StateFeedback';
import { TextField } from '@/components/TextField';
import { colors, radii, spacing, typography } from '@/styles/tokens';
import { formatDate, nullable } from '@/utils/formatters';
import { createIdempotencyKey } from '@/utils/idempotency';

const priorities = ['BAIXA', 'MEDIA', 'ALTA', 'CRITICA'].map((value) => ({
  value: value as Priority,
  label: value,
}));
export default function OccurrenceDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { user } = useAuth();
  const [item, setItem] = useState<Occurrence>();
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [followup, setFollowup] = useState<FollowUp>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<unknown>();
  const [acting, setActing] = useState(false);
  const [note, setNote] = useState('');
  const [reason, setReason] = useState('');
  const [triagePriority, setTriagePriority] = useState<Priority>('MEDIA');
  const [message, setMessage] = useState<string>();
  const load = useCallback(async () => {
    if (!id) return;
    setLoading(true);
    setError(undefined);
    try {
      const [occurrence, historyPage, followupPage] = await Promise.all([
        occurrencesApi.get(id),
        occurrencesApi.history(id),
        followupsApi.list(0, 100),
      ]);
      setItem(occurrence);
      setHistory(historyPage.items);
      setFollowup(followupPage.items.find((entry) => entry.occurrenceId === id));
      setTriagePriority(occurrence.priority);
    } catch (cause) {
      setError(cause);
    } finally {
      setLoading(false);
    }
  }, [id]);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  const pollId = item?.id;
  const pollStatus = item?.aiSuggestion?.status;
  useEffect(() => {
    if (!pollId || pollStatus !== 'PENDENTE') return;
    let count = 0;
    const timer = setInterval(() => {
      count += 1;
      if (count >= 10) clearInterval(timer);
      void occurrencesApi
        .get(pollId)
        .then((fresh) => {
          setItem(fresh);
          if (fresh.aiSuggestion?.status !== 'PENDENTE') clearInterval(timer);
        })
        .catch(() => clearInterval(timer));
    }, 3000);
    return () => clearInterval(timer);
  }, [pollId, pollStatus]);
  async function action(operation: () => Promise<unknown>, success: string) {
    setActing(true);
    setMessage(undefined);
    try {
      await operation();
      setMessage(success);
      setNote('');
      setReason('');
      await load();
    } catch (cause) {
      const normalized = normalizeApiError(cause);
      setMessage(normalized.message);
      if (normalized.code === 'CONCURRENT_MODIFICATION' || normalized.code === 'INVALID_TRANSITION')
        await load();
    } finally {
      setActing(false);
    }
  }
  function confirmCancel() {
    if (!item || !reason.trim()) {
      setMessage('Informe o motivo do cancelamento.');
      return;
    }
    Alert.alert('Cancelar ocorrencia?', 'O cancelamento e logico e permanecera no historico.', [
      { text: 'Voltar', style: 'cancel' },
      {
        text: 'Cancelar',
        style: 'destructive',
        onPress: () =>
          void action(
            () => occurrencesApi.cancel(item.id, item.version, reason.trim()),
            'Ocorrencia cancelada.',
          ),
      },
    ]);
  }
  if (loading)
    return (
      <Screen>
        <LoadingState label="Carregando detalhe e historico..." />
      </Screen>
    );
  if (error || !item)
    return (
      <Screen>
        <ErrorState
          error={error ?? new Error('Ocorrencia nao encontrada.')}
          onRetry={() => void load()}
        />
      </Screen>
    );
  const isOwner = user?.id === item.citizenId;
  return (
    <Screen>
      <View style={styles.header}>
        <View style={styles.badges}>
          <StatusBadge status={item.status} />
          <PriorityBadge priority={item.priority} />
        </View>
        <Text style={styles.title}>{item.title}</Text>
        <Text style={styles.meta}>
          {item.category.name} · versao {item.version}
        </Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.heading}>Descricao</Text>
        <Text style={styles.body}>{item.description}</Text>
        <Text style={styles.heading}>Endereco informado</Text>
        <Text style={styles.body}>
          {item.address.street}, {item.address.number}
          {item.address.complement ? ` · ${item.address.complement}` : ''}
          {'\n'}
          {item.address.district} · {item.address.city}/{item.address.state}
          {item.address.postalCode ? ` · ${item.address.postalCode}` : ''}
        </Text>
        <Text style={styles.meta}>Criada em {formatDate(item.createdAt)}</Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.heading}>Acompanhamento .NET</Text>
        {followup ? (
          <>
            <Text style={styles.body}>
              {followup.note || 'Voce acompanha esta ocorrencia sem nota.'}
            </Text>
            <Button
              label="Ver meus acompanhamentos"
              variant="secondary"
              onPress={() => router.push('/(app)/(tabs)/followups')}
            />
          </>
        ) : (
          <>
            <TextField label="Nota opcional" value={note} onChangeText={setNote} maxLength={500} />
            <Button
              label="Acompanhar ocorrencia"
              loading={acting}
              onPress={() =>
                void action(
                  () =>
                    followupsApi.create(
                      { occurrenceId: item.id, note: nullable(note) },
                      createIdempotencyKey(),
                    ),
                  'Ocorrencia adicionada aos acompanhamentos.',
                )
              }
            />
          </>
        )}
      </View>
      <View style={styles.card}>
        <Text style={styles.heading}>Classificacao assistida por IA</Text>
        {!item.aiSuggestion ? (
          <Text style={styles.body}>Sugestao ainda nao criada. Atualize em alguns instantes.</Text>
        ) : item.aiSuggestion.status === 'PENDENTE' ? (
          <Text style={styles.body}>
            Classificacao em processamento. A tela atualiza por ate 30 segundos.
          </Text>
        ) : item.aiSuggestion.status === 'FALHOU' ? (
          <Text style={styles.error}>
            Classificacao indisponivel ({item.aiSuggestion.errorCode ?? 'falha nao identificada'}).
            A triagem manual continua disponivel.
          </Text>
        ) : (
          <>
            <Text style={styles.body}>Status: {item.aiSuggestion.status}</Text>
            {item.aiSuggestion.suggestedCategory ? (
              <Text style={styles.body}>
                Categoria sugerida: {item.aiSuggestion.suggestedCategory.name}
              </Text>
            ) : null}
            {item.aiSuggestion.suggestedPriority ? (
              <Text style={styles.body}>
                Prioridade sugerida: {item.aiSuggestion.suggestedPriority}
              </Text>
            ) : null}
            {item.aiSuggestion.summary ? (
              <Text style={styles.body}>{item.aiSuggestion.summary}</Text>
            ) : null}
            {item.aiSuggestion.justification ? (
              <Text style={styles.meta}>{item.aiSuggestion.justification}</Text>
            ) : null}
            {item.aiSuggestion.sources?.map((source) => (
              <Text key={source} style={styles.source}>
                Fonte: {source}
              </Text>
            ))}
            {item.aiSuggestion.status === 'PRONTA' ? (
              <View style={styles.actions}>
                <Button
                  label="Aceitar sugestao"
                  loading={acting}
                  onPress={() =>
                    void action(
                      () =>
                        occurrencesApi.review(item.id, {
                          version: item.version,
                          decision: 'ACEITAR',
                          note: nullable(note) ?? undefined,
                        }),
                      'Sugestao aceita.',
                    )
                  }
                />
                <Button
                  label="Rejeitar sugestao"
                  variant="secondary"
                  loading={acting}
                  onPress={() =>
                    void action(
                      () =>
                        occurrencesApi.review(item.id, {
                          version: item.version,
                          decision: 'REJEITAR',
                          note: nullable(note) ?? undefined,
                        }),
                      'Sugestao rejeitada.',
                    )
                  }
                />
              </View>
            ) : null}
          </>
        )}
      </View>
      {isOwner && item.status === 'ABERTA' ? (
        <View style={styles.card}>
          <Text style={styles.heading}>Acoes do cidadao</Text>
          <Button
            label="Editar dados"
            variant="secondary"
            onPress={() =>
              router.push({ pathname: '/(app)/occurrences/[id]/edit', params: { id: item.id } })
            }
          />
          <TextField
            label="Motivo para cancelar"
            value={reason}
            onChangeText={setReason}
            maxLength={255}
          />
          <Button
            label="Cancelar ocorrencia"
            variant="danger"
            loading={acting}
            onPress={confirmCancel}
          />
        </View>
      ) : null}
      {isOwner && item.status === 'RESOLVIDA' ? (
        <View style={styles.card}>
          <Text style={styles.heading}>Confirmar atendimento</Text>
          <TextField
            label="Nota ou justificativa"
            value={note}
            onChangeText={setNote}
            maxLength={500}
          />
          <Button
            label="Confirmar e encerrar"
            onPress={() =>
              void action(
                () =>
                  occurrencesApi.transition(item.id, {
                    version: item.version,
                    status: 'ENCERRADA',
                    note: nullable(note) ?? undefined,
                  }),
                'Ocorrencia encerrada.',
              )
            }
          />
          <Button
            label="Reabrir atendimento"
            variant="secondary"
            onPress={() =>
              void action(
                () =>
                  occurrencesApi.transition(item.id, {
                    version: item.version,
                    status: 'EM_ANDAMENTO',
                    note: nullable(note) ?? undefined,
                  }),
                'Ocorrencia reaberta.',
              )
            }
          />
        </View>
      ) : null}
      {user?.role === 'GESTOR' && !['ENCERRADA', 'CANCELADA'].includes(item.status) ? (
        <View style={styles.card}>
          <Text style={styles.heading}>Triagem do gestor</Text>
          <ChoiceChips
            choices={priorities}
            value={triagePriority}
            onChange={(value) => value && setTriagePriority(value)}
          />
          <TextField label="Nota da triagem" value={note} onChangeText={setNote} maxLength={500} />
          <Button
            label="Aplicar triagem"
            loading={acting}
            onPress={() =>
              void action(
                () =>
                  occurrencesApi.triage(item.id, {
                    version: item.version,
                    priority: triagePriority,
                    note: nullable(note) ?? undefined,
                  }),
                'Triagem registrada.',
              )
            }
          />
          {nextStatus(item.status) ? (
            <Button
              label={`Avancar para ${nextStatus(item.status)}`}
              variant="secondary"
              onPress={() =>
                void action(
                  () =>
                    occurrencesApi.transition(item.id, {
                      version: item.version,
                      status: nextStatus(item.status)!,
                      note: nullable(note) ?? undefined,
                    }),
                  'Status atualizado.',
                )
              }
            />
          ) : null}
        </View>
      ) : null}
      {message ? (
        <Text
          accessibilityRole="alert"
          style={
            message.includes('adicionada') ||
            message.includes('registrada') ||
            message.includes('atualizado')
              ? styles.success
              : styles.error
          }
        >
          {message}
        </Text>
      ) : null}
      <View style={styles.card}>
        <Text style={styles.heading}>Historico</Text>
        {history.map((entry) => (
          <View key={entry.id} style={styles.history}>
            <Text style={styles.historyTitle}>
              {entry.action.replace('_', ' ')} · {entry.actorRole}
            </Text>
            <Text style={styles.meta}>
              {entry.fromStatus ?? 'INICIO'} → {entry.toStatus ?? 'SEM ALTERACAO'} ·{' '}
              {formatDate(entry.createdAt)}
            </Text>
            {entry.note ? <Text style={styles.body}>{entry.note}</Text> : null}
          </View>
        ))}
      </View>
    </Screen>
  );
}
function nextStatus(status: OccurrenceStatus): OccurrenceStatus | undefined {
  const map: Partial<Record<OccurrenceStatus, OccurrenceStatus>> = {
    ABERTA: 'EM_TRIAGEM',
    EM_TRIAGEM: 'EM_ANDAMENTO',
    EM_ANDAMENTO: 'RESOLVIDA',
    RESOLVIDA: 'ENCERRADA',
  };
  return map[status];
}
const styles = StyleSheet.create({
  header: { gap: spacing.sm },
  badges: { flexDirection: 'row', gap: spacing.sm },
  title: { ...typography.display, color: colors.text },
  heading: { ...typography.heading, color: colors.primaryDark },
  body: { ...typography.body, color: colors.text },
  meta: { ...typography.caption, color: colors.textMuted },
  card: {
    padding: spacing.lg,
    gap: spacing.md,
    borderRadius: radii.lg,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  actions: { gap: spacing.sm },
  source: { ...typography.caption, color: colors.info },
  error: { ...typography.body, color: colors.danger },
  success: { ...typography.body, color: colors.success },
  history: {
    borderLeftWidth: 3,
    borderLeftColor: colors.primary,
    paddingLeft: spacing.md,
    gap: spacing.xs,
  },
  historyTitle: { ...typography.label, color: colors.text },
});
