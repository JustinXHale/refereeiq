# PWA / GitHub Pages — design history

## 2026-05-14

### [Update] PDF sources on web open in the browser
- In-app PDFs for bundled laws still use the native viewer on Android; on web, PDFs open in a new tab so users are not blocked by missing plug-in support.

### [Update] Profile photo pickers use memory uploads on all platforms
- Choosing a gallery photo no longer relies on a temp `File` path, so web and mobile share one upload path (`putData`) and previews stay consistent.

### [Update] Push toggle hidden on web
- Push notifications are not wired for the web build yet, so Settings no longer shows a non-functional toggle on browsers.
