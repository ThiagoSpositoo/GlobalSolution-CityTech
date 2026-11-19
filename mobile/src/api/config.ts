const trimTrailingSlash = (value: string) => value.replace(/\/+$/, '');

/**
 * localhost funciona no computador/Expo Web. No Android Emulator use 10.0.2.2,
 * pois localhost aponta para o proprio emulador. Em dispositivo fisico com Expo Go,
 * use o IP LAN da maquina (por exemplo, 192.168.1.50) na mesma rede Wi-Fi.
 * Builds de avaliacao devem apontar para URLs HTTPS publicamente alcancaveis.
 */
export const apiConfig = {
  dotnetBaseUrl: trimTrailingSlash(
    process.env.EXPO_PUBLIC_DOTNET_API_URL ?? 'http://localhost:8081',
  ),
  javaBaseUrl: trimTrailingSlash(process.env.EXPO_PUBLIC_JAVA_API_URL ?? 'http://localhost:8080')
} as const;

export const apiHosts = {
  dotnet: new URL(apiConfig.dotnetBaseUrl).host,
  java: new URL(apiConfig.javaBaseUrl).host,
};
