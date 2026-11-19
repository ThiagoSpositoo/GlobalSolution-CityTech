import Constants from 'expo-constants';
import { StyleSheet, Text, View } from 'react-native';
import { apiHosts } from '@/api/config';
import { Screen } from '@/components/Screen';
import { colors, radii, spacing, typography } from '@/styles/tokens';

export default function AboutScreen() {
  const commitHash = String(Constants.expoConfig?.extra?.commitHash ?? 'development');
  return (
    <Screen>
      <View style={styles.hero}>
        <Text style={styles.eyebrow}>CITYTECH</Text>
        <Text style={styles.title}>Tecnologia que transforma cidades.</Text>
        <Text style={styles.body}>
          Aplicativo demonstrativo de zeladoria urbana colaborativa, desenvolvido para a Global
          Solution FIAP 2026/2.
        </Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.heading}>Versao publicada</Text>
        <Row label="Aplicativo" value={Constants.expoConfig?.version ?? '1.0.0'} />
        <Row label="Commit" value={commitHash} emphasis />
        <Text style={styles.note}>
          {commitHash === 'development'
            ? 'Build local de desenvolvimento. O APK final deve injetar o hash do commit publicado.'
            : 'Este hash deve corresponder exatamente ao fonte e ao APK distribuido.'}
        </Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.heading}>Servicos configurados</Text>
        <Row label="Identidade .NET" value={apiHosts.dotnet} />
        <Row label="Ocorrencias Java" value={apiHosts.java} />
        <Text style={styles.note}>
          Somente hosts publicos sao exibidos. Nenhuma credencial ou token e apresentado.
        </Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.heading}>Compromisso publico</Text>
        <Text style={styles.body}>
          Contribuicao proposta a ODS 11 por meio de participacao cidada e informacao sobre
          problemas urbanos. Os dados de demonstracao sao ficticios e o projeto nao possui vinculo
          oficial com prefeituras.
        </Text>
      </View>
    </Screen>
  );
}
function Row({ label, value, emphasis }: { label: string; value: string; emphasis?: boolean }) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Text selectable style={[styles.value, emphasis && styles.commit]}>
        {value}
      </Text>
    </View>
  );
}
const styles = StyleSheet.create({
  hero: { gap: spacing.sm, marginTop: spacing.sm },
  eyebrow: { ...typography.caption, color: colors.success, fontWeight: '800' },
  title: { ...typography.display, color: colors.text },
  body: { ...typography.body, color: colors.textMuted },
  card: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radii.lg,
    padding: spacing.lg,
    gap: spacing.md,
  },
  heading: { ...typography.heading, color: colors.primaryDark },
  row: { flexDirection: 'row', justifyContent: 'space-between', gap: spacing.md },
  label: { ...typography.label, color: colors.textMuted },
  value: { ...typography.body, color: colors.text, flex: 1, textAlign: 'right' },
  commit: { fontFamily: 'monospace', color: colors.primary },
  note: { ...typography.caption, color: colors.textMuted },
});
