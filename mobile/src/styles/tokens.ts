export const colors = {
  primary: '#145DA0',
  primaryDark: '#0E4478',
  primarySoft: '#E7F1FA',
  success: '#16845B',
  successSoft: '#E8F5EF',
  warning: '#B45309',
  warningSoft: '#FFF3E0',
  danger: '#B91C1C',
  dangerSoft: '#FDECEC',
  info: '#0369A1',
  background: '#F5F7FA',
  surface: '#FFFFFF',
  text: '#0F172A',
  textMuted: '#475569',
  border: '#DCE3EB',
  disabled: '#94A3B8',
  overlay: 'rgba(15, 23, 42, 0.55)',
} as const;
export const spacing = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32 } as const;
export const radii = { sm: 8, md: 12, lg: 18, pill: 999 } as const;
export const typography = {
  display: { fontSize: 28, lineHeight: 34, fontWeight: '800' as const },
  title: { fontSize: 22, lineHeight: 28, fontWeight: '700' as const },
  heading: { fontSize: 18, lineHeight: 24, fontWeight: '700' as const },
  body: { fontSize: 15, lineHeight: 22, fontWeight: '400' as const },
  label: { fontSize: 14, lineHeight: 20, fontWeight: '600' as const },
  caption: { fontSize: 13, lineHeight: 18, fontWeight: '400' as const },
} as const;
