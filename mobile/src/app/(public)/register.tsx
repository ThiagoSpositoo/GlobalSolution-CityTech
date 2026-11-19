import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { fieldErrorsMap, normalizeApiError } from '@/api/errors';
import { useAuth } from '@/auth/AuthContext';
import { Button } from '@/components/Button';
import { Screen } from '@/components/Screen';
import { TextField } from '@/components/TextField';
import { colors, spacing, typography } from '@/styles/tokens';
import { validateEmail, validatePassword } from '@/utils/validators';

export default function RegisterScreen() {
  const { register } = useAuth();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [message, setMessage] = useState<string>();
  async function submit() {
    const next: Record<string, string> = {};
    if (name.trim().length < 2 || name.trim().length > 120)
      next.name = 'Use entre 2 e 120 caracteres.';
    const emailError = validateEmail(email.trim());
    if (emailError) next.email = emailError;
    const passwordError = validatePassword(password);
    if (passwordError) next.password = passwordError;
    if (confirmation !== password) next.confirmation = 'As senhas nao conferem.';
    setErrors(next);
    if (Object.keys(next).length) return;
    setSubmitting(true);
    setMessage(undefined);
    try {
      await register({ name: name.trim(), email: email.trim(), password });
    } catch (cause) {
      setErrors(fieldErrorsMap(cause));
      setMessage(normalizeApiError(cause).message);
    } finally {
      setSubmitting(false);
    }
  }
  return (
    <Screen>
      <View style={styles.header}>
        <Text style={styles.eyebrow}>CADASTRO CIDADAO</Text>
        <Text style={styles.title}>Crie sua conta</Text>
        <Text style={styles.subtitle}>O cadastro publico cria exclusivamente o papel CIDADAO.</Text>
      </View>
      <View style={styles.form}>
        <TextField
          label="Nome completo"
          value={name}
          onChangeText={setName}
          error={errors.name}
          autoComplete="name"
        />
        <TextField
          label="E-mail"
          value={email}
          onChangeText={setEmail}
          error={errors.email}
          autoCapitalize="none"
          keyboardType="email-address"
        />
        <TextField
          label="Senha"
          value={password}
          onChangeText={setPassword}
          error={errors.password}
          secureTextEntry
        />
        <TextField
          label="Confirmar senha"
          value={confirmation}
          onChangeText={setConfirmation}
          error={errors.confirmation}
          secureTextEntry
        />
        {message ? (
          <Text accessibilityRole="alert" style={styles.error}>
            {message}
          </Text>
        ) : null}
        <Button label="Cadastrar e entrar" loading={submitting} onPress={() => void submit()} />
        <Button
          label="Ja tenho conta"
          variant="ghost"
          onPress={() => router.replace('/(public)/login')}
        />
      </View>
    </Screen>
  );
}
const styles = StyleSheet.create({
  header: { marginTop: spacing.lg, gap: spacing.sm },
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  subtitle: { ...typography.body, color: colors.textMuted },
  form: { gap: spacing.lg },
  error: { ...typography.body, color: colors.danger },
});
