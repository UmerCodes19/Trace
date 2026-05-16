# Local Development & Emulator Testing

Follow these steps to test the new AI matching features on your local machine using an Android emulator or iOS simulator without affecting the production site.

## 1. Start the Local Backend

1. Open a terminal in the `backend` directory.
2. Ensure dependencies are installed:
   ```bash
   npm install
   ```
3. Start the server:
   ```bash
   node index.js
   ```
   The server should now be running on `http://localhost:3000`.

## 2. Connect the Flutter App

To point your app to the local server instead of the live site:

1. Open the `.env` file in the root of your Flutter project (`f:/lostfound_android/.env`).
2. Update the `VERCEL_URL` (or the variable used for the base API URL):
   - **Android Emulator**: Use `http://10.0.2.2:3000/api`
   - **iOS Simulator**: Use `http://localhost:3000/api`
   - **Physical Device**: Use `http://<YOUR_LOCAL_IP>:3000/api` (e.g., `http://192.168.1.10:3000/api`)

3. **Restart the Flutter app** (fully stop and run again) to apply the `.env` changes.

## 3. Test AI Matching via CLI

You can test the AI logic directly from your terminal to see the JSON results:

1. In the `backend` folder, run:
   ```bash
   node scripts/test_match.js <POST_ID>
   ```
   *Replace `<POST_ID>` with an actual UUID from your Supabase `posts` table.*

## 4. Troubleshooting

- **Connection Refused**: Ensure your backend is actually running and the port (3000) matches what you put in the `.env`.
- **Firebase/Supabase Errors**: The local backend uses the same Supabase/Firebase credentials as production, so ensure your `.env` in the `backend` folder is correctly populated.
- **Emulator Network**: Android emulators use `10.0.2.2` as a bridge to the host machine's `localhost`.
