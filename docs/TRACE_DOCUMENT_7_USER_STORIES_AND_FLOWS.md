# DOCUMENT 7 — USER STORIES, FLOWS & JOURNEY MAPS

## 1. Introduction
This document captures every user interaction scenario within the Trace ecosystem. Each user story follows the standard format: "As a [role], I want to [action] so that [benefit]." Accompanying each story is the complete technical flow describing what happens across the mobile app, backend API, database, and cloud services.

---

## 2. User Story 1: Reporting a Lost Item

**As a** student who lost their laptop, **I want to** quickly report it with a photo and location, **so that** anyone who finds it can see my report and contact me.

### Complete Flow:
1. **User opens Trace app** → Home screen loads via `GoRouter` declarative navigation
2. **Taps the "+" floating action button** → Navigates to `CreatePostScreen`
3. **Selects "Lost" as post type** → Type toggle switches to red-themed "Lost" mode
4. **Takes a photo with camera** → Flutter `image_picker` captures the image
5. **AI Auto-Analysis kicks in** → Photo is sent to Google Gemini API via `AIService.analyzeItemImage()`
   - Gemini returns: `{ title: "Black Dell Laptop", description: "...", tags: ["electronics", "laptop", "dell"] }`
   - Title, description, and tags fields auto-populate (user can edit)
6. **Selects location** → Building dropdown (Liaquat Block, Engineering Block, etc.) → Floor picker → Room selector
   - Location data comes from `CampusMapService.buildings` static registry
7. **Taps "Publish"** → Post data is sent to `POST /api/posts/sync` backend endpoint
8. **Backend processes the post:**
   - `verifyToken` middleware validates Firebase JWT
   - Post is inserted into Supabase `posts` table
   - Cache is invalidated via `invalidate('posts')` call
   - `runMatchingLogic(newPost)` is triggered asynchronously
9. **Matchmaker Service runs in background:**
   - Queries all `found` posts with `status != 'resolved'` from Supabase
   - Phase 1: Heuristic pre-filter (category match +30, location match +20, title similarity +30)
   - Phase 2: Top 10 candidates are sent to Gemini AI for deep comparison
   - Phase 3: Matches with score ≥ 50% trigger FCM push notifications to both parties
10. **User receives confirmation** → Post appears in their feed immediately

---

## 3. User Story 2: Discovering a Found Item via AI Match

**As a** student who lost their wallet last week, **I want to** receive an automatic notification when someone finds a matching item, **so that** I don't have to manually check the app every hour.

### Complete Flow:
1. Another student finds a wallet and posts it as "Found" through Trace
2. Backend triggers `MatchmakerService.runMatching(foundPost)`
3. Heuristic filter identifies the original "Lost Wallet" post as a candidate:
   - Category match: "Accessories" = "Accessories" → +30 points
   - Building match: "Liaquat Block" = "Liaquat Block" → +20 points
   - Title similarity: "Leather Wallet" vs "Brown Wallet" → +18 points
   - Total heuristic score: 68 → passes 20-point threshold
4. Gemini AI deep evaluation returns: `{ score: 82, reason: "Both describe a brown leather wallet with card slots, found in the same building" }`
5. Score 82 ≥ 50 threshold → Match confirmed
6. `NotificationService.sendToUser()` is called for both users:
   - Saves notification to Supabase `notifications` table
   - Fetches user's `fcm_token` from Supabase
   - Sends FCM push notification: "🔍 AI Match Detected! High match (82%) for your Leather Wallet"
7. User receives push notification on their phone → Taps notification → Opens matched post detail
8. User can now initiate a claim request

---

## 4. User Story 3: Claiming & QR Handshake Verification

**As a** student who found my lost item on Trace, **I want to** prove I'm the real owner and safely receive my item, **so that** fraud is prevented and I get my item back securely.

### Complete Flow:
#### Phase 1 — Claim Request:
1. User views the found item's `PostDetailScreen`
2. Taps "Claim This Item" → Opens `ClaimRequestScreen`
3. Writes proof text: "It's my brown leather wallet. It has my university ID card inside with my name on it."
4. Optionally uploads a proof image (photo of purchase receipt, etc.)
5. Submits claim → `POST /api/claims/request` is called
6. Backend validates:
   - Post exists and `status === 'open'` → ✅
   - Claimer is not the post owner (no self-claims) → ✅
   - No duplicate claim exists for this user + post combo → ✅
7. Claim record inserted into Supabase `claims` table with `status: 'pending'`
8. Finder receives FCM notification: "🎁 New Claim Request — Someone wants to claim your Brown Wallet"

#### Phase 2 — Owner Review:
1. Finder opens `ClaimReviewListScreen` → Sees all pending claims for their post
2. Reviews the proof text and proof image
3. Approves the claim → `PATCH /api/claims/:id` with `{ status: 'approved' }`
4. Backend updates claim status and notifies claimer
5. Both parties can now chat via the in-app chat system to arrange a meetup

#### Phase 3 — QR Handshake:
1. When meeting in person, the finder opens `HandoverQRScreen` → Generates a unique QR code containing the claim ID
2. Claimer opens `HandoverScannerScreen` → Scans the QR code using the device camera
3. Scan triggers `POST /api/claims/handshake/verify`
4. Backend processes the handover:
   - Updates claim `status` to `'resolved'`
   - Updates post `status` to `'resolved'`
   - **Records on blockchain**: `BlockchainService.recordClaim()` creates an immutable hash-chain entry:
     ```
     {
       action: 'ITEM_RECOVERED_VIA_HANDSHAKE',
       claimerId: 'abc123', finderId: 'def456',
       postId: 'post789', timestamp: 1716000000000,
       prev_hash: '7a3f...', current_hash: 'b2e1...'
     }
     ```
   - Awards +50 Karma points to the finder via `supabase.rpc('increment_karma')`
5. Both users see a success animation and the post is marked as resolved across all platforms

---

## 5. User Story 4: Voice-Powered Item Reporting

**As a** student in a rush, **I want to** describe my lost item by voice instead of typing, **so that** I can report it hands-free in under 10 seconds.

### Complete Flow:
1. User opens `CreatePostScreen` → Taps microphone icon
2. Flutter `speech_to_text` plugin activates device microphone
3. User speaks: "I found a silver MacBook Pro on the second floor of Liaquat Block near the Software Engineering Lab"
4. Raw transcript is captured and sent to `AIService.parseVoiceTranscript(transcript)`
5. Gemini AI processes the natural language and returns structured JSON:
   ```json
   {
     "title": "Silver MacBook Pro",
     "type": "found",
     "buildingName": "Liaquat Block",
     "floor": 2,
     "location_room": "Software Engineering Lab",
     "description": "Silver MacBook Pro found on the second floor near the Software Engineering Lab"
   }
   ```
6. All form fields auto-populate with extracted data
7. If Gemini fails (rate limit), the local heuristic fallback parser `_parseVoiceTranscriptLocally()` activates:
   - Detects "found" → type = "found"
   - Detects "MacBook" → title = "Silver MacBook Pro"
   - Detects "Liaquat" → buildingName = "Liaquat Block"
   - Detects "second floor" → floor = 2
   - Detects "software lab" → location_room = "Software Engineering Lab"
8. User reviews and taps "Publish" → Post is created with full location metadata

---

## 6. User Story 5: Offline Item Reporting

**As a** student with poor campus WiFi, **I want to** report a found item even without internet, **so that** my report isn't lost when my connection drops.

### Complete Flow:
1. User fills out post creation form while offline
2. Taps "Publish" → `ApiService.createPost()` fails with network error
3. App catches the error and calls `SyncManager.instance.addPostToQueue(postData)`
4. Post is serialized to JSON and stored in encrypted `SharedPreferences` with a temp ID: `pending_1716000000000`
5. UI shows a "Queued for upload" badge with the pending count
6. **Later**, when WiFi reconnects:
   - `connectivity_plus` fires a connectivity change event
   - `SyncManager.syncQueue()` is triggered automatically
   - For each queued post:
     a. Local image files are uploaded to Cloudinary → CDN URLs returned
     b. Post data (with Cloudinary URLs) is sent to `POST /api/posts/sync`
     c. Successfully synced posts are removed from the queue
     d. Failed posts remain for next retry cycle
7. User is notified that their pending posts have been synced

---

## 7. User Story 6: Admin Content Moderation

**As a** platform administrator, **I want to** review reported posts and ban abusive users, **so that** the platform remains safe and trustworthy.

### Complete Flow:
1. Admin opens the **Next.js Web Dashboard** at `https://trace-self.vercel.app/admin`
2. Firebase web authentication verifies admin credentials
3. Dashboard displays: Total Posts, Resolution Rate, Total Users, Total Comments
   - Data fetched from `GET /api/admin/stats` (aggregation queries on Supabase)
4. Admin navigates to "Flagged Posts" tab → `GET /api/admin/flagged-posts` fetches all posts with `isReported === true`
5. Admin reviews a flagged post and takes action:
   - **Approve**: `POST /api/admin/posts/:postId/moderation { status: 'open' }` → Post becomes visible, reporter gets notification
   - **Reject**: `POST /api/admin/posts/:postId/moderation { status: 'rejected', note: 'Violates guidelines' }` → Post is hidden, user gets notification explaining the reason
6. Admin navigates to "Users" tab → `GET /api/admin/users` lists all registered users
7. Admin bans an abusive user: `POST /api/admin/users/:uid/ban { isBanned: true }`
   - User's `isBanned` flag is set to `true` in Supabase
   - Next time user tries to access any API endpoint, `verifyToken` middleware checks `isBanned` and returns HTTP 403
8. Admin views "Audit Logs" → `GET /api/admin/audit-logs` shows the blockchain-recorded claim history in reverse chronological order

---

## 8. User Story 7: Discord Bot Item Reporting

**As a** student who primarily uses Discord, **I want to** report lost items directly from my Discord server, **so that** I don't need to download a separate app.

### Complete Flow:
1. Student types `/link code:ABC123` in Discord
2. Discord bot receives the interaction and calls `POST /api/discord/link`
3. Backend verifies the linking code against Supabase and associates the Discord ID with the Trace user account
4. Student types `/lost item:Wallet location:Cafeteria description:Brown leather with student ID inside`
5. Discord bot creates a post via `POST /api/posts/sync` with the user's linked credentials
6. Bot responds with an embedded confirmation card:
   ```
   ┌──────────────────────────────────┐
   │ 🔴 Lost Item Reported            │
   │                                  │
   │ Title: Wallet                    │
   │ Location: Cafeteria              │
   │ Status: Open                     │
   │ Description: Brown leather with  │
   │ student ID inside                │
   └──────────────────────────────────┘
   ```
7. The post is now visible on the mobile app, web dashboard, AND Discord — all sharing the same Supabase database

### Available Discord Commands:
| Command | Purpose |
|---|---|
| `/help` | View all available commands |
| `/link` | Link Discord to Trace account |
| `/unlink` | Remove Discord-Trace link |
| `/lost` | Report a lost item |
| `/found` | Report a found item |
| `/recent` | View recent posts |
| `/myitems` | View your posted items |
| `/claim` | Claim an item |
| `/resolve` | Mark item as resolved |
| `/leaderboard` | View top karma users |
| `/stats` | View platform statistics |
| `/search` | Search items by keyword |

---

## 9. User Story 8: Campus Map Item Location

**As a** student looking for my lost phone, **I want to** see exactly which room on which floor the phone was found, **so that** I can go directly to the right location.

### Complete Flow:
1. User views a found item post that has location metadata: `buildingName: "Liaquat Block"`, `floor: 0`, `location_room: "L-001"`
2. Taps the map icon → Opens `MapScreen`
3. **Outdoor View**: OpenStreetMap loads with building markers at real GPS coordinates:
   - Liaquat Block: lat 24.892692, lng 67.088686
   - Quaid Block: lat 24.893240, lng 67.088235
   - Iqbal Block: lat 24.892799, lng 67.087586
4. Taps on Liaquat Block marker → **Indoor View** activates
5. `CampusMapService` loads the building's floor plan data:
   - Wall polygons are rendered as boundary lines
   - Room polygons are rendered as interactive zones
   - The specific room (L-001 "Main Lobby") is highlighted in green
6. Floor selector allows switching between floors (Ground, 1st, 2nd)
7. Stair connections show navigation paths between floors
8. User knows exactly where to go to check for their item

---

## 10. User Story 9: Visual Camera Search

**As a** student, **I want to** point my camera at a similar item and search if it has been reported, **so that** I can quickly check without typing a description.

### Complete Flow:
1. User taps the camera/search icon on the home screen
2. Camera viewfinder opens with Google ML Kit overlay
3. ML Kit processes the camera feed **on-device** (no cloud roundtrip) using the image labeling model
4. Labels are detected in real-time: `["Laptop", "Electronics", "Computer", "Silver"]`
5. These labels are used as search queries against the Trace database
6. Matching posts are displayed in a results overlay
7. User can tap any result to view the full post detail

---

## 11. User Story 10: Two-Factor Authentication Setup

**As a** security-conscious user, **I want to** enable 2FA on my Trace account, **so that** even if someone steals my password, they cannot access my account.

### Complete Flow:
1. User navigates to Profile → Security Settings → "Enable 2FA"
2. App calls `GET /api/security/2fa/setup`
3. Backend generates:
   - A cryptographically random Base32 secret via `authenticator.generateSecret()`
   - An `otpauth://` URI: `otpauth://totp/TracePlatform:user@email.com?secret=JBSWY3DPEHPK3PXP&issuer=TracePlatform`
   - A QR code image (base64 DataURL) via `qrcode.toDataURL()`
4. QR code is displayed on the Flutter screen
5. User scans QR with Google Authenticator app → App starts generating 6-digit TOTP codes that rotate every 30 seconds
6. User enters the current 6-digit code into the Trace app
7. App calls `POST /api/security/2fa/activate { proposedSecret: '...', token: '123456' }`
8. Backend verifies the code using `authenticator.verify({ token, secret, window: 1 })`
9. If valid → Secret is stored in Supabase `users` table (`twoFactorSecret` column), `twoFactorEnabled` set to `true`
10. Future logins will require the TOTP code in addition to the password

---
*Prepared for Project Trace — Cloud Computing Evaluation*
