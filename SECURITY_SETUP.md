# Security rollout

## Authentication

1. Firebase Console → Authentication → Sign-in method: enable **Google**.
2. Disable **Email/Password**, anonymous, and every other provider.
3. Android: add the release SHA-1 and SHA-256 fingerprints in Firebase project settings, then download a fresh `google-services.json` if Firebase changes it.
4. iOS: add the reversed client ID from `GoogleService-Info.plist` as a URL scheme.

Google issues the identity credential and Firebase rejects an account whose `emailVerified` claim is not true. Realtime Database rules additionally require the Google provider and verified-email claim.

## App Check / abuse protection

1. Firebase Console → App Check: register Android with **Play Integrity**, Apple with **App Attest** (DeviceCheck fallback), and Web with **reCAPTCHA v3**.
2. Run web builds with the public reCAPTCHA key, for example:
   `flutter build web --dart-define=RECAPTCHA_V3_SITE_KEY=your-public-site-key`
3. Release this updated client. In App Check metrics, confirm legitimate traffic is receiving valid tokens.
4. Turn on enforcement for **Authentication**, **Realtime Database**, and **Cloud Storage** in that order.
5. Deploy access rules: `firebase deploy --only database,storage`.

App Check is the DDoS/automated-abuse gate: it blocks requests that do not originate from an attested app. The storage rules also limit uploads to images, authenticated user-owned paths, and 5–10 MB payloads.

## Important

The current client-side pairing operation writes two user profiles. For a high-assurance production release, move pairing to a callable Cloud Function so the server can validate both accounts and the invitation atomically. The supplied rules preserve current pairing behavior while restricting all other access.
