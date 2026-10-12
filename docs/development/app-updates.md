# App updates (D-061)

Hệ thống › **Cập nhật ứng dụng** on the staff portal decides, per platform, which app versions
may run and what the app says about a new one. Publishing writes `publicConfig/appUpdate`; apps
pick it up at their next launch (and live while open).

| The phone has               | It shows                                                                 |
| --------------------------- | ------------------------------------------------------------------------ |
| A version below **minimum** | UP1 "Cần cập nhật để tiếp tục" instead of the app, until updated         |
| A version below **latest**  | UP2 "Child Life có bản mới" on Hôm nay; again after "Để sau" days        |
| Just updated to the release | UP5 "Đã cập nhật 1.2.0" on Hôm nay → "Xem" opens the pages (UP3/UP4)     |
| Anything                    | UP6 Tôi · "Phiên bản 1.0.3", "Có bản mới 1.2.0" + "Cập nhật" when behind |

Nothing is ever blocked without a published config, when the phone cannot read its own version,
or when the minimum is above what the store offers (the portal refuses that anyway).

## Releasing a version

1. Ship the build to the store and wait until it is live (App Store review, Play rollout).
2. Portal › Cập nhật ứng dụng: set **Bản mới nhất trên store** for that platform and the store
   link (App Store page, or TestFlight / Firebase App Distribution while testing).
3. Optional "Có gì mới": the version, a one-line summary, up to 4 highlight rows (icon, colour,
   title, short text) and up to 5 pages (picture, title, text, "Tìm ở đâu"), Vietnamese and
   English. Pictures are uploaded on the page; they are re-encoded to WebP and public.
4. **Xuất bản…**, write the reason, publish.

## Forcing an update

Raise **Bản thấp nhất được dùng** only when older versions are unsafe (a sync or security fix):
every phone below it stops at UP1 until it updates, offline included. The confirm dialog and
the platform panel show the effect in red, and the audit entry records the raised minimum.
Lower it again to undo; phones recover at their next launch.

## Who may

Viewing needs Hệ thống · Xem (Vận hành, Kỹ sư, Admin, Owner); publishing and uploading pictures
need Hệ thống · Sửa (Kỹ sư, Admin, Owner).

## Versions

The app compares `CFBundleShortVersionString` (iOS) / `versionName` (Android), the `x.y.z` part of
`version:` in `apps/mobile/pubspec.yaml`. Bump it for every store release. The build number does
not count; outside prod, Tôi shows it as "1.0.3 (86) · dev" so testers can tell builds apart.
