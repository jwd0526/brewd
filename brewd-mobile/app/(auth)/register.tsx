import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';

export default function RegisterScreen() {
    return (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
            <Text>🔔 Register</Text>
            <Pressable 
                onPress={() => router.push('/login')}
                style={{ 
                    backgroundColor: '#007AFF', 
                    padding: 10, 
                    borderRadius: 5, 
                    marginTop: 20 
                }}
            >
                <Text style={{ color: 'white' }}>Go to Login</Text>
            </Pressable>
        </View>
    )
}
