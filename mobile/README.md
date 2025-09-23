# Mobile Client – Blog Platform

Fully featured Flutter client for the Blog Platform backend. Focus areas: glassmorphism UI, reactive state with GetX, resilient API access, and smooth authoring of rich blog content.

## 1. Feature Snapshot
* Google sign‑in → JWT session exchange
* Feed with pagination, pull to refresh, optimistic like/bookmark toggles
* Blog composer (rich text, image attach, draft handling placeholder)
* Comment thread viewer & poster
* Search (title/content) and category filtering
* Profile edit (avatar, display name, bio)

## 2. Quick Run
```bash
flutter pub get
flutter run
```
If the API runs on your desktop and you are on a physical device, update the base URL constant to your machine LAN IP (see section 4).

## 3. Project Layout (mobile/)
```
lib/
	main.dart                # App bootstrap & initial bindings
	constants/               # API base URL, style tokens
	controllers/             # GetX controllers (Auth, Blog, Comment, Search, Profile)
	models/                  # Plain model classes with fromJson/toJson
	services/                # Dio client, auth interceptor, media helpers
	screens/                 # UI screens (auth, feed, detail, create, profile, search)
	widgets/                 # Reusable glass / frosted widgets, buttons, inputs
	firebase_options.dart    # Generated Firebase config
```

## 4. API Base URL
Edit `lib/constants/api_constants.dart` (or equivalent constant file) and set:
```dart
// Example (replace with LAN IP or tunneled host)
const String kApiBase = 'http://192.168.0.105:3000/api';
```
Important: do not use `localhost` on a device; use your computer's IP or a tunnel (e.g. ngrok, Cloudflare tunnel).

## 5. State & Data Flow
1. AuthController manages token & user profile
2. Dio client injects Authorization header when token is present
3. Controllers expose Rx models / lists; UI consumes with `Obx`
4. Blog list uses lazy loading (page cursor) & refresh triggers full reload
5. Error surfaces via snackbars / overlay toasts

## 6. Theming & UI System
Glassmorphism approach:
* Layered gradients at root scaffold
* Blurred containers (BackdropFilter) for panels
* Consistent spacing scale (4 / 8 / 12 / 16 / 24)
* Reusable widgets: GlassCard, FrostedTextField, PrimaryActionButton

Accessibility notes:
* Minimum tap target 44x44 logical px
* Text contrast tested against gradient backgrounds
* Scrollable areas avoid nested scroll conflicts

## 7. Rich Text Editing
The composer uses a Quill-based editor (check `services/` or `widgets/` directories). When uploading an image:
* User selects via gallery/camera
* File uploaded via API (multipart -> Cloudinary on backend)
* Returned secure URL inserted into editor document

## 8. Local Persistence
* Auth token cached (SharedPreferences) for auto login
* Last successful feed snapshot may be cached (optional / future enhancement)
* Draft persistence (planned improvement) – can be implemented via local JSON file or preferences

## 9. Error Handling Patterns
| Layer | Strategy |
|-------|----------|
| Network | Dio interceptor inspects non-2xx, maps to unified error object |
| Auth Expiry | 401 triggers logout + redirect to login screen |
| Parsing | Model factories guard against missing keys, fallback defaults |
| UI | Snackbars for recoverable issues, silent log for non-critical |

## 10. Logging
Custom lightweight logger wrapper is used instead of `print` to avoid noise in release and unify formatting. Adjust verbosity via a flag if needed.

## 11. Testing
Run widget / unit tests:
```bash
flutter test
```
Suggested future tests:
* Auth flow (mocked backend)
* Blog list pagination (fake data provider)
* Editor image insertion & serialization

## 12. Building Release APK
```bash
flutter build apk --release
```
Optionally create app bundle:
```bash
flutter build appbundle
```
Artifacts appear under `build/app/outputs/`.

## 13. Performance Considerations
* Avoid rebuilding large lists: item widgets kept lean & const where possible
* Image placeholders + caching reduce layout jank
* Debounced search queries minimize network chatter
* Defensive substring operations prevent runtime crashes on short strings

## 14. Troubleshooting Cheat Sheet
| Symptom | Cause | Remedy |
|---------|-------|--------|
| White screen at start | Missing bindings or async init hang | Check `main.dart` initial binding & Firebase init
| 401 after login | Base URL mismatch or token not saved | Confirm token persistence & header injection
| Network fail on device | Using localhost | Replace with LAN IP / tunnel URL
| Images broken | Cloudinary env not configured backend | Verify backend `.env` & restart server
| Editor crash inserting image | Null file or size too large | Add file null/size guard prior upload

## 15. Planned Enhancements
* Offline drafts & queue for later publish
* Push notifications (FCM) for likes/comments
* Theme variants (dark / AMOLED)
* In-app analytics (read time, retention)

## 16. Security Notes
* Token cleared on explicit logout & on any 401 chain
* Avoid logging PII (email) in release logs
* All external URLs validated before rendering images

## 17. Contribution (Internal)
Not open to external contributions (assignment context). For modifications:
1. Branch from `main`
2. Run analyzer & tests before PR
3. Keep UI components generic & reusable

## 18. License
Internal / educational use (no formal license declared).

---
End of mobile client README.
 
## 19. AI Assistance Documentation

This mobile client benefitted from iterative AI pair‑programming support. Below is a transparent (and intentionally verbose) log of categories where AI guidance accelerated delivery:

| Area | Nature of AI Help | Human Validation Steps |
|------|-------------------|------------------------|
| Architectural Skeleton | Suggested initial folder layout & DI (GetX bindings) structure | Reviewed vs common Flutter patterns; pruned unused suggestions |
| Glassmorphism Components | Generated prototype code for blurred containers, gradient layers, reusable buttons | Refactored for consistency, removed redundant opacity layers, added accessibility contrast checks |
| API Service Layer | Drafted Dio interceptor boilerplate & token refresh pattern scaffold | Manually adjusted to current auth (no refresh yet) & added error mapping enum |
| Models & JSON Parsing | Produced `fromJson/toJson` templates | Field types cross‑checked with backend schema; added null guards |
| Blog List Pagination | Proposed lazy loading pattern and scroll listener snippet | Integrated with existing controller; added debounce & end-of-list guard |
| Rich Text Editor Integration | Provided Quill controller initialization & toolbar wiring examples | Reduced unused toolbar actions; added image insert hook customization |
| Form & Validation | Suggested basic validators (empty, length) | Rewrote messages for UX tone; added defensive trimming |
| Error Handling | Provided pattern for unified snackbar error presenter | Unified with custom logger & removed generic catch blocks in favor of typed errors |
| Performance Tips | Recommended const constructors & list item caching | Audited widgets and applied where it reduced rebuilds |
| Troubleshooting Runtime Crashes | Assisted in tracing substring RangeErrors & animation controller misuse | Added defensive substring clamps & lifecycle disposal checks |

### Representative AI-Derived Snippet (Refactored)
```dart
// Original AI draft simplified & hardened:
Widget build(BuildContext context) {
	return Obx(() {
		final blogs = controller.blogs; // RxList
		if (controller.isLoading.value && blogs.isEmpty) {
			return const Center(child: CircularProgressIndicator());
		}
		return RefreshIndicator(
			onRefresh: controller.refreshBlogs,
			child: ListView.builder(
				physics: const AlwaysScrollableScrollPhysics(),
				itemCount: blogs.length + (controller.hasMore.value ? 1 : 0),
				itemBuilder: (ctx, i) {
					if (i >= blogs.length) {
						controller.loadMore();
						return const Padding(
							padding: EdgeInsets.all(16),
							child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
						);
					}
					return BlogGlassCard(blog: blogs[i]);
				},
			),
		);
	});
}
```

### Guardrails Applied to AI Output
* Removed any unsafe string slicing (added length checks)
* Consolidated duplicate GetX `put` calls into single binding initialization
* Replaced broad `catch (e)` with typed / layered error handling where meaningful
* Ensured no secrets or keys were ever suggested directly in code
* Confirmed all third‑party dependency suggestions matched existing locked versions

### Productivity Impact (Approximate)
| Category | Estimated Time Saved |
|----------|----------------------|
| Repetitive model & JSON boilerplate | 1.5 hrs |
| UI prototype scaffolding | 3 hrs |
| Pagination & loading pattern | 45 mins |
| Editor integration hints | 1 hr |
| Error handling consolidation | 40 mins |
| TOTAL (rounded) | ~6–7 hrs |

### Human Ownership Statement
All AI contributions served as drafts. Every committed line was:
1. Read & understood
2. Adjusted for project conventions (naming, null safety, style)
3. Verified via analyzer & runtime smoke tests

AI never made unilateral architectural decisions; it proposed options that were curated manually.

---
