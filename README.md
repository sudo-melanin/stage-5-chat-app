# Realtime Chat App (HNG Stage 5)

## Overview
This is a real-time chat application built with Flutter as part of the HNG Mobile Track Stage 5 task. The app supports multi-user messaging with Firebase backend services and focuses on clean architecture and responsive UI.

## Features
- Email/password authentication
- Real-time messaging with Firestore
- User search and conversation creation
- Typing indicators
- Message reactions (emoji)
- Message edit and delete (for me / for everyone)
- Read receipts (Sent, Delivered, Seen)
- Voice note recording and playback
- Audio playback with speed control and countdown timer
- In-chat message search with highlighting
- Clean UI with reusable components

## Tech Stack
- Flutter (Dart)
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Riverpod (State Management)
- just_audio (Audio playback)
- record (Audio recording)

## Architecture
The project follows a feature-first, MVVM-inspired architecture:
- Presentation: UI screens and widgets
- Providers: State management (Riverpod)
- Repository: Firebase data handling
- Models: Data structures

UI components were refactored into reusable widgets such as:
- MessageBubble
- ChatInputBar
- RecordingBar
- AudioMessageBubble

## How to Run
1. Clone the repo
2. Configure Firebase (Auth, Firestore, Storage)
3. Run:
```dart
- flutter pub get
- flutter run
```

## Known Limitations
- Audio delete state may not fully remove playback in all cases
- Reaction aggregation is basic (no counts yet)

## Video Demo
https://youtu.be/cnz7T2R59II

## Live Demo Link (Appetize)


## Author
Amos Emmanuel for HNG Internship 14