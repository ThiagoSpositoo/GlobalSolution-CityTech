import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { Text } from 'react-native';
import { occurrencesApi } from '@/api/occurrencesApi';
import type { Occurrence } from '@/api/types';
import { Screen } from '@/components/Screen';
import { ErrorState, LoadingState } from '@/components/StateFeedback';
import { OccurrenceForm } from '@/features/OccurrenceForm';
import { typography } from '@/styles/tokens';

export default function EditOccurrenceScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [item, setItem] = useState<Occurrence>();
  const [error, setError] = useState<unknown>();
  useEffect(() => {
    void occurrencesApi.get(id).then(setItem).catch(setError);
  }, [id]);
  if (error)
    return (
      <Screen>
        <ErrorState error={error} />
      </Screen>
    );
  if (!item)
    return (
      <Screen>
        <LoadingState />
      </Screen>
    );
  return (
    <Screen>
      <Text style={typography.title}>Editar ocorrencia aberta</Text>
      <OccurrenceForm
        initial={{
          title: item.title,
          description: item.description,
          categoryId: item.category.id,
          priority: item.priority,
          address: item.address,
        }}
        submitLabel="Salvar alteracoes"
        onSubmit={async (input) => {
          await occurrencesApi.update(item.id, { ...input, version: item.version });
          router.replace({ pathname: '/(app)/occurrences/[id]', params: { id: item.id } });
        }}
      />
    </Screen>
  );
}
