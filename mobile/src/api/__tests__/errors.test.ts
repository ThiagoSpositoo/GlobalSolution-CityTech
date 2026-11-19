import { normalizeApiError } from '../errors';

function axiosError(status: number, code: string, retryAfter?: string) {
  return {
    isAxiosError: true,
    response: {
      status,
      headers: retryAfter ? { 'retry-after': retryAfter } : {},
      data: {
        type: 'https://citytech.example/errors/teste',
        title: 'Erro',
        status,
        detail: 'Detalhe real da API',
        instance: '/api/v1/teste',
        code,
        traceId: 'trace-123',
        errors: [{ field: 'title', message: 'campo invalido' }],
      },
    },
  };
}

describe('mapeamento explicito de erros HTTP', () => {
  it('preserva code, traceId e erros de campo no 400', () => {
    const error = normalizeApiError(axiosError(400, 'VALIDATION_ERROR'));
    expect(error.code).toBe('VALIDATION_ERROR');
    expect(error.traceId).toBe('trace-123');
    expect(error.fieldErrors).toEqual([{ field: 'title', message: 'campo invalido' }]);
  });

  it('le Retry-After no 429', () => {
    const error = normalizeApiError(axiosError(429, 'RATE_LIMITED', '45'));
    expect(error.retryAfter).toBe(45);
    expect(error.message).toContain('45s');
  });

  it('nao mascara falha de rede com dados simulados', () => {
    const error = normalizeApiError(new Error('offline'));
    expect(error.code).toBe('NETWORK_ERROR');
    expect(error.message).toContain('conectar');
  });
});
