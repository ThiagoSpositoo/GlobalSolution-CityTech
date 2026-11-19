import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';
import { Button } from '@/components/Button';
import { Screen } from '@/components/Screen';
import { colors, radii, spacing, typography } from '@/styles/tokens';

export default function WelcomeScreen() {
  return (
    <Screen contentContainerStyle={styles.content}>
      <View style={styles.mark}>
        <MaterialCommunityIcons name="city-variant-outline" size={50} color={colors.surface} />
      </View>
      <View style={styles.hero}>
        <Text style={styles.eyebrow}>ZELADORIA URBANA COLABORATIVA</Text>
        <Text style={styles.title}>Uma cidade melhor começa com quem vive nela.</Text>
        <Text style={styles.body}>
          Registre problemas urbanos, acompanhe o atendimento e participe da transformacao dos
          espacos publicos.
        </Text>
      </View>
      <View style={styles.actions}>
        <Button label="Entrar" onPress={() => router.push('/(public)/login')} />
        <Button
          label="Criar conta cidada"
          variant="secondary"
          onPress={() => router.push('/(public)/register')}
        />
        <Button label="Sobre o CityTech" variant="ghost" onPress={() => router.push('/about')} />
      </View>
      <Text style={styles.note}>Projeto academico demonstrativo · FIAP GS 2026/2 · ODS 11</Text>
    </Screen>
  );
}
const styles = StyleSheet.create({
  content: { justifyContent: 'center' },
  mark: {
    width: 82,
    height: 82,
    borderRadius: radii.lg,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  hero: { gap: spacing.md },
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800', letterSpacing: 1.2 },
  title: { ...typography.display, color: colors.text },
  body: { ...typography.body, color: colors.textMuted },
  actions: { gap: spacing.md },
  note: { ...typography.caption, color: colors.textMuted, textAlign: 'center' },
});
