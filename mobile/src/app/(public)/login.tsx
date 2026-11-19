import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { normalizeApiError } from '@/api/errors';
import { useAuth } from '@/auth/AuthContext';
import { Button } from '@/components/Button';
import { Screen } from '@/components/Screen';
import { TextField } from '@/components/TextField';
import { colors, spacing, typography } from '@/styles/tokens';
import { validateEmail } from '@/utils/validators';

export default function LoginScreen() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string>();
  async function submit() {
    const emailError = validateEmail(email.trim());
    if (emailError || !password) {
      setError(emailError ?? 'Informe sua senha.');
      return;
    }
    setSubmitting(true);
    setError(undefined);
    try {
      await login({ email: email.trim(), password });
    } catch (cause) {
      setError(normalizeApiError(cause).message);
    } finally {
      setSubmitting(false);
    }
  }
  return (
    <Screen>
      <View style={styles.header}>
        <Text style={styles.eyebrow}>CITYTECH</Text>
        <Text style={styles.title}>Bem-vindo de volta</Text>
        <Text style={styles.subtitle}>Entre com sua conta emitida pela identidade CityTech.</Text>
      </View>
      <View style={styles.form}>
        <TextField
          label="E-mail"
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          autoComplete="email"
          keyboardType="email-address"
        />
        <TextField
          label="Senha"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          autoComplete="password"
          onSubmitEditing={() => void submit()}
        />
        {error ? (
          <Text accessibilityRole="alert" style={styles.error}>
            {error}
          </Text>
        ) : null}
        <Button label="Entrar" loading={submitting} onPress={() => void submit()} />
        <Button
          label="Ainda nao tenho conta"
          variant="ghost"
          onPress={() => router.replace('/(public)/register')}
        />
      </View>
    </Screen>
  );
}
const styles = StyleSheet.create({
  header: { marginTop: spacing.xxl, gap: spacing.sm },
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  subtitle: { ...typography.body, color: colors.textMuted },
  form: { gap: spacing.lg },
  error: { ...typography.body, color: colors.danger },
});
