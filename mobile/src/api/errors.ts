import { isAxiosError } from 'axios';
import type { ApiErrorBody, FieldError } from './types';

export class AppError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
    public readonly code = 'NETWORK_ERROR',
    public readonly fieldErrors: FieldError[] = [],
    public readonly traceId?: string,
    public readonly retryAfter?: number,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export function normalizeApiError(error: unknown): AppError {
  if (error instanceof AppError) return error;
  if (!isAxiosError<ApiErrorBody>(error) || !error.response) {
    return new AppError(
      'Nao foi possivel conectar aos servicos. Verifique a rede e tente novamente.',
    );
  }
  const { status, data, headers } = error.response;
  const retryHeader = headers['retry-after'];
  const retryAfter = retryHeader ? Number(retryHeader) : undefined;
  const messages: Record<number, string> = {
    400: data.detail || 'Revise os dados informados.',
    401: 'Sua sessao expirou. Entre novamente.',
    403: 'Voce nao possui permissao para esta acao.',
    404: data.detail || 'O recurso nao foi encontrado ou nao esta disponivel.',
    409: data.detail || 'Os dados foram alterados. Atualize e tente novamente.',
    429: `Limite de tentativas atingido.${retryAfter ? ` Aguarde ${retryAfter}s.` : ''}`,
    500: 'O servico encontrou uma falha inesperada.',
    503: 'O servico esta temporariamente indisponivel. Tente novamente.',
  };
  return new AppError(
    messages[status] ?? data.detail ?? 'Nao foi possivel concluir a operacao.',
    status,
    data.code,
    data.errors ?? [],
    data.traceId,
    retryAfter,
  );
}

export function fieldErrorsMap(error: unknown): Record<string, string> {
  const normalized = normalizeApiError(error);
  return Object.fromEntries(normalized.fieldErrors.map((item) => [item.field, item.message]));
}
