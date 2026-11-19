import { ActivityIndicator, Pressable, StyleSheet, Text, type PressableProps } from 'react-native';
import { colors, radii, spacing, typography } from '@/styles/tokens';

interface Props extends PressableProps {
  label: string;
  loading?: boolean;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
}
export function Button({ label, loading, variant = 'primary', disabled, style, ...props }: Props) {
  const blocked = disabled || loading;
  return (
    <Pressable
      accessibilityRole="button"
      disabled={blocked}
      style={(state) => [
        styles.base,
        styles[variant],
        blocked && styles.disabled,
        state.pressed && !blocked && styles.pressed,
        typeof style === 'function' ? style(state) : style,
      ]}
      {...props}
    >
      {loading ? (
        <ActivityIndicator
          color={variant === 'primary' || variant === 'danger' ? colors.surface : colors.primary}
        />
      ) : (
        <Text
          style={[
            styles.label,
            (variant === 'primary' || variant === 'danger') && styles.lightLabel,
          ]}
        >
          {label}
        </Text>
      )}
    </Pressable>
  );
}
const styles = StyleSheet.create({
  base: {
    minHeight: 48,
    borderRadius: radii.md,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    borderWidth: 1,
  },
  primary: { backgroundColor: colors.primary, borderColor: colors.primary },
  secondary: { backgroundColor: colors.primarySoft, borderColor: colors.primary },
  danger: { backgroundColor: colors.danger, borderColor: colors.danger },
  ghost: { backgroundColor: 'transparent', borderColor: 'transparent' },
  label: { ...typography.label, color: colors.primary },
  lightLabel: { color: colors.surface },
  disabled: { opacity: 0.55 },
  pressed: { opacity: 0.82 },
});
