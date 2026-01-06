# Google Maps App

A Flutter application demonstrating Google Maps integration with GetX state management.

## Features

- Display Google Map with current location
- Add markers by tapping on the map
- Draw routes between two points
- Clear markers and routes
- My Location button to re-center map
- Handle location permissions gracefully

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Google Maps API key

### 2. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Maps SDK for Android and iOS
4. Create API credentials and copy the API key

### 3. Configure API Key

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_API_KEY"/>