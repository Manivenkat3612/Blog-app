   npm install
3. Create `.env` file with your credentials:
3. Create your `.env` file (or copy from `.env.example`) and fill in required keys (MongoDB, Cloudinary, Google OAuth, JWT secrets).

4. Launch backend (dev):
   ```bash
   node server.js
   ```

### Mobile (Flutter) Quick Start
```bash
cd mobile
flutter pub get
flutter run
```

If you run on a physical device and the backend is on your PC, replace the API base URL constant with your machine's LAN IP.

### Release APK
```bash
flutter build apk --release
```
Output: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## 3. Environment Variables
Backend `.env` keys summary (see `.env.example` for the full list):

| Key | Purpose |
|-----|---------|
| PORT | API port (default 3000) |
| MONGODB_URI | MongoDB connection string |
| JWT_SECRET | Access token signing secret |
| JWT_REFRESH_SECRET | Refresh token secret (if used) |
| GOOGLE_CLIENT_IDS | Comma separated Google OAuth client IDs (web, android) |
| CLOUDINARY_CLOUD_NAME / API_KEY / API_SECRET | Image hosting |
| DB_RESET_ON_START | (Optional) If `true`, database will be dropped on boot (use only for local resets) |

## 4. Architecture Snapshot

High level data flow:
User (Flutter app) -> REST calls (Dio) -> Express routes -> Controllers -> Mongoose Models -> MongoDB

Selected conventions:
- All protected routes expect a Bearer token (JWT) in `Authorization` header.
- Controllers return consistent JSON `{ success, data, message }` or `{ success: false, error }`.
- Images uploaded via multipart form go directly to Cloudinary; only secure URLs are stored.
- Google sign‑in on device obtains idToken which is exchanged for app JWT on `/api/auth/google`.

## 5. Core Endpoints (Condensed)

Auth:
- POST `/api/auth/google` – Exchange Google idToken for app JWT
- GET  `/api/auth/me` – Current user profile
- POST `/api/auth/logout` – Invalidate refresh/session (stateless client just discards token)

Blogs:
- GET  `/api/blogs` – List (supports paging & search query params)
- POST `/api/blogs` – Create (auth)
- GET  `/api/blogs/:id` – Detail
- PUT  `/api/blogs/:id` – Update (owner)
- DELETE `/api/blogs/:id` – Delete (owner)
- POST `/api/blogs/:id/like` – Toggle like
- POST `/api/blogs/:id/bookmark` – Toggle bookmark

Comments:
- GET  `/api/comments/:blogId`
- POST `/api/comments` (auth)
- DELETE `/api/comments/:id` (owner/moderator)

Users:
- GET `/api/users/me/bookmarks`
- PUT `/api/users/profile`

## 6. Mobile App Highlights

Visual theme: full glassmorphism layer stack (blurred panels, gradient backdrops) with reusable components in `lib/widgets/` (glass cards, frosted text fields, primary actions).

Important directories:
- `lib/controllers/` – GetX controllers (Auth, Blog, Comment, Search, Profile)
- `lib/services/` – API service wrappers (Dio instances, interceptors for auth token)
- `lib/models/` – Data models with `fromJson/toJson`
- `lib/screens/` – Screen widgets (auth, feed, detail, create/edit, profile, search)
- `lib/constants/` – App-wide constants (API base URL, colors, theming)

State management pattern:
1. Bind controllers at app start (dependency injection)
2. UI subscribes via `Obx` to reactive state
3. Network layer sets auth header automatically when token changes

## 7. Development & Quality

Local linting / analysis (Flutter):
```bash
flutter analyze
flutter test
```

Node style: prefer async/await, centralized error handler, minimal logic inside route definitions.

### Error Handling Guarantees
- All uncaught promise rejections are logged.
- Mongo connection uses retry/backoff & can short‑circuit requests if DB is unavailable.
- Client defensive guards around string slicing & null media.

## 8. Operational Tips

Seeding (manual quick start): use a temporary script to insert starter categories or sample blogs, or adapt existing `migrate-categories.js` script in `backend/`.

Health check: add a simple route e.g. `GET /api/health` returning `{ status: 'ok', db: mongoose.connection.readyState }` if you deploy.

Using a new empty database: set `MONGODB_URI` to a fresh database name; optional one‑time `DB_RESET_ON_START=true` to clear immediately, then revert to `false`.

## 9. Security Notes
- Keep `.env` out of version control (already gitignored).
- Never reuse JWT secrets across environments.
- Always URL‑encode special characters in MongoDB passwords.
- Validate image mime types before forwarding to Cloudinary.

## 10. Roadmap Ideas
- Push notification integration (FCM) for likes/comments
- Role-based moderation & soft delete for blogs/comments
- Offline draft storage & sync conflict resolution
- In-app content analytics (views, read time estimation)
- Multi-language localization & dynamic font scaling
- Dark / AMOLED adaptive theme variant

## 11. Troubleshooting Quick Table

| Issue | Likely Cause | Fix |
|-------|--------------|-----|
| Google auth fails | Mismatched client ID | Add correct client ID to `GOOGLE_CLIENT_IDS` (comma list) |
| 10s DB buffering timeout | Wrong `MONGODB_URI` or network/firewall | Verify URI, IP allowlist in Atlas |
| Images not showing | Missing Cloudinary credentials | Fill `.env` & restart server |
| 401 on protected routes | Missing Bearer token | Confirm login flow saved token & header interceptor active |
| Flutter network error on device | Using `localhost` | Use LAN IP or tunneled URL (e.g. ngrok) |

## 12. Author
Nerella Manivenkat  
Contact: 23211a66c1@bvrit.ac.in

---
This repository represents a full-stack mobile blogging experience showcasing modern Flutter UI (glassmorphism), robust Node/Express API design, resilient Mongo connectivity, and structured state management with GetX.

