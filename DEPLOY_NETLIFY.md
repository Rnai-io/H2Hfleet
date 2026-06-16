# Deploy H2HFleet (Flutter Web) to Netlify

The app lives in `/h2hfleet`. Netlify's build image has no Flutter SDK, so
`netlify.toml` (at repo root) installs a pinned Flutter and runs `flutter build web`.

## One-time setup (Netlify dashboard)

1. Go to your team → **Add new project → Import an existing project**
   (https://app.netlify.com/teams/rnai-io/projects)
2. Connect **GitHub** → pick repo **Rnai-io/H2Hfleet**.
3. Netlify auto-detects `netlify.toml`, so the build settings are already filled:
   - **Base directory:** `h2hfleet`
   - **Build command:** (from netlify.toml — installs Flutter, then `flutter build web`)
   - **Publish directory:** `h2hfleet/build/web`
   Leave them as-is.
4. **No environment variables are required.** Gemini/OpenAI keys are entered by the
   user in-app (Settings → AI Settings); the Supabase `anonKey` is a public key
   protected by Row Level Security.
5. Click **Deploy**. First build takes ~3–6 min (Flutter clone + build). Later builds
   are similar unless Netlify caches the SDK.

## Continuous deploy

After this, every `git push` to `main` triggers a new Netlify build automatically.

## Custom domain (optional)

Project → **Domain management → Add domain** → follow DNS instructions. SSL is free/auto.

## Notes & gotchas

- **Flutter version** is pinned in `netlify.toml` → `FLUTTER_VERSION = "3.38.4"`
  (must satisfy `pubspec.lock`: flutter ≥ 3.38.4 / dart ≥ 3.11). Bump it there to upgrade.
- **Routing** is hash-based (`/#/...`) so it works without server rewrites, but a SPA
  redirect (`/* → /index.html 200`) is included so refresh/deep-links keep working.
- **Supabase**: make sure **RLS is enabled** on every table (the anon key is public).
- This Netlify project is independent of the GitHub Pages demo
  (`rnai-io.github.io/H2Hfleet/demo.html`) — they don't interfere.

## If the build fails

- `flutter: tag not found` → the pinned `FLUTTER_VERSION` tag doesn't exist; set it to
  a real released version (see https://docs.flutter.dev/release/archive).
- Icon tree-shaking error → already mitigated with `--no-tree-shake-icons`.
- White screen after deploy → check the browser console; usually a base-href issue
  (we build with the default `/`, correct for a root-domain Netlify site).
