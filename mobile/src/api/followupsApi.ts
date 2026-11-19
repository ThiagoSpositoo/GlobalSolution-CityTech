import { dotnetClient } from './dotnetClient';
import type { CreateFollowUpRequest, FollowUp, PageResponse, UpdateFollowUpRequest } from './types';

export const followupsApi = {
  async list(page = 0, size = 20) {
    const { data } = await dotnetClient.get<PageResponse<FollowUp>>('/followups/', {
      params: { page, size, sort: 'createdAt,desc' },
    });
    return data;
  },
  async get(id: string) {
    const { data } = await dotnetClient.get<FollowUp>(`/followups/${id}`);
    return data;
  },
  async create(input: CreateFollowUpRequest, idempotencyKey: string) {
    const { data } = await dotnetClient.post<FollowUp>('/followups/', input, {
      headers: { 'Idempotency-Key': idempotencyKey },
    });
    return data;
  },
  async update(id: string, input: UpdateFollowUpRequest) {
    const { data } = await dotnetClient.patch<FollowUp>(`/followups/${id}`, input);
    return data;
  },
  async remove(id: string) {
    await dotnetClient.delete(`/followups/${id}`);
  },
};
