import React from 'react'
import { Text, View, TouchableOpacity, StyleSheet } from 'react-native'
import { useRouter } from 'expo-router'

export default function Welcome() {
    const router = useRouter()

    return (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
            <Text>Welcome Screen</Text>
            
            <TouchableOpacity 
                style={styles.button}
                onPress={() => router.push('/(auth)/login')}
            >
                <Text style={styles.buttonText}>Login</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
                style={styles.button}
                onPress={() => router.push('/(auth)/register')}
            >
                <Text style={styles.buttonText}>Register</Text>
            </TouchableOpacity>
        </View>
    )
}

const styles = StyleSheet.create({
    button: {
        backgroundColor: '#007AFF',
        paddingHorizontal: 30,
        paddingVertical: 15,
        borderRadius: 8,
        marginTop: 20,
        minWidth: 120,
    },
    buttonText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
        textAlign: 'center',
    },
})
