# Local-First Architecture: Riverpod & Hive

Baby Corn is currently built with a **local-first** approach. This means the app reads from and writes to a local database (Hive) immediately, ensuring the app works perfectly offline and feels incredibly fast. State management (Riverpod) bridges the gap between this local storage and the UI.

This document outlines how the current architecture works, its tradeoffs, and how to scale it for production later.

---

## How It Works

### 1. Storage: Hive (Local NoSQL Database)
Hive is a lightweight, blazing-fast key-value database written purely in Dart. 
- **Immediate Reads/Writes:** Because Hive stores data in memory and persists to disk asynchronously, reads are instantaneous.
- **Boxes:** Data is partitioned into "Boxes" (e.g., `settingsBox`, `recordsBox`). 
- **JSON Serialization:** We convert Dart models (like `BabyModel` or `RecordModel`) into JSON maps and save them in Hive.

### 2. State Management: Riverpod
Riverpod is the reactive state management layer that sits on top of Hive.
- **Providers (`StateNotifierProvider` / `NotifierProvider`):** These hold the current state in memory for the UI to read.
- **Initialization:** When the app starts, Riverpod reads the initial state synchronously from Hive boxes.
- **Updates:** When a user performs an action (e.g., adding a feeding record), the Riverpod `Notifier`:
  1. Updates the state in memory (triggering immediate UI rebuilds).
  2. Saves the new state back to Hive so it persists across app restarts.

### 3. The Flow
`UI Action` ➔ `Riverpod Provider` (Updates Memory State) ➔ `UI Rebuilds` & `Hive saves to disk`

---

## Tradeoffs of the Current Architecture

### Pros
1. **Zero Latency:** No network requests mean the app is incredibly responsive.
2. **Offline by Default:** Parents can log data anywhere (e.g., in a hospital room with no reception).
3. **Privacy:** Data stays on the device, which is highly desirable for personal health and baby data.
4. **Simple Infrastructure:** No server costs, backend maintenance, or complex authentication flows required initially.

### Cons & Issues
1. **No Cloud Sync:** If a user loses their phone, or uninstalls the app, all data is lost permanently (unless manual backups are implemented).
2. **Multi-device Limitations:** Two parents cannot easily share and view the same baby's data on different phones.
3. **Storage Limits:** While text/JSON data is tiny, if you ever add photos or heavy media, device storage can become a bottleneck.
4. **Migrations:** Changing data models (e.g., adding a new required field to a record) requires careful local data migration logic, as you cannot just update a server schema.

---

## Scaling for Production (The Future)

Eventually, an app like Baby Corn will need cloud sync so parents can share accounts or backup data. Here are the common paths forward:

### Option 1: Firebase (Firestore)
Firebase is the standard path for Flutter apps that want real-time syncing.
- **How it integrates:** You keep Riverpod, but instead of Hive, you use the Firestore SDK. Firestore has "offline persistence" built-in. It writes locally first and syncs to the cloud when online.
- **Pros:** Real-time updates across multiple devices (perfect for two parents tracking the same baby), easy authentication, built-in offline support.
- **Cons:** Vendor lock-in, NoSQL querying limitations, and costs can scale quickly if reads/writes aren't optimized.

### Option 2: Supabase
Supabase is an open-source Firebase alternative built on PostgreSQL.
- **How it integrates:** You can either query Supabase directly, or implement a sync engine where Hive stays the primary local database, and a background isolate syncs JSON payloads up to a Supabase table.
- **Pros:** Relational database (SQL), open-source, powerful edge functions, great Flutter SDK.
- **Cons:** Offline caching isn't as magically seamless as Firestore out-of-the-box; you often have to build a custom queue system for offline writes.

### Option 3: Custom REST/GraphQL API (Node.js, Go, Python)
Building your own backend server.
- **How it integrates:** Hive remains the "Source of Truth" for the UI. You build a Sync Engine that checks timestamps (`updatedAt`) and pushes local changes to your server via API endpoints, while fetching new data from the server.
- **Pros:** Total control over business logic, database choice, and infrastructure. No vendor lock-in.
- **Cons:** Highest maintenance burden. You have to write and host the backend, manage deployments, handle security, and build complex conflict-resolution logic for offline syncing.

### Recommendation for Transition
If you want to move to production soon and prioritize parents sharing an account, **Firebase/Firestore** is the path of least resistance because of its excellent built-in offline persistence cache, meaning the app will still feel "local-first" without you having to manually write sync logic.
