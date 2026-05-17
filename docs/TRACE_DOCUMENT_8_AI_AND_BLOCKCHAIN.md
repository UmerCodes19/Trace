# DOCUMENT 8 — AI & BLOCKCHAIN DEEP DIVE

## 1. Introduction
This document provides an exhaustive technical deep dive into the two most advanced subsystems within Trace: the AI-Powered Matching Engine and the Blockchain-Inspired Audit Trail. These systems represent the cutting edge of the platform, transforming a simple lost-and-found app into an intelligent, tamper-proof ecosystem.

---

## 2. THE AI ENGINE

### 2.1 Overview
Trace integrates Google Gemini (formerly Bard) generative AI models across three distinct use cases:
1. **Item Image Analysis** — Automatic metadata extraction from photos
2. **Cross-Post Matching** — Intelligent similarity scoring between lost and found items
3. **Voice Transcript Parsing** — Natural language understanding for hands-free reporting

All AI operations use a fault-tolerant, multi-key, multi-model architecture designed for maximum uptime on free-tier API quotas.

### 2.2 Multi-Key Rotation Pool Architecture
The AI service implements a **round-robin API key rotation** strategy:

```
Key Pool: [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
                ↓ (rotate on each request)
Request 1 → KEY_1
Request 2 → KEY_2
Request 3 → KEY_3
...
Request 6 → KEY_1 (wraps around)
```

**Why this matters for cloud computing:**
- Each Gemini API key has a free-tier rate limit (e.g., 60 requests/minute)
- With 5 keys, the effective free-tier capacity becomes 300 requests/minute
- This is a cloud cost optimization technique called **quota pooling**
- Zero additional cost — all keys use the same free tier

### 2.3 Multi-Model Fallback Chain
If the primary model fails (rate limit, server error, unsupported feature), the system automatically tries the next model:

```
Attempt Order:
  1. gemini-flash-latest        (fastest, cheapest)
  2. gemini-2.5-flash-lite      (backup fast model)
  3. gemini-flash-lite-latest   (lightweight alternative)
  4. gemini-pro-latest          (most capable, slower)
```

**Fallback logic:**
- If a model returns HTTP 429 (rate limit) → Break model loop, try next API key
- If a model returns any other error → Try next model with same key
- If all models and all keys fail → Fall back to local heuristic parser (for voice) or return null (for images)

### 2.4 Image Analysis Pipeline

**Input:** Raw image file (JPEG/PNG) from user's camera
**Output:** Structured JSON with title, description, and tags

**Prompt Engineering:**
```
You are an AI assistant for a Lost & Found app at a university campus.
Analyze this image of an item.
Return a JSON object strictly following this structure:
{
  "title": "A concise, descriptive title (max 5 words)",
  "description": "Detailed physical description including color, brand, condition",
  "tags": ["tag1", "tag2", "tag3"] // 3-5 relevant single-word tags
}
```

**Technical details:**
- Image is read as raw bytes and sent as a `DataPart` with MIME type detection
- Response is constrained to `application/json` via `responseMimeType` parameter
- Temperature is set to 0.4 (low creativity, high accuracy) for consistent results
- The structured JSON response is parsed and used to auto-populate form fields

### 2.5 Matching Engine — The 3-Phase Pipeline

The Matchmaker Service orchestrates a sophisticated 3-phase pipeline:

#### Phase 1: Heuristic Pre-Filtering (Fast, Free, Local)
Purpose: Quickly eliminate irrelevant candidates before expensive AI calls.

```
Scoring Matrix:
  Category match:     +30 points (e.g., both "Electronics")
  Building match:     +20 points (e.g., both "Liaquat Block")
  Title similarity:   +0 to +30 points (word overlap calculation)
  
  Threshold: Score ≥ 20 to advance
  Max candidates forwarded: 10
```

This phase runs entirely on the server using simple string comparisons — no AI API calls, no cloud costs. It eliminates ~90% of irrelevant candidates instantly.

#### Phase 2: AI Deep Evaluation (Accurate, Cloud-Powered)
Purpose: Use Gemini's reasoning ability to deeply compare remaining candidates.

The prompt provides the new post's full details and up to 10 candidate posts, asking Gemini to return scored results:
```json
[
  { "candidateId": "abc123", "score": 85, "reason": "Both describe a silver laptop with stickers, found in the same building on the same floor" },
  { "candidateId": "def456", "score": 32, "reason": "Different color and brand, unlikely match" }
]
```

#### Phase 3: Notification Dispatch
All matches with score ≥ 50 are considered valid. For each valid match:
- Both the poster and the matched post's owner receive FCM push notifications
- Notifications include the match score percentage and a direct link to the matched post
- Notifications are also stored in Supabase for in-app display

### 2.6 Voice Transcript AI Parser
When users report items by voice, the raw transcript is sent to Gemini with a specialized prompt:

```
Analyze this voice report transcript and extract structured information.
Transcript: "I found a silver MacBook Pro on the second floor of Liaquat Block"

Return JSON:
{
  "title": "Silver MacBook Pro",
  "type": "found",
  "buildingName": "Liaquat Block",
  "floor": 2,
  "location_room": null,
  "description": "Silver MacBook Pro found on the second floor of Liaquat Block"
}
```

**Local Fallback Parser:**
If all AI keys are exhausted, a heuristic parser activates:
- Keyword detection for type: "found"/"lost"/"discovered"/"spotted"
- Building name detection: "liaquat"/"engineering"/"library"/"quaid"/"iqbal"
- Floor detection: "1st floor"/"second floor"/"floor 3"
- Item detection: "macbook"/"wallet"/"phone"/"keys"/"bag"
- Room detection: "software lab"/"room 102"/"cafeteria"

---

## 3. THE BLOCKCHAIN AUDIT TRAIL

### 3.1 Why Blockchain in a Lost & Found App?
When a found item is handed over to a claimer, there must be an immutable, tamper-proof record that:
- Proves the handover happened
- Records who received the item and who gave it
- Cannot be altered after the fact (even by administrators)
- Provides an auditable history for dispute resolution

Traditional database records can be edited or deleted. The blockchain-inspired hash chain makes any tampering immediately detectable.

### 3.2 How the Hash Chain Works

Each claim log entry (block) contains:
```
Block N:
  claim_id:     "claim_789"
  prev_hash:    "7a3f8b..." (Block N-1's current_hash)
  current_hash: "b2e1c4..." (SHA-256 of prev_hash + data + timestamp)
  data:         { action, claimerId, finderId, postId, ... }
  timestamp:    1716000000000
```

**Hash Generation Algorithm:**
```javascript
static generateHash(prevHash, data, timestamp) {
  // 1. Sort data keys alphabetically for deterministic hashing
  const sortedData = {};
  Object.keys(data).sort().forEach(key => { sortedData[key] = data[key]; });
  
  // 2. Concatenate: previous hash + sorted data + timestamp
  const content = prevHash + JSON.stringify(sortedData) + timestamp.toString();
  
  // 3. Generate SHA-256 hash
  return crypto.createHash('sha256').update(content).digest('hex');
}
```

### 3.3 Chain Structure Visualization
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  BLOCK 0        │     │  BLOCK 1        │     │  BLOCK 2        │
│  (Genesis)      │     │                 │     │                 │
│                 │     │                 │     │                 │
│ prev: "GENESIS" │────▶│ prev: "a1b2..." │────▶│ prev: "c3d4..." │
│ hash: "a1b2..." │     │ hash: "c3d4..." │     │ hash: "e5f6..." │
│ data: {...}     │     │ data: {...}     │     │ data: {...}     │
│ time: 170100... │     │ time: 170200... │     │ time: 170300... │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 3.4 Chain Validation Algorithm
The `validateChain()` function verifies the entire chain's integrity:

1. Fetch all blocks from Supabase ordered by timestamp ascending
2. For each block:
   a. Verify `prev_hash` matches the previous block's `current_hash` (link integrity)
   b. Recompute `current_hash` from the block's own data (content integrity)
   c. Compare recomputed hash with stored hash
3. If any mismatch is found → Chain is compromised → Return `{ valid: false, error: 'description' }`
4. If all blocks pass → Return `{ valid: true, count: N }`

### 3.5 Tamper Detection Example
If an attacker tries to modify Block 1's data:
```
Original Block 1: hash = SHA256("a1b2..." + '{"action":"RECOVERED"}' + "170200...")
                 = "c3d4..."

Tampered Block 1: hash = SHA256("a1b2..." + '{"action":"STOLEN"}' + "170200...")
                 = "x9y8..."  ← DIFFERENT!

Block 2's prev_hash still says "c3d4..." but Block 1 now has "x9y8..."
→ Chain validation detects the mismatch immediately
```

### 3.6 Events Recorded on the Blockchain
| Event | Trigger | Data Recorded |
|---|---|---|
| Claim Request Created | User submits a claim | claimerId, postId, action: 'CLAIM_CREATED' |
| Claim Approved | Owner approves claim | claimerId, finderId, action: 'CLAIM_APPROVED' |
| Item Recovered (QR Handshake) | Both parties verify via QR | claimerId, finderId, postId, action: 'ITEM_RECOVERED_VIA_HANDSHAKE' |
| Claim Rejected | Owner denies claim | claimerId, reason, action: 'CLAIM_REJECTED' |

### 3.7 Admin Audit Log Access
Administrators can view the complete blockchain audit trail through:
- **Web Dashboard**: `GET /api/admin/audit-logs` → Displays all claim logs in reverse chronological order
- **Chain Validation**: Admin can trigger `GET /api/claim-logs/validate` to verify the entire chain's integrity at any time
- This provides full transparency and accountability for every item recovery on the platform

---

## 4. AI + Blockchain Working Together
The AI and Blockchain systems complement each other in the full item recovery lifecycle:

```
[Item Lost] → [AI Matching Engine finds a match] → [Claim Request Created]
                                                           ↓
                                              [Blockchain records: CLAIM_CREATED]
                                                           ↓
                                              [Owner reviews & approves]
                                                           ↓
                                              [Blockchain records: CLAIM_APPROVED]
                                                           ↓
                                              [QR Handshake verification]
                                                           ↓
                                              [Blockchain records: ITEM_RECOVERED]
                                                           ↓
                                              [+50 Karma awarded to finder]
                                                           ↓
                                              [Chain is immutable & auditable forever]
```

---
*Prepared for Project Trace — Cloud Computing Evaluation*
