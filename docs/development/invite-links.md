# Invite links (D-059)

"Nhận lời mời" in the invite email opens the app and joins without questions, also right after
installing it from the store.

## How a tap travels

| Where the person is                            | What happens                                                                                                                                                                            |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Phone with the app                             | iOS Universal Link / Android App Link on `childlife.onelink.me` opens the app; the router turns `?deep_link_value=invite&deep_link_sub1={token}` into `/i/{token}` (`oneLinkLocation`). |
| Phone without the app                          | OneLink sends them to the App Store / Play Store. The first open after installing gets the link from AppsFlyer (`startOneLink`, deferred deep link) and goes to `/i/{token}`.           |
| Desktop                                        | `af_web_dp`: the web page `/i/{token}` with the code to type in the app.                                                                                                                |
| Web link `https://dev.childlife.app/i/{token}` | Opens the app too (AASA and `assetlinks.json` from the landing build allow only `/i/*`).                                                                                                |

`/i/{token}` is `InviteLinkScreen`: it waits for a saved account to load, signs in anonymously
("Vào ngay") if there is none, accepts with the invited relation and the name "Người thân", selects
the baby and opens Hôm nay. A closed invite shows 17; an error shows the usual 16 screen.

Until the OneLink template exists the email links the web page `/i/{token}`, which also opens the
installed app.

## One-time setup (owner)

1. **AppsFlyer apps:** add the iOS app (dev bundle `dev.hsba.app`, later `app.childlife`) and the
   Android app (`app.childlife.dev`, later `app.childlife`).
2. **OneLink template** on the subdomain `childlife.onelink.me`:
   - iOS: Universal Links on, team ID `VHFV2HNZGN` for dev; App Store link.
   - Android: App Links on, SHA-256 of the signing key (dev: the debug key, see
     `apps/landing/scripts/prerender.mjs`); Play Store link.
   - Give engineering the template URL (for example `https://childlife.onelink.me/AbCd`). It goes in
     `inviteOneLinks` in `firebase/functions/src/env.ts`; it is not a secret.
3. **Keys for the app build:** copy `apps/mobile/config/appsflyer.example.json` to
   `apps/mobile/config/appsflyer.dev.json` (gitignored) and fill in:
   - `AF_DEV_KEY`: AppsFlyer → App settings → Dev key. Never paste it in chat or commit it.
   - `AF_APPLE_APP_ID`: the numeric App Store ID (iOS only).
4. **Build with the keys:**

   ```bash
   flutter run --flavor dev --dart-define-from-file=config/appsflyer.dev.json
   ```

   A build without the file never starts AppsFlyer; invite links still open the installed app.

## Privacy

AppsFlyer is started with advertising identifiers disabled (no IDFA / GAID, the Android `AD_ID`
permission is removed, no tracking prompt, Apple Search Ads off). The app never gives it a user
id, email or any child data. The invite token is the link's parameter, so AppsFlyer sees it; it is
only good until the invite is accepted, revoked or expires.
