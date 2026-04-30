# GEMINI.md - Mobile Toko Keluarga

This document provides instructional context and development guidelines for the `mobile_tokokeluarga` project.

## Project Overview
`mobile_tokokeluarga` is a Flutter-based mobile application designed for field staff of "Toko Keluarga". Its primary focus is facilitating the receipt of goods (penerimaan barang) with offline support and camera integration for capturing physical receipts.

- **Primary Technologies:** Flutter (SDK ^3.7.2), Dart.
- **Key Libraries:** 
    - **Dio:** For RESTful API communication with the Laravel backend.
    - **SQFlite:** Local database for offline storage and synchronization.
    - **Provider:** State management for app state and synchronization status.
    - **Camera & Image Picker:** For capturing and selecting photos of delivery notes/receipts.
    - **Flutter Secure Storage:** For secure storage of authentication tokens.

## Architecture
The project follows a feature-driven Clean Architecture pattern:
- **Core:** `lib/core/` contains global utilities like `ApiClient` and `DatabaseHelper`.
- **Features:** `lib/features/` is organized by functional modules (e.g., `auth`, `inventory`).
    - **Data:** Repository implementations, data sources (local/remote), and models.
    - **Domain:** Business logic, entities, and repository interfaces.
    - **Presentation:** UI screens, widgets, and state management (Providers).

## Building and Running

### Prerequisites
- Flutter SDK (^3.7.2)
- Android Studio / VS Code with Flutter extension
- Android/iOS Emulator or Physical Device

### Development Commands
- **Install Dependencies:**
  ```bash
  flutter pub get
  ```
- **Run the App:**
  ```bash
  flutter run
  ```
- **Run Tests:**
  ```bash
  flutter test
  ```

## Development Conventions
- **Feature Isolation:** Keep logic related to a specific feature within its respective `lib/features/` folder.
- **API Integration:** Use the `ApiClient` in `lib/core/` for all network requests to ensure consistent headers and error handling.
- **Offline First:** Design features (especially inventory/penerimaan) to work offline using SQFlite, then synchronize when a connection is available.
- **Type Safety:** Use strongly typed models for API responses and database entities.
- **Naming Conventions:** Follow standard Flutter/Dart naming conventions (PascalCase for classes, camelCase for variables/functions).

---

*This file is intended for AI agents to understand the project context quickly.*
