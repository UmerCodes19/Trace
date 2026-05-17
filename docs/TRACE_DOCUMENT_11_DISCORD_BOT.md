# DOCUMENT 11 — DISCORD BOT & CROSS-PLATFORM INTEGRATION

## 1. Introduction
Trace extends beyond the mobile app and web dashboard by integrating a fully functional Discord bot. This allows students to interact with the Lost & Found system directly from their university Discord servers — reporting items, searching, claiming, and viewing statistics without ever leaving Discord. This document covers the complete Discord bot architecture, command reference, and cross-platform data flow.

---

## 2. Why Discord Integration?
- **University students already use Discord daily** for class coordination, study groups, and social communities
- **Lower friction**: No app download required — students can report items from a platform they already use
- **Community engagement**: Posts appear in shared Discord channels, creating natural visibility
- **Cross-platform data**: All Discord actions sync to the same Supabase database, so items posted from Discord appear in the mobile app and vice versa

---

## 3. Technical Architecture

### 3.1 Bot Stack
- **Runtime**: Node.js
- **Library**: Discord.js v14
- **API Communication**: Axios HTTP client
- **Target API**: Trace backend (`https://trace-self.vercel.app/api`)

### 3.2 Connection Flow
```
[Discord Gateway (Cloud)] ←WebSocket→ [Discord.js Client]
                                              ↓
                                    [Slash Command Handler]
                                              ↓
                                    [Axios HTTP Request]
                                              ↓
                                    [Trace Backend API (Vercel)]
                                              ↓
                                    [Supabase PostgreSQL]
```

### 3.3 Brand Theming
The bot uses the Trace brand color system for embedded messages:
- **Primary (Jade Green)**: `0x00A86B` — General embeds, help menu
- **Red (Crimson)**: `0xE74C3C` — Lost items and errors
- **Green (Emerald)**: `0x2ECC71` — Found items and confirmations
- **Gold**: `0xF1C40F` — Leaderboards and rankings
- **Slate Gray**: `0x7F8C8D` — Search results and detailed cards

---

## 4. Account Linking System

### 4.1 The Problem
Discord users need to be associated with their Trace mobile app accounts to:
- Post items under their real Trace profile
- Claim items with their verified identity
- Accumulate Karma on their actual account

### 4.2 The Solution: 6-Character Linking Code
1. User opens the Trace mobile app → Profile → Settings → "Link Discord"
2. App generates a random 6-character alphanumeric code
3. Code is stored in Supabase `users` table (`linkCode` column)
4. User types `/link code:ABC123` in Discord
5. Bot calls `POST /api/discord/link { discordId, code }`
6. Backend matches the code against the `users` table
7. If found → `discordId` is saved to the user's record, `linkCode` is cleared
8. Future Discord commands use the stored `discordId` to identify the user

---

## 5. Complete Command Reference

### 5.1 `/help` — Interactive Guide
Displays a rich embedded message listing all available commands with descriptions and usage examples.

### 5.2 `/link code:<6-char-code>` — Link Account
Links the Discord user to their Trace mobile app account.

**Flow:**
```
User: /link code:XY7Z3K
Bot: ✅ Account linked successfully! Your Discord is now connected to your Trace profile.
```

### 5.3 `/unlink` — Unlink Account
Removes the Discord-Trace association.

### 5.4 `/lost item:<name> location:<place> [description:<details>]` — Report Lost Item
Creates a new "lost" post in the Trace system.

**Example:**
```
User: /lost item:Black Wallet location:Liaquat Block Cafeteria description:Has my CNIC inside
Bot: 
┌──────────────────────────────────┐
│ 🔴 Lost Item Reported            │
│                                  │
│ Title: Black Wallet              │
│ Location: Liaquat Block          │
│ Status: Open                     │
│ Description: Has my CNIC inside  │
│                                  │
│ Your item has been registered.   │
│ You'll be notified if a match    │
│ is found!                        │
└──────────────────────────────────┘
```

**Backend call:** `POST /api/posts/sync { type: 'lost', title, description, buildingName }`

### 5.5 `/found item:<name> location:<place> [description:<details>]` — Report Found Item
Same as `/lost` but creates a "found" post.

### 5.6 `/recent [limit:<number>]` — View Recent Posts
Fetches the latest posts from the Trace feed.

**Backend call:** `GET /api/posts?limit=5`
**Response:** Paginated embedded list showing each post's title, type, location, and status with color-coded borders.

### 5.7 `/myitems` — View My Posts
Shows all items the linked user has posted.

**Backend call:** `GET /api/users/:uid/posts`

### 5.8 `/claim post_id:<uuid>` — Claim an Item
Submits a claim request for a specific post.

**Backend call:** `POST /api/claims/request { postId, proofText: 'Claimed via Discord' }`

### 5.9 `/resolve post_id:<uuid>` — Mark as Resolved
Marks the user's own post as resolved.

**Backend call:** `PATCH /api/posts/:id/status { status: 'resolved' }`

### 5.10 `/leaderboard` — Karma Leaderboard
Displays the top community members ranked by Karma points.

**Backend call:** `GET /api/users/leaderboard`
**Response:** Gold-themed embedded message with numbered rankings, usernames, and Karma scores.

### 5.11 `/stats` — Platform Statistics
Shows overall Trace platform metrics.

**Backend call:** `GET /api/admin/stats`
**Response:** Shows total posts, resolution rate, total users, and total comments.

### 5.12 `/search query:<keyword>` — Search Items
Searches across all posts by keyword.

**Backend call:** `GET /api/posts?search=<keyword>`

---

## 6. Error Handling

### 6.1 Unlinked Account
If a user tries to run `/lost`, `/found`, `/claim`, or `/myitems` without linking their account first:
```
❌ Account Not Linked
You need to link your Discord account to Trace first!
Use /link code:<your-code> to get started.
```

### 6.2 API Failures
If the backend API is unreachable or returns an error:
```
⚠️ Service Temporarily Unavailable
The Trace API is currently experiencing issues.
Please try again in a few moments.
```

### 6.3 Invalid Post ID
If a user tries to claim or resolve a non-existent post:
```
❌ Post Not Found
The post ID you provided doesn't exist.
Use /recent to see available posts.
```

---

## 7. Cross-Platform Data Flow
The beauty of Trace's architecture is that all platforms share the same cloud database:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Flutter App  │     │ Discord Bot  │     │ Web Dashboard│
│ (Mobile)     │     │ (Discord.js) │     │ (Next.js)    │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                    ┌───────▼───────┐
                    │ Trace Backend │
                    │ (Vercel API)  │
                    └───────┬───────┘
                            │
                    ┌───────▼───────┐
                    │   Supabase    │
                    │  PostgreSQL   │
                    └───────────────┘
```

**Example scenario:**
1. Student A reports a found wallet via `/found` in Discord
2. Student B, using the Flutter mobile app, sees the wallet in their feed
3. Student B submits a claim via the mobile app
4. Student A receives a push notification (FCM) on their phone
5. Admin reviews the claim on the Next.js web dashboard
6. All three platforms see the same data in real-time

---

## 8. Cloud Concepts in Discord Integration

| Concept | Implementation |
|---|---|
| **Cloud Gateway** | Discord's cloud gateway manages WebSocket connections, message routing, and slash command delivery |
| **Webhook Architecture** | Slash commands use Discord's interaction webhook system — events are pushed to the bot, not polled |
| **API Gateway** | Bot communicates with Trace backend through Vercel's API gateway |
| **Shared Cloud Database** | All platforms (mobile, web, Discord) read/write to the same Supabase instance |
| **Environment Variables** | `DISCORD_BOT_TOKEN` and `DISCORD_CLIENT_ID` are managed via cloud environment variable injection |

---
*Prepared for Project Trace — Cloud Computing Evaluation*
