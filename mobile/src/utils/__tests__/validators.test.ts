import { validateEmail, validateOccurrence, validatePassword } from '../validators';

describe('validadores dos contratos', () => {
  it('aceita e-mail e senha no contrato .NET', () => {
    expect(validateEmail('pessoa@example.test')).toBeUndefined();
    expect(validatePassword('SenhaForte123')).toBeUndefined();
  });

  it('rejeita senha sem numero e e-mail invalido', () => {
    expect(validateEmail('invalido')).toBeDefined();
    expect(validatePassword('somenteletras')).toBeDefined();
  });

  it('espelha limites de titulo e descricao do Java', () => {
    expect(validateOccurrence('abcd', 'curta')).toEqual({
      title: 'Use entre 5 e 120 caracteres.',
      description: 'Use entre 20 e 2000 caracteres.',
    });
    expect(
      validateOccurrence('Buraco na via', 'Buraco profundo proximo a faixa de pedestres.'),
    ).toEqual({});
  });
});
