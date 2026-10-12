# Invite links (D-059)

"Nhận lời mời" in the invite email opens the web page `https://dev.childlife.app/i/{token}`
(prod: `https://childlife.app/i/{token}`). With the app installed, iOS and Android usually open the
app straight away; otherwise the page shows:

1. **Mở app và nhận lời mời** — a link to the same invite on the other landing domain
   (`child-life-dev-landing.web.app` ↔ `dev.childlife.app`). iOS ignores a Universal Link to the
   domain the page is already on, so the button always points at the other one
   (`inviteOpenUrl` in `firebase/functions/src/env.ts`).
2. **Chưa có app:** install it (store buttons once `storeLinksFor` has them), come back to the page
   or the email and tap the button, or open the app → "Mã mời" and type the code (copy button).

In the app, `/i/{token}` is `InviteLinkScreen`: it waits for a saved account to load, signs in
anonymously ("Vào ngay") if there is none, accepts with the invited relation and the name
"Người thân", selects the baby and opens Hôm nay. A closed invite shows 17; an error shows the
usual 16 screen.

## What makes a link open the app

| Platform | Declared in                                                                   | Served by the landing build                            |
| -------- | ----------------------------------------------------------------------------- | ------------------------------------------------------ |
| iOS      | `tool/ios_flavors.rb` → `applinks:` both landing domains (profile allows `*`) | `/.well-known/apple-app-site-association`, `/i/*` only |
| Android  | `android/app/src/dev/AndroidManifest.xml`, both hosts, `pathPrefix /i/`       | `/.well-known/assetlinks.json` (debug key on dev)      |

Both files come from `apps/landing/scripts/prerender.mjs`; deploy with
`scripts/deploy.sh dev hosting:landing`. iOS reads the association file when the app is installed
(through Apple's CDN), so reinstall after changing it.

## Known limits

- Gmail / Outlook may open the email link in their own browser, where neither the link nor the
  button opens the app. "Mở trong Safari" (or the code) works.
- Someone who once chose "open in Safari" for the domain keeps getting the web page; long-press the
  link → "Mở trong Child Life" resets it.
- Click tracking in Resend must stay off: a redirect through another domain stops the app opening.

## Open for prod

- A second domain for the button (for example `www.childlife.app`), added to `inviteHostsFor`,
  the prod Associated Domains, and the App Links filter.
- App Store / Google Play links in `storeLinksFor` once the app is published.
