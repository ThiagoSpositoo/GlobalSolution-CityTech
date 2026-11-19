import { MaterialCommunityIcons } from '@expo/vector-icons';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { AppError, normalizeApiError } from '@/api/errors';
import { colors, spacing, typography } from '@/styles/tokens';
import { Button } from './Button';

export function LoadingState({ label = 'Carregando...' }: { label?: string }) {
  return (
    <View style={styles.box}>
      <ActivityIndicator size="large" color={colors.primary} />
      <Text style={styles.text}>{label}</Text>
    </View>
  );
}
export function EmptyState({
  title,
  message,
  action,
}: {
  title: string;
  message: string;
  action?: React.ReactNode;
}) {
  return (
    <View style={styles.box}>
      <MaterialCommunityIcons name="inbox-outline" size={42} color={colors.textMuted} />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.text}>{message}</Text>
      {action}
    </View>
  );
}
export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  const normalized = error instanceof AppError ? error : normalizeApiError(error);
  return (
    <View style={styles.box}>
      <MaterialCommunityIcons name="alert-circle-outline" size={42} color={colors.danger} />
      <Text style={styles.title}>Nao foi possivel carregar</Text>
      <Text style={styles.text}>{normalized.message}</Text>
      {__DEV__ && normalized.traceId ? (
        <Text style={styles.trace}>Trace: {normalized.traceId}</Text>
      ) : null}
      {onRetry ? <Button label="Tentar novamente" variant="secondary" onPress={onRetry} /> : null}
    </View>
  );
}
const styles = StyleSheet.create({
  box: {
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    paddingVertical: spacing.xxl,
  },
  title: { ...typography.heading, color: colors.text, textAlign: 'center' },
  text: { ...typography.body, color: colors.textMuted, textAlign: 'center' },
  trace: { ...typography.caption, color: colors.textMuted },
});
