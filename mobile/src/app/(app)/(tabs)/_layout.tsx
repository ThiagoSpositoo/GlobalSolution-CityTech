import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { useAuth } from '@/auth/AuthContext';
import { colors } from '@/styles/tokens';

export default function TabsLayout() {
  const { user } = useAuth();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarStyle: { height: 64, paddingBottom: 8, paddingTop: 6 },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Inicio',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="home-city-outline" color={String(color)} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="occurrences"
        options={{
          title: 'Ocorrencias',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="format-list-bulleted" color={String(color)} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="new-occurrence"
        options={{
          title: 'Registrar',
          href: user?.role === 'CIDADAO' ? undefined : null,
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="plus-circle-outline" color={String(color)} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="followups"
        options={{
          title: 'Acompanhar',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons
              name="bookmark-multiple-outline"
              color={String(color)}
              size={size}
            />
          ),
        }}
      />
    </Tabs>
  );
}
