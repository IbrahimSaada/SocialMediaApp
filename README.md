## 🚀 **SocialMediaApp: A Feature-Rich Social Media Mobile Application**

Welcome to **SocialMediaApp**, a mobile social media application built with **Flutter**. This app offers a seamless experience for users to share content, interact with others, and stay updated in real-time.

---

## 📚 **Overview**

This mobile application serves as a complete social media platform where users can:
- **Create and Share Posts:** Upload photos, videos, and text-based posts.
- **Real-Time Chat:** Communicate with other users instantly.
- **Interact with Posts:** Like, comment, share, and bookmark posts.
- **Story Feature:** Add and view stories.
- **Profile Management:** Customize user profiles with bio, QR codes, and rating systems.
- **Push Notifications:** Stay updated with Firebase Cloud Messaging.

The app is built using **Flutter** for cross-platform compatibility and integrates robust services for scalability and performance.

---

## 🛠️ **Tech Stack**

- **Frontend Framework:** Flutter (Dart)
- **State Management:** Provider / Bloc (depending on implementation)
- **Authentication:** JWT (JSON Web Token)
- **Real-Time Communication:** SignalR
- **Notifications:** Firebase Cloud Messaging
- **Media Handling:** Video Player, Image Picker, Cached Network Image
- **Secure Storage:** Flutter Secure Storage, Shared Preferences
- **Networking:** Dio, HTTP
- **Animations:** Animate_do, Shimmer

---

## 📦 **Folder Structure Overview**

```
lib/
├── main.dart               # Entry point of the application

├── chat/                   # Real-time chat implementation
│   ├── chat_app_bar.dart   # Chat header UI
│   ├── chat_page.dart      # Chat UI
│   ├── message_bubble.dart # Chat message widget
│   ├── message_input.dart  # Message input widget

├── contact/                # Contacts and friends management
│   ├── contact_tile.dart   # Contact list tile widget
│   ├── contacts_page.dart  # Contacts listing screen
│   ├── pluscontact.dart    # Add new contacts

├── home/                   # Home page and dashboard components
│   ├── add_friends_page.dart
│   ├── app_bar.dart
│   ├── bottom_navigation_bar.dart
│   ├── comment.dart
│   ├── full_screen_image_page.dart
│   ├── full_screen_story_view.dart
│   ├── home.dart
│   ├── post_bottom_likes_sheet.dart
│   ├── post_card.dart
│   ├── posting.dart
│   ├── report_dialog.dart
│   ├── repost_card.dart
│   ├── search.dart
│   ├── share.dart
│   ├── story.dart
│   ├── story_section.dart
│   ├── video_post.dart

├── login/                  # Authentication screens
│   ├── forgotpassword.dart
│   ├── forgotpasswordver.dart
│   ├── login_page.dart
│   ├── new_password_page.dart
│   ├── register.dart
│   ├── verification_page.dart

├── maintenance/            # Maintenance screens
│   ├── expiredtoken.dart

├── menu/                   # User menu and settings
│   ├── helpnsupport.dart
│   ├── menu_page.dart
│   ├── privacypolicy.dart
│   ├── savedposts.dart

├── models/                 # Data models and DTOs
│   ├── FollowStatusResponse.dart
│   ├── LikeRequest_model.dart
│   ├── ReportRequest_model.dart
│   ├── SearchUserModel.dart
│   ├── comment_model.dart
│   ├── user_model.dart
│   ├── usercontact_model.dart
│   ├── userprofileresponse_model.dart
│   ├── story_model.dart
│   ├── post_model.dart
│   ├── privacy_settings_model.dart

│   ├── feed/               # Models for feed-related data
│   │   ├── feed_item.dart
│   │   ├── post_info.dart
│   │   ├── post_item.dart
│   │   ├── post_media.dart
│   │   ├── repost_item.dart
│   │   ├── user_info.dart

├── notification/           # Notification management
│   ├── notification_page.dart

├── page/                   # Detailed screens for posts and comments
│   ├── comment_details_page.dart
│   ├── post_details_page.dart
│   ├── repost_details_page.dart

├── profile/                # User profile management
│   ├── bookmarked_grid.dart
│   ├── editprofilepage.dart
│   ├── followerspage.dart
│   ├── followingpage.dart
│   ├── otheruserprofilepage.dart
│   ├── profile_page.dart
│   ├── profilepostdetails.dart
│   ├── qr_code.dart
│   ├── shared_post_details_page.dart
│   ├── shared_posts_grid.dart

├── services/               # API and backend service integrations
│   ├── CommentService.dart
│   ├── CreatePostService.dart
│   ├── LoginService.dart
│   ├── PasswordResetService.dart
│   ├── Userprofile_service.dart
│   ├── notificationservice.dart
│   ├── pushnotificationservice.dart
│   ├── signalr_service.dart
│   ├── search_service.dart

│   ├── crypto/             # Cryptography services
│   │   ├── encryption_service.dart
│   │   ├── key_exchange_service.dart
│   │   ├── key_manager.dart

├── settings/               # User settings screens
│   ├── changepasswordpage.dart
│   ├── settings_page.dart

├── utils/                  # Utility functions and constants

├── widgets/                # Reusable UI components

---

## 📥 **Installation Guide**

### Prerequisites
- Flutter SDK (latest version)
- Android Studio or VS Code with Flutter plugin
- Firebase Account for push notifications

### Steps
1. **Clone the repository:**
```bash
git clone https://github.com/<your-repo>/SocialMediaApp.git
cd SocialMediaApp
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Setup Firebase:**
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase Console.
- Place them in the respective platform folders.

4. **Run the app:**
```bash
flutter run
```

---

## 🌟 **Key Features**

- **Post Creation:** Share text, images, and videos.
- **Real-Time Chat:** Instant communication with SignalR.
- **Story Integration:** Add and view user stories.
- **Notifications:** Firebase Cloud Messaging for updates.
- **Profile Management:** Bio, ratings, QR code profile sharing.
- **Media Playback:** Video and image viewers.
- **Admin Controls:** Restricted features for moderation.

---

## 🚀 **Build and Deployment**

### Android Build
```bash
flutter build apk --release
```

### iOS Build
```bash
flutter build ios --release
```

### Deployment Platforms
- **Google Play Store** (Android)
- **Apple App Store** (iOS)

```

---

## 📄 **License**

This project is licensed under the **MIT License**.

---

## 📬 **Contact & Support**

- **Email:** ibrahimsaada99@gmail.com - adamsaifi.cs@gmail.com - ahmadghosen20@gmail.com


