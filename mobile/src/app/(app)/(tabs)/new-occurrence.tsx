import { router } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';
import { occurrencesApi } from '@/api/occurrencesApi';
import { Screen } from '@/components/Screen';
import { OccurrenceForm } from '@/features/OccurrenceForm';
import { colors, spacing, typography } from '@/styles/tokens';

export default function NewOccurrenceScreen() {
  return (
    <Screen>
      <View style={styles.header}>
        <Text style={styles.eyebrow}>REGISTRO CIDADAO</Text>
        <Text style={styles.title}>Nova ocorrencia</Text>
        <Text style={styles.subtitle}>
          Descreva o problema com dados ficticios e informe o endereco completo.
        </Text>
      </View>
      <OccurrenceForm
        submitLabel="Registrar ocorrencia"
        onSubmit={async (input) => {
          const created = await occurrencesApi.create(input);
          router.replace({ pathname: '/(app)/occurrences/[id]', params: { id: created.id } });
        }}
      />
    </Screen>
  );
}
const styles = StyleSheet.create({
  header: { gap: spacing.sm },
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  subtitle: { ...typography.body, color: colors.textMuted },
});
