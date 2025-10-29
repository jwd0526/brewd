import { Slot } from 'expo-router';

export default function AuthLayout() {
  // Remove the useEffect with router.replace
  // Let the root layout handle navigation
  return <Slot />;
}