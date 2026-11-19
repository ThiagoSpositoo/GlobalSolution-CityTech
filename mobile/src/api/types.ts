export type Role = 'CIDADAO' | 'GESTOR';
export type Priority = 'BAIXA' | 'MEDIA' | 'ALTA' | 'CRITICA';
export type OccurrenceStatus =
  'ABERTA' | 'EM_TRIAGEM' | 'EM_ANDAMENTO' | 'RESOLVIDA' | 'ENCERRADA' | 'CANCELADA';
export type AiSuggestionStatus = 'PENDENTE' | 'PRONTA' | 'ACEITA' | 'REJEITADA' | 'FALHOU';
export type AiDecision = 'ACEITAR' | 'REJEITAR';
export type HistoryAction =
  'CRIACAO' | 'EDICAO' | 'TRIAGEM' | 'TRANSICAO' | 'CANCELAMENTO' | 'REVISAO_IA';

export interface FieldError {
  field: string;
  message: string;
}
export interface ApiErrorBody {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  code: string;
  traceId: string;
  timestamp?: string;
  errors?: FieldError[] | null;
}
export interface PageResponse<T> {
  items: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}
export interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
}
export interface Account extends User {
  createdAt: string;
}
export interface LoginResponse {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  user: User;
}
export interface RegisterRequest {
  name: string;
  email: string;
  password: string;
}
export interface LoginRequest {
  email: string;
  password: string;
}
export interface FollowUp {
  id: string;
  occurrenceId: string;
  note: string | null;
  createdAt: string;
  updatedAt: string;
  version: number;
}
export interface CreateFollowUpRequest {
  occurrenceId: string;
  note?: string | null;
}
export interface UpdateFollowUpRequest {
  version: number;
  note?: string | null;
}

export interface CategorySummary {
  id: string;
  code: string;
  name: string;
}
export interface Category extends CategorySummary {
  description: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}
export interface Address {
  street: string;
  number: string;
  complement?: string | null;
  district: string;
  city: string;
  state: string;
  postalCode?: string | null;
}
export interface AddressSummary {
  district: string;
  city: string;
  state: string;
}
export interface OccurrenceInput {
  title: string;
  description: string;
  categoryId: string;
  priority?: Priority;
  address: Address;
}
export interface UpdateOccurrenceInput extends OccurrenceInput {
  version: number;
}
export interface OccurrenceSummary {
  id: string;
  title: string;
  category: CategorySummary;
  priority: Priority;
  status: OccurrenceStatus;
  address: AddressSummary;
  createdAt: string;
  updatedAt: string;
  aiSuggestionStatus: AiSuggestionStatus | null;
}
export interface AiSuggestion {
  status: AiSuggestionStatus;
  suggestedCategory: CategorySummary | null;
  suggestedPriority: Priority | null;
  summary: string | null;
  justification: string | null;
  sources: string[] | null;
  model: string | null;
  promptVersion: string | null;
  errorCode: string | null;
  reviewedAt: string | null;
  decision: AiDecision | null;
}
export interface Occurrence extends Omit<OccurrenceSummary, 'address' | 'aiSuggestionStatus'> {
  citizenId: string;
  description: string;
  address: Address;
  version: number;
  aiSuggestion: AiSuggestion | null;
}
export interface HistoryItem {
  id: string;
  action: HistoryAction;
  fromStatus: OccurrenceStatus | null;
  toStatus: OccurrenceStatus | null;
  actorId: string;
  actorRole: Role;
  note: string | null;
  createdAt: string;
}
export interface OccurrenceFilters {
  status?: OccurrenceStatus;
  categoryId?: string;
  priority?: Priority;
  q?: string;
  page?: number;
  size?: number;
  sort?: string;
}
export interface ManagerIndicators {
  totalOccurrences: number;
  byStatus: Record<string, number>;
  byCategory: Record<string, number>;
}
