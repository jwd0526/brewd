import { Tabs } from 'expo-router';
import React from 'react';

export default function Layout() {
  

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#5c3920ff',
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Activity',
        }}
      />
      <Tabs.Screen
        name="discover"
        options={{
          title: 'Discover',
        }}
      />
        <Tabs.Screen
          name="post"
          options={{
            title: 'Post',
          }}
        />
      <Tabs.Screen
        name="notifications"
        options={{
          title: 'Notifications',
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
        }}
      />
    </Tabs>
  );
}
