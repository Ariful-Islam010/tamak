# Tobacco Awareness App (Tamakmukto Jibon) - Architecture & Design Overview

This document provides a comprehensive overview of the "Tobacco Awareness" (Tamakmukto Jibon) Flutter application. It is structured to help any AI assistant quickly understand the project's frontend screens, backend architecture, state management, and overall data flow.

## 1. Technology Stack
*   **Frontend Framework:** Flutter (Dart SDK `^3.10.8`)
*   **Backend as a Service (BaaS):** Firebase (Firebase Auth, Firestore Database)
*   **External API / Storage:** Cloudinary API (For robust profile image storage and URL generation)
*   **State Management:** Provider (`provider: ^6.1.5+1`)
*   **Design & Theming:** Google Fonts (`google_fonts: ^8.1.0`), Cupertino Icons

## 2. Project Structure (`lib/` directory)
```text
lib/
├── firebase_options.dart      # Firebase configuration settings
├── main.dart                  # App entry point, Firebase init, Provider setup
├── models/
│   └── user_model.dart        # Data schema for User properties
├── screens/
│   ├── auth_screen.dart
│   ├── daily_check_in_screen.dart
│   ├── education_info_screen.dart
│   ├── gamification_screen.dart
│   ├── home_dashboard_screen.dart
│   ├── money_saver_screen.dart
│   ├── onboarding_screen.dart
│   ├── peer_support_screen.dart
│   ├── profile_assessment_screen.dart
│   ├── profile_screen.dart
│   ├── quit_plan_screen.dart
│   └── sos_emergency_screen.dart
├── services/
│   ├── auth_service.dart      # Firebase Auth logic & Google Sign-In
│   └── cloudinary_service.dart# Direct image upload to Cloudinary API
└── theme/
    └── app_theme.dart         # Global UI theming, colors, and typography
```

## 3. Frontend Architecture & Screens
The frontend is divided into specialized screens focused on helping users (specifically targeted at students in classes 9-12) quit tobacco through engagement, tracking, and education.

*   **`onboarding_screen.dart`**: First-time user experience explaining the app's benefits.
*   **`auth_screen.dart`**: Handles User Login and Registration (Email/Password & Google Sign-In).
*   **`profile_assessment_screen.dart`**: Collects initial data needed to build a personalized quit plan (e.g., tobacco type, quit date).
*   **`home_dashboard_screen.dart`**: The main hub post-login. Displays a summary of user progress, current level, and quick actions.
*   **`daily_check_in_screen.dart`**: Interface for users to log their daily cravings, mood, and tobacco-free status.
*   **`quit_plan_screen.dart`**: Shows the user's active strategy and timeline for quitting.
*   **`gamification_screen.dart`**: A vibrant, gamified UI tracking level progression, stats, and badge achievements to keep users highly motivated.
*   **`money_saver_screen.dart`**: Financial tracker showing how much money the user has saved by avoiding tobacco.
*   **`peer_support_screen.dart`**: A community-driven feature allowing users to share experiences and support each other.
*   **`education_info_screen.dart`**: Awareness materials, health facts, and recovery timelines.
*   **`sos_emergency_screen.dart`**: A quick-access tool providing immediate coping mechanisms and distractions during severe cravings.
*   **`profile_screen.dart`**: User account management, displaying user info, and allowing profile picture updates via Cloudinary.

## 4. Backend & Services Structure
The app uses a decoupled service architecture, injecting services into the widget tree via Provider.

### A. Authentication Service (`auth_service.dart`)
*   **Methods:** `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signOut`, `updateProfilePhoto`, `updateUserData`.
*   **State Management:** Extends `ChangeNotifier`. Maintains `_currentUser` and `_isLoading` states.
*   **Data Syncing:** Converts `Firebase User` to the custom `UserModel`. Updates to `displayName` or `photoUrl` are synchronized with Firebase Auth and the local state.

### B. Cloudinary Service (`cloudinary_service.dart`)
*   **Purpose:** Because Firebase Storage can sometimes have complex security rule setups, the app directly uploads profile images to Cloudinary.
*   **Implementation:** Uses `http.MultipartRequest` with a secure SHA-1 signed signature (`crypto` package) based on timestamp and API secret.
*   **Return:** Returns a `secure_url` which is then passed to `AuthService` to update the user's profile photo.

## 5. Data Models
### `user_model.dart`
Defines the core data structure for an authenticated user, extending beyond basic Firebase Auth fields.
*   **Standard Fields:** `uid`, `email`, `displayName`, `photoUrl`.
*   **Custom Fields:** 
    *   `educationalInfo` (String): e.g., Class 9, Class 10.
    *   `tobaccoType` (String): e.g., Cigarettes, Smokeless.
    *   `planDuration` (int): Days planned for quitting.
    *   `quitDate` (DateTime): The target date to stop completely.
*   **Methods:** Contains a `copyWith` method for immutable state updates and a `fromFirebaseUser` factory.

## 6. Global Theming
### `app_theme.dart`
Centralized design system for the app. Emphasizes modern web/app design aesthetics (vibrant colors, glassmorphism hints, dynamic styling) to appeal to the target demographic of high school students. It controls standard `MaterialApp` theme properties like `AppBarTheme`, `ElevatedButtonTheme`, and Text Themes (using `google_fonts`).

## 7. App Flow Summary
1. App launches -> `main.dart` initializes Firebase and provides `AuthService` globally.
2. `TamakmuktoJibonApp` loads `AppTheme` and routes to `OnboardingScreen` (or `AuthScreen`/`HomeDashboard` depending on auth state).
3. User signs in via `AuthService` -> Global `UserModel` state is updated.
4. User completes `ProfileAssessmentScreen` -> Custom fields in `UserModel` are populated and saved to Firestore.
5. User accesses `HomeDashboardScreen` and navigates to specialized features (Gamification, SOS, Money Saver).
6. User uploads a new profile picture -> `CloudinaryService` uploads the file -> returns `secure_url` -> `AuthService` updates Firebase profile.
