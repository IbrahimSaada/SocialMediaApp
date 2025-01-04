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
## 📸 **App Screenshots**

### 🔑 **Authentication Screens**

![1](https://github.com/user-attachments/assets/034453a0-face-413b-b6bf-96f3db1cac78)
![2](https://github.com/user-attachments/assets/f96650a6-8e55-4d4f-8336-a68f19cbad41)
![3](https://github.com/user-attachments/assets/f8d27d1c-03f2-4bef-a49b-76176403a5a6)
![Screenshot 2024-12-31 194057](https://github.com/user-attachments/assets/fe61a8d0-ed48-47ed-86a9-94330f24b837)
![Screenshot 2024-12-31 194145](https://github.com/user-attachments/assets/e9b32aaa-46af-4622-938d-766f30c5c022)
![Screenshot 2024-12-31 194225](https://github.com/user-attachments/assets/ee63e3c8-9ed3-46d8-893c-14840994e502)
![Screenshot 2024-12-31 194334](https://github.com/user-attachments/assets/8b257b94-b396-46f0-9c9c-16e8f292f29c)
![Screenshot 2024-12-31 194413](https://github.com/user-attachments/assets/d3173fbe-cd88-45c0-9147-09225cb15b19)

### 🏠 **Home Page**

![Screenshot 2025-01-04 110332](https://github.com/user-attachments/assets/8666414d-a549-45c2-8eee-96a46edccc21)
![Screenshot 2025-01-04 111149](https://github.com/user-attachments/assets/aaae956b-f993-4497-86b9-86ed2f890e05)
![Screenshot 2024-12-31 201609](https://github.com/user-attachments/assets/95742891-e48f-493a-8791-fd51ea1400de)
![Screenshot 2025-01-04 111228](https://github.com/user-attachments/assets/5f16efee-d9dd-4422-891b-b9cb67101296)

### 📖 **Story Feature**
![Screenshot 2024-12-31 201228](https://github.com/user-attachments/assets/497d5a0a-fe72-4153-bae3-95115cb3938e)
![Screenshot 2025-01-04 115634](https://github.com/user-attachments/assets/28567253-cc87-4002-8b6a-1bfcda5c6796)


### 💬 **Comment Section**
![Screenshot 2025-01-04 111228](https://github.com/user-attachments/assets/3354d1d8-a007-4133-8c34-e3b1d7e3f52d)

### 📑 **Menu**
![Screenshot 2025-01-04 114211](https://github.com/user-attachments/assets/90580052-4fe8-48aa-ac14-8abab810cbd7)


### 👤 **My Profile**
![Screenshot 2025-01-04 114519](https://github.com/user-attachments/assets/a62dd98c-1ff7-475f-bc2e-6230f4ee47d7)
![Screenshot 2024-12-31 204946](https://github.com/user-attachments/assets/9bdcac96-0d58-4d4b-88d4-200086749d3e)

### 👥 **Other User Profile**
![Screenshot 2025-01-04 115434](https://github.com/user-attachments/assets/60af486a-86db-4860-9476-4187d2d86393)


### 💬 **Chat**

![Screenshot 2025-01-04 115239](https://github.com/user-attachments/assets/889ffb28-81e8-4a78-850f-a848221ae38c)
![Screenshot 2025-01-04 114948](https://github.com/user-attachments/assets/3469e86f-59a5-4a72-99ab-52688df59ea4)

### 🔔 **Notifications**
![Screenshot 2025-01-04 114546](https://github.com/user-attachments/assets/c252874c-e9e9-4ee7-af8d-abb4f4a52c75)

### 🤝 **Follow Requests**
![Screenshot 2024-12-31 205509](https://github.com/user-attachments/assets/5aabf57e-f4a0-4dc1-a335-dbd49fd75389)
![Screenshot 2024-12-31 205517](https://github.com/user-attachments/assets/60b26521-ab5c-4264-8b95-648a4feab622)

### **🔍 Search**
![sea](https://github.com/user-attachments/assets/c563062f-6b86-49c5-8239-1e17866129ae)
![Screenshot 2024-12-31 205750](https://github.com/user-attachments/assets/783eb380-6129-4281-a121-05da8d220974)




This README provides an overview, setup instructions, and key information about **SocialMediaApp**. If you have additional requirements, let me know! 🚀😊
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




also say we are not published this project yet  and their is private feature will be show when app published in playstore and app store.
