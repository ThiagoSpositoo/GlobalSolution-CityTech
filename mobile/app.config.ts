import type { ExpoConfig } from 'expo/config';

const config: ExpoConfig = {
  name: 'CityTech',
  slug: 'citytech-mobile',
  version: '1.0.0',
  scheme: 'citytech',
  orientation: 'portrait',
  userInterfaceStyle: 'light',
  plugins: ['expo-router', 'expo-secure-store', 'expo-font'],
  experiments: { typedRoutes: true },
  android: {
    package: 'br.com.fiap.citytech.mobile',
    adaptiveIcon: { backgroundColor: '#145DA0' },
  },
  ios: { bundleIdentifier: 'br.com.fiap.citytech.mobile', supportsTablet: true },
  extra: { commitHash: process.env.EXPO_PUBLIC_GIT_COMMIT_HASH ?? 'development' },
};

export default config;
