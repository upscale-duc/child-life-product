# S8 widget gallery strings (the names and blurbs iOS shows in "Add Widget" and on the Lock
# Screen picker). iOS draws these before the app ever runs, so they cannot come through the glance
# snapshot: this script adds them to the ARB catalogs (D-012, Vietnamese = Figma source, English =
# engineering draft) and writes ios/widget/Localizable.xcstrings from the ARB values, so ARB stays
# the only place to edit them. Idempotent. Usage: python3 tool/s8_widget_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc):
    S[key] = (vi, en, desc)

s('glanceGalleryBottleName', 'Bú bình', 'Bottle', 'Widget gallery name (W1 small).')
s('glanceGalleryBottleBlurb', 'Ghi lại cữ bình vừa rồi chỉ với một chạm.', 'Log the last bottle again with one tap.', 'Widget gallery description.')
s('glanceGalleryBreastName', 'Bú mẹ', 'Breastfeeding', 'Widget gallery name (W1 small).')
s('glanceGalleryBreastBlurb', 'Bắt đầu, đổi bên và kết thúc cữ bú.', 'Start, switch sides and end a feed.', 'Widget gallery description.')
s('glanceGallerySleepName', 'Giấc ngủ', 'Sleep', 'Widget gallery name (W1 small).')
s('glanceGallerySleepBlurb', 'Bắt đầu ngủ và thức dậy ngay trên màn hình chính.', 'Start sleep and wake up right from the Home Screen.', 'Widget gallery description.')
s('glanceGalleryDiaperName', 'Thay tã', 'Diaper', 'Widget gallery name (W1 small).')
s('glanceGalleryDiaperBlurb', 'Ướt, bẩn hay cả hai — một chạm.', 'Wet, dirty or both — one tap.', 'Widget gallery description.')
s('glanceGalleryQuickName', 'Ghi nhanh', 'Quick log', 'Widget gallery name (W2 medium).')
s('glanceGalleryQuickBlurb', 'Bú bình, bú mẹ, ngủ, thay tã — một chạm.', 'Bottle, breastfeeding, sleep, diaper — one tap.', 'Widget gallery description.')
s('glanceGalleryTodayName', 'Hôm nay', 'Today', 'Widget gallery name (W2 large).')
s('glanceGalleryTodayBlurb', 'Giấc ngủ, ghi nhanh và 3 lần ghi gần nhất.', 'Sleep, quick log and the 3 latest entries.', 'Widget gallery description.')
s('glanceGalleryLockName', 'Child Life', 'Child Life', 'Lock Screen widget name (W3).')
s('glanceGalleryLockBlurb', 'Lần bú, tã và giấc ngủ trên màn hình khoá.', 'Feeds, diapers and sleep on the Lock Screen.', 'Lock Screen widget description.')
s('glanceGalleryLockSleepName', 'Giấc ngủ', 'Sleep', 'Lock Screen widget name (W3 circular).')
s('glanceGalleryLockSleepBlurb', 'Đang ngủ bao lâu, hoặc đã thức bao lâu.', 'How long asleep, or how long awake.', 'Lock Screen widget description.')
s('glanceGalleryLockFeedName', 'Lần bú', 'Last feed', 'Lock Screen widget name (W3 circular).')
s('glanceGalleryLockFeedBlurb', 'Bao lâu từ lần bú gần nhất.', 'Time since the last feed.', 'Lock Screen widget description.')

app = pathlib.Path(__file__).resolve().parent.parent
l10n = app / 'lib' / 'l10n'
arb = {}
for locale, idx in (('vi', 0), ('en', 1)):
    path = l10n / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc) in S.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    arb[locale] = data

# Every glanceGallery* id in the ARB, read back from the catalogs (not from the table above).
keys = sorted(k for k in arb['vi'] if k.startswith('glanceGallery'))
catalog = collections.OrderedDict(sourceLanguage='en', strings=collections.OrderedDict(), version='1.0')
for key in keys:
    catalog['strings'][key] = {
        'extractionState': 'manual',
        'localizations': collections.OrderedDict(
            (locale, {'stringUnit': {'state': 'translated', 'value': arb[locale][key]}})
            for locale in ('en', 'vi')
        ),
    }
out = app / 'ios' / 'widget' / 'Localizable.xcstrings'
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
print(len(keys), 'gallery strings ->', out.relative_to(app))
