# Email: Resend + the childlife.app domain (D-054)

Every email Child Life sends goes through [Resend](https://resend.com) from
`Child Life <hello@childlife.app>`. The domain's DNS stays at GoDaddy, and replies go to the GoDaddy
mailbox `hello@childlife.app`. D-054 replaces AWS SES (D-020).

## What is sent

| Kind | Templates | Path |
| --- | --- | --- |
| Invite (Figma 14e) | `invite` | `mail/` queue → `deliverQueuedMail` (retried every 15 min) |
| Account / service (S11, S15, portal v1.0) | `storageRequestAck`, `storageRequestStaff`, `supportAck`, `supportStaff`, `babyDeleted`, `accountDeleted`, `ownershipOffer`, `exportReady`, `supportReply`, `storageGranted`, `storageDeclined`, `staffInvite`, `ownershipStaffRequest` | `mail/` queue |
| Sign-in | `verifyEmail` (08), `resetPassword` (09), `signInLink` (portal "Link qua email") | callable `sendAuthEmail`, sent at once and never stored |

- **Copy and layout** live in `firebase/functions/src/mail-templates.ts`: one branded layout in
  vi and en, with an HTML and a plain-text part.
- **Unsubscribe:** only the invite carries the unsubscribe link and `List-Unsubscribe` header.
  Service and sign-in mail is transactional.
- **Rate limit:** sign-in mail is limited to one per minute and five per day for each kind and address
  (`authMailLimits/{hash}`). The limit is checked before the account is looked up, so the answer
  never reveals whether an address has an account.
- **Fallback:** without the Resend key the callable answers `unavailable / no-provider`. The app
  (and the portal) then fall back to Firebase Auth's own mail.

To preview every template locally, run this from `firebase/functions`:

```bash
MAIL_PREVIEW_DIR=/tmp/mail-preview pnpm exec vitest run test/mail-templates.test.ts
```

Then open `/tmp/mail-preview/index.html`.

## One-time setup (owner)

1. **Resend account:** sign up at resend.com.
2. **Add the domain:** in Resend → Domains → Add domain, enter `childlife.app`. A region close to
   Vietnam is fine (for example Tokyo, `ap-northeast-1`).
3. **GoDaddy DNS** (My Products → childlife.app → DNS → Add record): add exactly the records Resend
   shows. GoDaddy wants the host part only (`send`, not `send.childlife.app`). They are usually:
   - `MX` · host `send` · `feedback-smtp.<region>.amazonses.com` · priority 10
   - `TXT` · host `send` · `v=spf1 include:amazonses.com ~all`
   - `TXT` · host `resend._domainkey` · the DKIM value (`p=…`) Resend gives
   - recommended: `TXT` · host `_dmarc` · `v=DMARC1; p=none; rua=mailto:hello@childlife.app`

   Leave the root `@` MX and SPF records alone. They belong to the GoDaddy mailbox, which keeps
   receiving mail (and replies).
4. **Verify:** press Verify in Resend. DNS can take from a few minutes to a few hours.
5. **API key:** Resend → API Keys → Create, with permission "Sending access" for `childlife.app`
   only. Never paste it in chat or commit it; if it leaks, revoke it in Resend and make a new one.
6. **Store the key as a Firebase secret** (the command asks for the value, which is not echoed):

   ```bash
   firebase functions:secrets:set RESEND_API_KEY --project child-life-dev
   ```

   Do the same with `--project child-life-prod` when prod is approved. The value `unset` means
   "not configured": mail then waits in `mail/` with status `waiting-provider`.
7. **Deploy the mail functions:**

   ```bash
   scripts/deploy.sh dev "functions:deliverQueuedMail,functions:retryQueuedMail,functions:sendAuthEmail"
   ```

   Mail that queued while there was no provider goes out within 15 minutes.

Optional parameters, set in `firebase/functions/.env.<project>`:

- `MAIL_FROM`, default `Child Life <hello@childlife.app>`
- `MAIL_REPLY_TO`, default `hello@childlife.app`

## Checking it works

- **Invite:** in the app, Gia đình → Mời → Email → send to your own address. The mail arrives from
  hello@childlife.app, and replying goes to the GoDaddy mailbox.
- **Password reset:** sign out → Email → "Quên mật khẩu" → the branded "Đặt lại mật khẩu Child Life" mail.
- **Delivery:** the Resend dashboard (Emails) lists each send. Logs keep the queue id and status
  only, never the address or content.
