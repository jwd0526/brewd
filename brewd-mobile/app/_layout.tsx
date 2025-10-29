import { Slot, useRouter, useSegments } from 'expo-router';
import { useEffect } from 'react';

export default function RootLayout() {
  const router = useRouter();
  const segments = useSegments();
  const isLoggedIn = true; // Replace with your actual auth check

  useEffect(() => {
    // Wait a tick to ensure layout is mounted
    const timeout = setTimeout(() => {
      const inAuthGroup = segments[0] === '(auth)';
      
      if (isLoggedIn && inAuthGroup) {
        router.replace('/(main)/');
      } else if (!isLoggedIn && !inAuthGroup) {
        router.replace('/(auth)/login');
      }
    }, 0);

    return () => clearTimeout(timeout);
  }, [isLoggedIn, segments]);

  return <Slot />;
}