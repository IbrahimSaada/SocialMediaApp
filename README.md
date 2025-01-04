SocialMediaApp
A Feature-Rich Social Media Mobile Application

<div align="center"> <img src="https://github.com/user-attachments/assets/d3173fbe-cd88-45c0-9147-09225cb15b19" width="250" alt="App Logo"/> </div>
Table of Contents
Overview
Project Status
Key Features
Tech Stack
Folder Structure
Installation
App Screenshots
Build & Deployment
License
Contact & Support
1. Overview <a name="overview"></a>
SocialMediaApp is a mobile social media application built with Flutter. It allows users to create and share various types of content, connect in real-time through chat, and manage their profiles and social presence efficiently.

Core Features Include:

Creating and sharing posts (photos, videos, text)
Real-time chat integration
Stories & ephemeral content
Interactive feed with likes, comments, bookmarks, and shares
User-friendly profile management
Push notifications with Firebase Cloud Messaging
2. Project Status <a name="project-status"></a>
Note: This project is currently not published on any app store. Certain private features are hidden in this version and will be made available once the application is officially released on the Google Play Store and the Apple App Store.

3. Key Features <a name="key-features"></a>
Post Creation
Share text, images, and videos seamlessly.
Real-Time Chat
Instant communication with SignalR.
Story Integration
Add and view user stories just like popular social platforms.
Notifications
Get real-time alerts via Firebase Cloud Messaging.
Profile Management
Bio, rating system, QR code sharing, and more.
Media Playback
Built-in image viewer and video player.
Admin Controls
Features for moderation and restricting inappropriate content.
4. Tech Stack <a name="tech-stack"></a>
Frontend Framework: Flutter (Dart)
State Management: Provider / Bloc (depending on implementation)
Authentication: JWT (JSON Web Token)
Real-Time Communication: SignalR
Notifications: Firebase Cloud Messaging
Media Handling: Video Player, Image Picker, Cached Network Image
Secure Storage: Flutter Secure Storage, Shared Preferences
Networking: Dio, HTTP
Animations: Animate_do, Shimmer
5. Folder Structure <a name="folder-structure"></a>
Below is a high-level overview of the lib directory:

bash
Copy code
lib/
├── main.dart               # Entry point of the application

├── chat/                   # Real-time chat implementation
│   ├── chat_app_bar.dart
│   ├── chat_page.dart
│   ├── message_bubble.dart
│   └── message_input.dart

├── contact/                # Contacts and friends management
│   ├── contact_tile.dart
│   ├── contacts_page.dart
│   └── pluscontact.dart

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
│   └── video_post.dart

├── login/                  # Authentication screens
│   ├── forgotpassword.dart
│   ├── forgotpasswordver.dart
│   ├── login_page.dart
│   ├── new_password_page.dart
│   ├── register.dart
│   └── verification_page.dart

├── maintenance/            # Maintenance screens
│   └── expiredtoken.dart

├── menu/                   # User menu and settings
│   ├── helpnsupport.dart
│   ├── menu_page.dart
│   ├── privacypolicy.dart
│   └── savedposts.dart

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
│   └── feed/
│       ├── feed_item.dart
│       ├── post_info.dart
│       ├── post_item.dart
│       ├── post_media.dart
│       ├── repost_item.dart
│       └── user_info.dart

├── notification/           # Notification management
│   └── notification_page.dart

├── page/                   # Detailed screens for posts and comments
│   ├── comment_details_page.dart
│   ├── post_details_page.dart
│   └── repost_details_page.dart

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
│   └── shared_posts_grid.dart

├── services/               # API and backend service integrations
│   ├── CommentService.dart
│   ├── CreatePostService.dart
│   ├── LoginService.dart
│   ├── PasswordResetService.dart
│   ├── Userprofile_service.dart
│   ├── notificationservice.dart
│   ├── pushnotificationservice.dart
│   ├── signalr_service.dart
│   └── search_service.dart
│   └── crypto/
│       ├── encryption_service.dart
│       ├── key_exchange_service.dart
│       └── key_manager.dart

├── settings/               # User settings screens
│   ├── changepasswordpage.dart
│   └── settings_page.dart

├── utils/                  # Utility functions and constants

└── widgets/                # Reusable UI components
6. Installation <a name="installation"></a>
Prerequisites
Flutter SDK (latest version)
Android Studio or VS Code with Flutter plugin
Firebase Account (for push notifications)
Steps
Clone the repository:

bash
Copy code
git clone https://github.com/<your-repo>/SocialMediaApp.git
cd SocialMediaApp
Install dependencies:

bash
Copy code
flutter pub get
Set up Firebase:

Download google-services.json (Android) and GoogleService-Info.plist (iOS) from your Firebase Console.
Place them in the respective platform folders:
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
Run the app:

bash
Copy code
flutter run
7. App Screenshots <a name="app-screenshots"></a>
Authentication Screens
Login	Register	Forgot Password
		
Additional Screens:


Home Page



Story Feature



Comment Section


Menu


My Profile



Other User Profile


Chat



Notifications


Follow Requests



Search



8. Build & Deployment <a name="build--deployment"></a>
Android
bash
Copy code
flutter build apk --release
iOS
bash
Copy code
flutter build ios --release
Deployment Platforms:

Google Play Store (Android)
Apple App Store (iOS)
The project is currently not published on any store. All private features will be made available upon release.

9. License <a name="license"></a>
This project is licensed under the MIT License.

10. Contact & Support <a name="contact--support"></a>
For questions, issues, or any kind of support, feel free to reach out:

Email: ibrahimsaada99@gmail.com | adamsaifi.cs@gmail.com | ahmadghosen20@gmail.com
Thank You for Checking Out SocialMediaApp!

Stay tuned for the official release to experience the full range of private features.