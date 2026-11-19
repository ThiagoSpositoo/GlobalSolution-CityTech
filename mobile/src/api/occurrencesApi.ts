import { javaClient } from './javaClient';
import type {
  AiDecision,
  Category,
  HistoryItem,
  ManagerIndicators,
  Occurrence,
  OccurrenceFilters,
  OccurrenceInput,
  OccurrenceStatus,
  PageResponse,
  Priority,
  UpdateOccurrenceInput,
} from './types';

export const categoriesApi = {
  async list() {
    const { data } = await javaClient.get<Category[]>('/categories');
    return data;
  },
};
export const occurrencesApi = {
  async list(filters: OccurrenceFilters = {}) {
    const { data } = await javaClient.get<PageResponse<import('./types').OccurrenceSummary>>(
      '/occurrences',
      { params: filters },
    );
    return data;
  },
  async get(id: string) {
    const { data } = await javaClient.get<Occurrence>(`/occurrences/${id}`);
    return data;
  },
  async create(input: OccurrenceInput) {
    const { data } = await javaClient.post<Occurrence>('/occurrences', input);
    return data;
  },
  async update(id: string, input: UpdateOccurrenceInput) {
    const { data } = await javaClient.put<Occurrence>(`/occurrences/${id}`, input);
    return data;
  },
  async cancel(id: string, version: number, reason: string) {
    await javaClient.delete(`/occurrences/${id}`, { params: { version, reason } });
  },
  async history(id: string, page = 0, size = 50) {
    const { data } = await javaClient.get<PageResponse<HistoryItem>>(`/occurrences/${id}/history`, {
      params: { page, size },
    });
    return data;
  },
  async triage(
    id: string,
    input: { version: number; categoryId?: string; priority?: Priority; note?: string },
  ) {
    const { data } = await javaClient.patch<Occurrence>(`/occurrences/${id}/triage`, input);
    return data;
  },
  async transition(
    id: string,
    input: { version: number; status: OccurrenceStatus; note?: string; reason?: string },
  ) {
    const { data } = await javaClient.patch<Occurrence>(`/occurrences/${id}/status`, input);
    return data;
  },
  async review(id: string, input: { version: number; decision: AiDecision; note?: string }) {
    const { data } = await javaClient.post<Occurrence>(
      `/occurrences/${id}/ai-suggestion/review`,
      input,
    );
    return data;
  },
};
export const managerApi = {
  async indicators() {
    const { data } = await javaClient.get<ManagerIndicators>('/manager/indicators');
    return data;
  },
};
