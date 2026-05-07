# Local Development Setup

This guide shows you how to run Firebase Functions locally using the emulator, avoiding the need to deploy after every change.

## One-Time Setup

### 1. Install Firebase Emulator Suite (if not already installed)

```bash
firebase setup:emulators:firestore
firebase setup:emulators:functions
```

### 2. Set up your OpenAI API key for local development

Edit `functions/.env.local` and add your OpenAI API key:

```
OPENAI_API_KEY=sk-proj-your-actual-key-here
```

**Note:** This file is gitignored and won't be committed.

## Running the Emulator

### Start the emulator

```bash
firebase emulators:start
```

This will start:
- Functions at `http://127.0.0.1:5001`
- Firestore at `http://127.0.0.1:8080`
- Auth at `http://127.0.0.1:9099`
- Emulator UI at `http://127.0.0.1:4000`

Your function URLs will be:
```
http://127.0.0.1:5001/refereeiq-69cff/us-central1/incidentAnalyze
http://127.0.0.1:5001/refereeiq-69cff/us-central1/incidentRuling
http://127.0.0.1:5001/refereeiq-69cff/us-central1/chatWithGPT
```

### Point Flutter to the emulator

In `lib/services/openai_service.dart`, change line 7:

```dart
static const bool _useEmulator = true;  // Change from false to true
```

### Make changes and test

1. Edit files in `functions/` (e.g., `functions/handlers/incident.js`)
2. Save the file
3. The emulator automatically reloads the function
4. Test immediately in your Flutter app - no deployment needed!

### View logs

The emulator shows all logs in the terminal where you ran `firebase emulators:start`.

## Switching Back to Production

1. Stop the emulator (Ctrl+C)
2. In `lib/services/openai_service.dart`, change:
   ```dart
   static const bool _useEmulator = false;
   ```
3. Your app now points back to deployed production functions

## When to Deploy

You only need to deploy when:
- You want to test with production data
- You're ready to release changes to users
- You've finished a feature and want it live

```bash
firebase deploy --only functions
```

## Troubleshooting

**"Cannot find module" errors:**
```bash
cd functions
npm install
```

**Functions not updating:**
- Stop the emulator (Ctrl+C)
- Restart: `firebase emulators:start`

**Auth errors in emulator:**
- The emulator uses mock auth tokens
- Real Firebase Auth tokens work too, but you can also use the emulator's auth UI

**Firestore data:**
- Emulator starts with empty Firestore
- You can import/export data using the Emulator UI at http://127.0.0.1:4000
