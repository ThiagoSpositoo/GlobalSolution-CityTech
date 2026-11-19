import { Pressable, ScrollView, StyleSheet, Text } from 'react-native';
import { colors, radii, spacing, typography } from '@/styles/tokens';

export interface Choice<T extends string> {
  value: T;
  label: string;
}
export function ChoiceChips<T extends string>({
  choices,
  value,
  onChange,
  includeAll,
}: {
  choices: Choice<T>[];
  value?: T;
  onChange(value?: T): void;
  includeAll?: boolean;
}) {
  const items: Choice<T | ''>[] = includeAll
    ? [{ value: '', label: 'Todos' }, ...choices]
    : choices;
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.row}
    >
      {items.map((item) => {
        const selected = (value ?? '') === item.value;
        return (
          <Pressable
            key={item.value}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(item.value ? (item.value as T) : undefined)}
            style={[styles.chip, selected && styles.selected]}
          >
            <Text style={[styles.label, selected && styles.selectedLabel]}>{item.label}</Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}
const styles = StyleSheet.create({
  row: { gap: spacing.sm },
  chip: {
    minHeight: 40,
    justifyContent: 'center',
    paddingHorizontal: spacing.md,
    borderRadius: radii.pill,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  selected: { backgroundColor: colors.primary, borderColor: colors.primary },
  label: { ...typography.label, color: colors.textMuted },
  selectedLabel: { color: colors.surface },
});
