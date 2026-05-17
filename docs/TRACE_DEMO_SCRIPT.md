# TRACE — Evaluation Demo Script
## Step-by-Step Presentation Flow

---

## BEFORE YOU GO (Prep Checklist)

- App installed on phone, logged in, working
- Create 2 test accounts — one on your phone, one on a teammate's phone (for live claim demo)
- Laptop has: VS Code with project open, browser with Vercel dashboard + Supabase dashboard + NotebookLM slides
- Have the NotebookLM slide deck open in one browser tab
- Have the NotebookLM video ready in another tab (optional, play if they want)
- Phone screen mirroring to laptop if possible (use scrcpy or just hold phone up and show)

---

## THE DEMO FLOW (15-20 minutes)

### PART 1 — Opening Hook (2 min)
**Use: Laptop → NotebookLM Slide Deck**

> "Ma'am, our project is Trace — a cloud-native Lost & Found ecosystem for university campuses."

- Show Slide 1 (Title) → Slide 2 (Problem) → Slide 3 (Solution)
- Keep it quick, just set the context
- Say: "Instead of telling you more, let me show you everything live on the app"

---

### PART 2 — Live App Demo (10-12 min)
**Use: Your Phone**

#### Step 1: Home Feed (30 sec)
- Open the app → Show the home feed
- Point out: "This is the main feed — all lost and found items posted by students. It uses cursor-based pagination so it loads fast even with thousands of posts. Data comes from Supabase cloud database through our Vercel serverless API."
- Show the Lost/Found toggle filter at the top
- Show dark mode toggle quickly

#### Step 2: Create a Post with AI (1.5 min) — STAR FEATURE
- Tap the "+" button
- Select "Found"
- Take a photo of any item on the table (pen, bottle, phone, wallet — anything)
- WAIT for AI auto-fill → Point at screen and say: "See — Google Gemini AI just analyzed the image and automatically generated the title, description, and tags. No typing needed."
- Select building: Liaquat Block → Floor → Room
- Tap Publish
- Say: "That photo just uploaded to Cloudinary CDN, the post data went to our Supabase database through Vercel serverless functions, and the AI matching engine is now running in the background comparing this against all lost items."

#### Step 3: Show AI Match Notification (1 min) — STAR FEATURE
- If you pre-planted a matching "Lost" post earlier, the notification should appear
- Show the push notification: "See — the AI found a match with 82% confidence and sent a Firebase Cloud Messaging notification to both users automatically. Nobody had to search."
- If notification doesn't come live, open the Notifications tab and show a previous one

#### Step 4: Claim Flow (2 min) — STAR FEATURE
- Open any "Found" post from the feed
- Tap "Claim This Item"
- Type proof: "This is my wallet, it has my student ID inside"
- Submit the claim
- Say: "The post owner just got a notification. Let me show you the other side."
- Switch to teammate's phone (or show the claim review screen)
- Show the Claim Review List → Approve the claim
- Say: "Now both parties can chat to arrange a meetup."

#### Step 5: QR Handshake (1 min) — STAR FEATURE
- On one phone: Open Handover QR Screen → Show the QR code
- On other phone: Open Scanner → Scan the QR
- Say: "This is our secure handshake. The moment this QR is scanned, three things happen: the claim is marked resolved, the post is closed, and the entire transaction is recorded on our blockchain audit trail using SHA-256 hashing. Plus the finder gets +50 Karma points."

#### Step 6: Campus Map (30 sec)
- Open the Map Screen
- Show the outdoor building markers
- Tap a building → Show indoor floor plan
- Say: "These are custom indoor vector maps — we built this because GPS doesn't work inside buildings. Students can see exactly which room an item was found in."

#### Step 7: Voice Reporting (30 sec)
- Go to Create Post → Tap the microphone
- Speak: "I found a silver laptop on the second floor of Engineering Block"
- Show how AI fills all fields automatically
- Say: "Gemini AI parses natural language and extracts structured data — building, floor, item type — all from voice. If AI fails, we have a local heuristic fallback so it never breaks."

#### Step 8: Profile & Karma (20 sec)
- Open Profile tab
- Show Karma points, post count, avatar
- Say: "We gamified the system — honest behavior is rewarded with Karma points and a leaderboard."

#### Step 9: Security / 2FA (20 sec)
- Go to Profile → Security Settings
- Show the 2FA setup option
- Say: "We implemented TOTP two-factor authentication using Google Authenticator — the same standard banks use."

---

### PART 3 — Laptop Demos (3-4 min)
**Use: Laptop Browser**

#### Step 10: Web Admin Dashboard (1 min)
- Open browser → Go to your Vercel URL /admin
- Login
- Show: Stats dashboard (total posts, resolution rate, users)
- Show: Flagged posts review
- Show: User management (ban toggle)
- Show: Audit logs (blockchain records)
- Say: "This is the admin panel — built with Next.js 16 and React 19, deployed on Vercel. Maria built this part. Admins can moderate content, ban users, and view the complete blockchain audit trail."

#### Step 11: Discord Bot (1 min)
- Open Discord in browser → Go to your server
- Type /help → Show all 12 commands
- Type /recent → Show embedded post cards
- Type /leaderboard → Show karma rankings
- Say: "Students can report and search items directly from Discord without downloading the app. Muhammad Umer worked on the backend services that power this. All three platforms — mobile, web, Discord — share the same Supabase database."

#### Step 12: Show the Code (1 min)
- Open VS Code with the project
- Quickly expand the folder tree — show the structure
- Open backend/services/ai_service.js → Point to the multi-key rotation
- Open backend/services/blockchain_service.js → Point to SHA-256 hashing
- Open backend/middleware/auth.js → Point to JWT verification
- Say: "The backend has 9 route modules, 4 services, and 2 middleware layers — all deployed as Vercel serverless functions."

---

### PART 4 — Cloud Concepts Summary (1 min)
**Use: Laptop → NotebookLM Slides**

- Switch to slide deck → Jump to the Cloud Architecture slide
- Quickly list: "We used 18 cloud computing concepts:"
  - Supabase — Database as a Service
  - Firebase Auth — Identity as a Service
  - Vercel — Serverless Functions
  - Gemini AI — AI as a Service
  - FCM — Push Notifications
  - Cloudinary — CDN
  - Docker — Containerization
  - GitHub Actions — CI/CD
  - Blockchain audit trail
- Show the last slide (closing)

---

### PART 5 — Closing (30 sec)

> "Trace is not just an app — it's a complete cloud-native ecosystem. Mobile app, web dashboard, Discord bot, AI engine, and blockchain security. 18 cloud concepts working together to make sure losing something on campus is a minor inconvenience, not a crisis. Thank you!"

---

## IF MA'AM ASKS QUESTIONS

**"How does the AI matching work?"**
3 phases — heuristic filter first (free, fast), then Gemini AI deep comparison, then notification dispatch.

**"What is the blockchain doing here?"**
Every item handover is recorded as a SHA-256 hash block. Each block links to the previous one. If anyone tampers with a record, the hash chain breaks and we detect it instantly.

**"How is this cloud computing?"**
We use zero physical servers. Everything runs on managed cloud services — Supabase, Firebase, Vercel, Gemini, Cloudinary. The backend auto-scales, costs nothing, and requires no infrastructure management.

**"What did each member do?"**
I (Umer Qureshi) did the mobile app, backend, AI, blockchain, Discord bot. Muhammad Umer worked on backend cloud services, notification system, and admin routes. Maria built the web dashboard and deployed it on Vercel.

**"Is it deployed?"**
Yes — backend and web dashboard are live on Vercel, database is on Supabase cloud, APK is available for download via GitHub Releases.

**"What about security?"**
Firebase JWT auth, role-based access control, 2FA with Google Authenticator, rate limiting, CORS, Helmet.js headers, QR handshake verification, and encrypted offline storage.

---

## STAR FEATURES (Emphasize these the most)

1. AI auto-fill from photo (live demo)
2. AI match notification (live demo)  
3. QR handshake + blockchain record
4. Discord bot cross-platform sync
