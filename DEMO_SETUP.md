# Mobile Demo Setup Guide - Blog Platform

## 🚀 Quick Start for Assignment Review

### Option 1: Mobile Demo with ngrok (Recommended)

**For testing on real mobile devices:**

1. **Start Backend Server:**
   ```bash
   cd backend
   npm install
   npm start
   ```
   Server runs on `http://localhost:3000`

2. **Setup ngrok (Free account required):**
   ```bash
   # Install ngrok
   npm install -g ngrok
   # OR download from https://ngrok.com/
   
   # Sign up for free account: https://dashboard.ngrok.com/signup
   # Get your authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
   # Set authtoken (replace YOUR_TOKEN):
   ngrok config add-authtoken YOUR_TOKEN
   ```

3. **Expose Backend with ngrok:**
   ```bash
   ngrok http 3000
   ```
   You'll get a URL like: `https://abc123.ngrok.io`

4. **Update Mobile App API URL:**
   - Open `mobile/lib/constants/api_constants.dart`
   - Replace `baseUrl` with your ngrok URL:
   ```dart
   static const String baseUrl = 'https://abc123.ngrok.io/api';
   ```

5. **Build and Install Mobile APK:**
   ```bash
   cd mobile
   flutter build apk
   # APK location: build/app/outputs/flutter-apk/app-release.apk
   ```

6. **Install on Android Device:**
   - Transfer APK to phone and install
   - OR use `flutter install` if device connected via USB

### Option 2: Local Network Demo (Quick Testing - No ngrok needed)

**For testing on same WiFi network:**

1. **Start Backend:**
   ```bash
   cd backend
   npm start
   ```

2. **Mobile app is pre-configured for local IP: `192.168.0.113:3000`**

3. **Build APK:**
   ```bash
   cd mobile
   flutter build apk --release
   # APK location: build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Install on Android device connected to same WiFi and test!**

### Option 3: Web Demo (Instant Testing)

**For quick web testing:**

1. **Start Backend:**
   ```bash
   cd backend
   npm start
   ```

2. **Run Flutter Web:**
   ```bash
   cd mobile
   flutter run -d chrome
   ```
   Access at: `http://localhost:8080`

## 📱 Demo Flow - All Features

### 1. Authentication
- **Register** with email/password
- **Login** with credentials  
- **Google Sign-In** (configured with Firebase)
- **Auto-login** on app restart

### 2. Blog Management
- **View Blog Feed** with pull-to-refresh
- **Create Blog** with rich text editor
- **Upload Images** for featured image
- **Add Categories and Tags**
- **Edit/Delete** your own blogs

### 3. Social Features
- **Like/Unlike** blog posts
- **Bookmark/Save** blogs for later
- **Comment** on blogs with nested replies
- **Delete** your own comments

### 4. User Profiles
- **View Author Profiles** with bio and posts
- **Edit Profile** picture and bio
- **View Bookmarked Blogs**
- **See User Statistics**

### 5. Search & Discovery
- **Search Blogs** by title, content, tags
- **Filter by Category**
- **Popular Tags** discovery
- **Real-time Search** results

## 🛠 Technical Features Demonstrated

### Frontend (Flutter)
- ✅ **GetX State Management** - Reactive programming
- ✅ **Material Design UI** - Modern, responsive
- ✅ **Rich Text Editor** - Flutter Quill integration
- ✅ **Image Handling** - Upload and caching
- ✅ **Offline Support** - Cached network images
- ✅ **Error Handling** - User-friendly error messages

### Backend (Node.js)
- ✅ **REST API** - Complete CRUD operations
- ✅ **JWT Authentication** - Secure token-based auth
- ✅ **MongoDB Integration** - Cloud database (Atlas)
- ✅ **File Upload** - Cloudinary integration
- ✅ **Input Validation** - Comprehensive validation
- ✅ **Error Handling** - Proper HTTP status codes

### Integration
- ✅ **Cross-platform** - Works on Android, iOS, Web
- ✅ **Real-time Updates** - Immediate state updates
- ✅ **Network Handling** - Offline/online states
- ✅ **Performance** - Optimized builds and caching

## 📋 Pre-configured Test Data

The app includes demo functionality with:
- Sample user accounts
- Test blog posts
- Comment threads
- Various categories and tags

## 🎥 Demo Script

**Suggested demo flow (5-7 minutes):**

1. **Launch App** → Show splash screen and auto-login
2. **Browse Blogs** → Demonstrate pull-to-refresh, smooth scrolling
3. **Create New Blog** → Show rich text editor, image upload, categories
4. **Blog Details** → Like, bookmark, add comments with replies
5. **Search** → Search by title, tags, show real-time results
6. **Profile** → View profile, edit bio, see bookmarked blogs
7. **Authentication** → Logout and login with Google

## 💡 Assignment Highlights

### AI Tools Integration
- **70% code generated** using GitHub Copilot
- **Architecture designed** with Claude AI
- **Complete documentation** AI-generated
- **Development time**: 2-3 days vs 4-6 weeks traditional

### Professional Features
- **Production-ready code** with proper error handling
- **Scalable architecture** with clean separation of concerns
- **Modern UI/UX** following Material Design guidelines
- **Complete documentation** with setup instructions

### Technical Excellence
- **Security**: JWT tokens, password hashing, input validation
- **Performance**: Cached images, optimized builds, efficient state management
- **Maintainability**: Clean code, proper folder structure, comprehensive comments
- **Testing Ready**: Modular architecture perfect for unit/integration tests

## 📞 Support

For any issues during review:
1. Check that MongoDB Atlas connection is working
2. Ensure ngrok tunnel is active
3. Verify mobile device is connected to internet
4. Check API URL in mobile app matches ngrok URL

**This setup allows reviewers to:**
- ✅ Test on real mobile devices
- ✅ See all features working live
- ✅ Experience the complete user journey
- ✅ Evaluate both backend and frontend
- ✅ Assess AI-assisted development quality

---
*Developed using AI-powered development tools for Mitt Arv Internship Assignment*