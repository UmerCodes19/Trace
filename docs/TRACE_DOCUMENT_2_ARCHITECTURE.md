# DOCUMENT 2 - TRACE SYSTEM ARCHITECTURE & TECH STACK

## 1. Complete Architecture Overview
Trace aik decoupled multi-tier architecture follow karta hai jahan client interface aur server-side computational logic totally isolate hotay hain takay independent scaling possible ho.

Architecture following components par mustamil hai:
*   **Client Side (Frontend)**: Native applications built in Flutter jo dynamic interface present karti hain.
*   **Orchestration Layer (API)**: Express.js based server jo business logic process karta hai.
*   **Persistency Tier (Database)**: Supabase managed relational instance complex queries handle karne ke liye.
*   **Identity Tier**: Firebase Auth system jo cross-platform identity maintain karta hai.
*   **CDN & Storage Node**: Cloudinary node optimize image/video asset deliver karne ke liye.

### Text-Based Architecture Layout
```
[User Handheld Device] 
       | (HTTPS / WebSocket)
[Express Gateway Server]
       |
       +-----> [Supabase PostgreSQL Instance] (Transactional Data)
       +-----> [Firebase Identity SDK] (Token Validation)
       +-----> [Cloudinary API] (Blob Media Objects)
```

---

## 2. Frontend Architecture
Frontend environment Flutter framework use karta hai using the Declarative UI model. Application "Feature-first layered architecture" follow karti hai jo modular development support karti hai.

Key frontend metrics:
*   **Concurrency Model**: Single threaded event loop using asynchronous isolates for heavy vector decoding.
*   **Navigation Model**: Declarative Routing utilizing GoRouter stack framework jo web URL mapping support karta hai.
*   **Networking Engine**: Dio runtime client configuring customized interceptors (Request loggers, global header insertion wrappers).

---

## 3. Backend Architecture
Backend logic Express engine based module drive karti hai executing on Node.js runtime. Hum service-based design pattern use karte hain jahan Controllers routing catch karte hain aur separate Services specific queries run karti hain logic encapsulation maintain karne ke liye.

Key patterns:
*   **Middlewares Stack**: Helmet secure headers protection ke liye, CORS policy protection ke liye, aur express-rate-limit DDoS mitigation ke liye.
*   **Error Boundaries**: Global centralized exception catch wrappers jo server crash prevent karte hain unexpected DB failures par.

---

## 4. State Management System
State management runtime Riverpod architecture utilize karta hai. Traditional Provider ke bajaye Riverpod dynamic auto-dispose attributes offer karta hai jo data state clean up auto process karte hain.

*   **Notifier Framework**: StateNotifiers controllers handle complex logic streams like real-time feeds updates.
*   **Dependency Injection**: Injected services explicitly mockability test cycles improve karti hain during pipeline runs.

---

## 5. Database Structure
Trace Relational normalization strategies employ karta hai storage optimized approach ke sath.

| Table Entity | Type | Purpose |
| :--- | :--- | :--- |
| users | Core Entity | User core profile and dynamic config store karta hai. |
| posts | Event Object | Media refs, geospatial vectors aur statuses contain karti hai. |
| claims | Relational Link | Connects seeker object and finder target for logical handshake. |
| notifications | Stream Queue | Persistent history tracking alerts push history stores. |

User schema JSONB extension support provide karti hai configuration schemas (e.g., 2FA credentials, map markers zoom preference) store karne ke liye context switching simplify karne ke liye.

---

## 6. Authentication Flow
Auth orchestration hybrid token verification utilize karti hai:
1.  User frontend initiate input validation triggers.
2.  Firebase Client verification validation successful verify authentication payload.
3.  JWT ID token returns with temporary signature algorithm signature.
4.  Client app passes JWT Bearer token inside request Authorization headers key.
5.  Express microservice fires `verifyIdToken()` request via server-side Firebase Admin logic.
6.  Validation validated hone par session context load inside req.user property pipeline.

---

## 7. API Structure & Design
Rest API strict predictable HTTP verbs follow karti hai resource modification ke liye:

*   **GET /api/posts**: Parameters basis dynamic query filters execution runtime fetch algorithms list.
*   **POST /api/posts/sync**: Generates atomic record inside database persistence ledger sync operation.
*   **PATCH /api/claims/:id**: Trigger workflow state transitions lock (Pending -> Resolved).

---

## 8. Real-time Communication Systems
Hum dual stream method use karte hain instantaneous response time reach karne ke liye:
*   **Instant Messaging Stream**: Firebase Firestore Realtime hooks listen persistent path modifications ensuring zero lag bubbles update UI redraw frames.
*   **Global Notifications Channel**: Firebase Cloud Messaging (FCM) dispatch push bundles system event notification triggers background thread listener mode triggers notifications directly device tray levels.

---

## 9. Indoor Mapping Engine Architecture
Standard mapping providers (Google maps, OSM) indoor rooms map correctly locate nahi karte. Trace utilizes vector geometry overlay system:
1.  Predefined AutoCAD specific floor plans vector layouts defined into GeoJSON vectors sets.
2.  Vectors coordinates scaled mapping matrix align real-world Lat/Lng bounding box region boundary dimensions inside flutter_map context.
3.  Floor selector active switch trigger filter coordinates load rendering geometry polygons real-time context switches smooth frames operations.

---

## 10. AI Systems Overview
AI detection systems assist human input validation flows:
*   **Automatic Identification**: Gemini generative prompt vectors apply media ingestion objects detecting auto classification labels arrays for efficient index search retrieval indexing tags.
*   **Matching Engine**: Scoring parameters evaluate difference metric between target query objects attribute properties calculating match probability ratios.

---

## 11. Cloud/Storage Systems
Large media handling architecture:
*   Frontend media capture buffer storage.
*   Direct pipe transmission to Cloudinary bucket partition segment system folders.
*   Cloudinary dynamically processes transforms assets applied on retrieval requests (Dynamic scale, low quality delivery optimizations).
*   Postgres database internally stores absolute secure reference URI strings saving storage bandwidth overhead costs on cloud hosting platforms.

---

## 12. Scalability Approach
Ecosystem growth scale requirements management strategy:
*   **Stateless Deployment Engine**: Express instances are fully stateless. Any process nodes increase can happen instantly dynamic load balancers attach behind deployment groups dynamically.
*   **Read/Write Segregation potential**: Read intensive workloads caching ready utilization through local node-cache engines reduces repetitive heavy query load stress levels database tier layer level.

---

## 13. Security Systems
Enterprise-standard protection modules:
*   **Field Encryption**: Critical configuration attributes stored hashing algorithms protect storage values databases compromises.
*   **MFA Lock down**: RFC standard client-side TOTP (Time-based One Time Password) generator engine protects accounts bypassing device stolen breach possibilities.
*   **Environment Integrity**: All secure endpoints protect via `.env` files strict server-side restriction execution runtime never exposed browser client bundles leaks.

---

## 14. Performance Optimization Methods
*   **Asset Lazy Loading Engine**: Scroll views trigger initialization pause controller resources automatically during user non-active visibility viewport frames prevents RAM balloon saturation states.
*   **Response Compression GZIP**: Payload data packages encoded middleware reduces round trip time latency high throughput rates optimized scenarios.
*   **Image Cache Node Management**: Front cached_network_image packages automatically persistent local device cache avoiding recurring redundant network requests downloads saved data costs limits.

---

## 15. Folder/Module Structure Explanation

### Flutter Source Distribution (lib/)
*   `/core`: Core application logic boundary defines, static constant configuration matrix components mappings.
*   `/data`: Logic gateways, models blueprint structural entity mappings, remote REST service repo clients injection constructors.
*   `/presentation`: User Interaction visible modules hierarchy separated visually screens viewports versus modular decoupled widget objects reusing interfaces structures.

### Backend Source Distribution
*   `/routes`: Direct mapping http pathways definition modules.
*   `/services`: High level complex computational sequence handlers abstraction layer separating SQL/Supabase logics APIs routes entry points cleanly.
*   `/utils`: Common library reusable standalone routines formats data transform parsers algorithms library modules.

---
EOF Document
