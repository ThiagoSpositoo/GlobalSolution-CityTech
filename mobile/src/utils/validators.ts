export function validateEmail(value: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) ? undefined : 'Informe um e-mail valido.';
}
export function validatePassword(value: string) {
  return value.length >= 8 && value.length <= 128 && /[A-Za-z]/.test(value) && /\d/.test(value)
    ? undefined
    : 'Use 8 a 128 caracteres, com letra e numero.';
}
export function validateOccurrence(title: string, description: string) {
  const errors: Record<string, string> = {};
  if (title.trim().length < 5 || title.trim().length > 120)
    errors.title = 'Use entre 5 e 120 caracteres.';
  if (description.trim().length < 20 || description.trim().length > 2000)
    errors.description = 'Use entre 20 e 2000 caracteres.';
  return errors;
}
