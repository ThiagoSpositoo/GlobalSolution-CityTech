import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { OccurrenceSummary } from '@/api/types';
import { colors, radii, spacing, typography } from '@/styles/tokens';
import { formatDate } from '@/utils/formatters';
import { PriorityBadge, StatusBadge } from './Badge';

export function OccurrenceCard({
  item,
  onPress,
}: {
  item: OccurrenceSummary;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && { opacity: 0.8 }]}
    >
      <View style={styles.row}>
        <Text style={styles.title} numberOfLines={2}>
          {item.title}
        </Text>
        <Text style={styles.date}>{formatDate(item.createdAt)}</Text>
      </View>
      <Text style={styles.meta}>
        {item.category.name} · {item.address.district}, {item.address.city}/{item.address.state}
      </Text>
      <View style={styles.badges}>
        <StatusBadge status={item.status} />
        <PriorityBadge priority={item.priority} />
      </View>
    </Pressable>
  );
}
const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radii.lg,
    padding: spacing.lg,
    gap: spacing.sm,
  },
  row: { flexDirection: 'row', justifyContent: 'space-between', gap: spacing.sm },
  title: { ...typography.heading, color: colors.text, flex: 1 },
  date: { ...typography.caption, color: colors.textMuted },
  meta: { ...typography.body, color: colors.textMuted },
  badges: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
});
