import { View, Text, TouchableOpacity } from 'react-native';
import { router } from 'expo-router';

export default function LoginScreen() {
    return (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
            <Text>🔔 Login</Text>
            <TouchableOpacity 
                onPress={() => router.push('/register')}
                style={{ marginTop: 20, padding: 10, backgroundColor: '#007AFF', borderRadius: 5 }}
            >
                <Text style={{ color: 'white' }}>Register</Text>
            </TouchableOpacity>
        </View>
    )
}
