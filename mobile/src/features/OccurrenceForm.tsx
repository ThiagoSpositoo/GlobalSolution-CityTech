import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { categoriesApi } from '@/api/occurrencesApi';
import type { Category, OccurrenceInput, Priority } from '@/api/types';
import { fieldErrorsMap, normalizeApiError } from '@/api/errors';
import { Button } from '@/components/Button';
import { ChoiceChips } from '@/components/ChoiceChips';
import { ErrorState, LoadingState } from '@/components/StateFeedback';
import { TextField } from '@/components/TextField';
import { colors, spacing, typography } from '@/styles/tokens';
import { maskPostalCode, nullable } from '@/utils/formatters';
import { validateOccurrence } from '@/utils/validators';

const priorities = [
  { value: 'BAIXA', label: 'Baixa' },
  { value: 'MEDIA', label: 'Media' },
  { value: 'ALTA', label: 'Alta' },
  { value: 'CRITICA', label: 'Critica' },
] as { value: Priority; label: string }[];
export function OccurrenceForm({
  initial,
  submitLabel,
  onSubmit,
}: {
  initial?: OccurrenceInput;
  submitLabel: string;
  onSubmit(input: OccurrenceInput): Promise<void>;
}) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loadingCategories, setLoadingCategories] = useState(true);
  const [title, setTitle] = useState(initial?.title ?? '');
  const [description, setDescription] = useState(initial?.description ?? '');
  const [categoryId, setCategoryId] = useState(initial?.categoryId);
  const [priority, setPriority] = useState<Priority>(initial?.priority ?? 'MEDIA');
  const [street, setStreet] = useState(initial?.address.street ?? '');
  const [number, setNumber] = useState(initial?.address.number ?? '');
  const [complement, setComplement] = useState(initial?.address.complement ?? '');
  const [district, setDistrict] = useState(initial?.address.district ?? '');
  const [city, setCity] = useState(initial?.address.city ?? '');
  const [state, setState] = useState(initial?.address.state ?? 'SP');
  const [postalCode, setPostalCode] = useState(initial?.address.postalCode ?? '');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [message, setMessage] = useState<string>();
  const [submitting, setSubmitting] = useState(false);
  async function loadCategories() {
    setLoadingCategories(true);
    try {
      setCategories(await categoriesApi.list());
    } catch (cause) {
      setErrors((current) => ({ ...current, ...fieldErrorsMap(cause) }));
      setMessage(normalizeApiError(cause).message);
    } finally {
      setLoadingCategories(false);
    }
  }
  useEffect(() => {
    let active = true;
    categoriesApi
      .list()
      .then((items) => {
        if (active) setCategories(items);
      })
      .catch((cause: unknown) => {
        if (active) setMessage(normalizeApiError(cause).message);
      })
      .finally(() => {
        if (active) setLoadingCategories(false);
      });
    return () => {
      active = false;
    };
  }, []);
  async function submit() {
    const next = validateOccurrence(title, description);
    if (!categoryId) next.categoryId = 'Selecione uma categoria.';
    if (!street.trim()) next.street = 'Informe o logradouro.';
    if (!number.trim()) next.number = 'Informe o numero ou S/N.';
    if (!district.trim()) next.district = 'Informe o bairro.';
    if (!city.trim()) next.city = 'Informe a cidade.';
    if (!/^[A-Za-z]{2}$/.test(state)) next.state = 'Informe uma UF com 2 letras.';
    if (postalCode && !/^\d{5}-\d{3}$/.test(postalCode))
      next.postalCode = 'Use o formato 00000-000.';
    setErrors(next);
    if (Object.keys(next).length) return;
    setSubmitting(true);
    setMessage(undefined);
    try {
      await onSubmit({
        title: title.trim(),
        description: description.trim(),
        categoryId: categoryId!,
        priority,
        address: {
          street: street.trim(),
          number: number.trim(),
          complement: nullable(complement),
          district: district.trim(),
          city: city.trim(),
          state: state.toUpperCase(),
          postalCode: nullable(postalCode),
        },
      });
    } catch (cause) {
      setMessage(normalizeApiError(cause).message);
    } finally {
      setSubmitting(false);
    }
  }
  if (loadingCategories) return <LoadingState label="Carregando categorias..." />;
  if (message && !categories.length)
    return <ErrorState error={new Error(message)} onRetry={() => void loadCategories()} />;
  return (
    <View style={styles.form}>
      <Text style={styles.section}>Sobre o problema</Text>
      <TextField
        label="Titulo"
        value={title}
        onChangeText={setTitle}
        error={errors.title}
        maxLength={120}
      />
      <TextField
        label="Descricao detalhada"
        value={description}
        onChangeText={setDescription}
        error={errors.description}
        multiline
        numberOfLines={5}
        maxLength={2000}
        textAlignVertical="top"
      />
      <Text style={styles.label}>Categoria</Text>
      <ChoiceChips
        choices={categories.map((item) => ({ value: item.id, label: item.name }))}
        value={categoryId}
        onChange={setCategoryId}
      />
      {errors.categoryId ? <Text style={styles.error}>{errors.categoryId}</Text> : null}
      <Text style={styles.label}>Prioridade informada</Text>
      <ChoiceChips
        choices={priorities}
        value={priority}
        onChange={(value) => value && setPriority(value)}
      />
      <Text style={styles.section}>Endereco</Text>
      <TextField label="Logradouro" value={street} onChangeText={setStreet} error={errors.street} />
      <TextField label="Numero" value={number} onChangeText={setNumber} error={errors.number} />
      <TextField
        label="Complemento (opcional)"
        value={complement ?? ''}
        onChangeText={setComplement}
      />
      <TextField
        label="Bairro"
        value={district}
        onChangeText={setDistrict}
        error={errors.district}
      />
      <TextField label="Cidade" value={city} onChangeText={setCity} error={errors.city} />
      <TextField
        label="UF"
        value={state}
        onChangeText={(value) => setState(value.slice(0, 2).toUpperCase())}
        error={errors.state}
        autoCapitalize="characters"
        maxLength={2}
      />
      <TextField
        label="CEP (opcional)"
        value={postalCode ?? ''}
        onChangeText={(value) => setPostalCode(maskPostalCode(value))}
        error={errors.postalCode}
        keyboardType="number-pad"
      />
      {message ? (
        <Text accessibilityRole="alert" style={styles.error}>
          {message}
        </Text>
      ) : null}
      <Button label={submitLabel} loading={submitting} onPress={() => void submit()} />
    </View>
  );
}
const styles = StyleSheet.create({
  form: { gap: spacing.lg },
  section: { ...typography.heading, color: colors.primaryDark, marginTop: spacing.sm },
  label: { ...typography.label, color: colors.text },
  error: { ...typography.caption, color: colors.danger },
});
