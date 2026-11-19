import { StyleSheet, Text, View } from 'react-native';
import type { OccurrenceStatus, Priority } from '@/api/types';
import { colors, radii, spacing, typography } from '@/styles/tokens';

const statusLabels: Record<OccurrenceStatus, string> = {
  ABERTA: 'Aberta',
  EM_TRIAGEM: 'Em triagem',
  EM_ANDAMENTO: 'Em andamento',
  RESOLVIDA: 'Resolvida',
  ENCERRADA: 'Encerrada',
  CANCELADA: 'Cancelada',
};
const priorityLabels: Record<Priority, string> = {
  BAIXA: 'Baixa',
  MEDIA: 'Media',
  ALTA: 'Alta',
  CRITICA: 'Critica',
};
export function StatusBadge({ status }: { status: OccurrenceStatus }) {
  return (
    <View
      style={[
        styles.badge,
        status === 'CANCELADA'
          ? styles.danger
          : status === 'RESOLVIDA' || status === 'ENCERRADA'
            ? styles.success
            : styles.info,
      ]}
    >
      <Text style={styles.text}>● {statusLabels[status]}</Text>
    </View>
  );
}
export function PriorityBadge({ priority }: { priority: Priority }) {
  return (
    <View
      style={[
        styles.badge,
        priority === 'CRITICA'
          ? styles.danger
          : priority === 'ALTA'
            ? styles.warning
            : styles.neutral,
      ]}
    >
      <Text style={styles.text}>◆ {priorityLabels[priority]}</Text>
    </View>
  );
}
const styles = StyleSheet.create({
  badge: {
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: radii.pill,
  },
  text: { ...typography.caption, fontWeight: '700', color: colors.text },
  info: { backgroundColor: colors.primarySoft },
  success: { backgroundColor: colors.successSoft },
  warning: { backgroundColor: colors.warningSoft },
  danger: { backgroundColor: colors.dangerSoft },
  neutral: { backgroundColor: colors.background },
});
