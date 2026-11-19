import { maskPostalCode, nullable } from '../formatters';

describe('normalizacao antes do envio', () => {
  it('converte campo opcional vazio em null para o Bean Validation Java', () => {
    expect(nullable('   ')).toBeNull();
    expect(nullable(' Apto 2 ')).toBe('Apto 2');
  });

  it('formata CEP no contrato 00000-000', () => {
    expect(maskPostalCode('01000000')).toBe('01000-000');
    expect(maskPostalCode('01000-0009')).toBe('01000-000');
  });
});
