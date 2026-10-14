# Apple Watch copy (Figma page "Apple Watch" 464:18, W01–W14; plan docs/product/apple-watch-plan.md).
# The watch app runs without Flutter, and before the phone ever sends a snapshot, so its strings
# cannot travel in the glance snapshot: this script adds them to the ARB catalogs (D-012,
# Vietnamese = Figma source, English = engineering draft) and writes ios/watch/Localizable.xcstrings
# from the ARB values, so ARB stays the only place to edit them. Placeholders are `{x}`, filled in
# Swift (WatchText.t). Idempotent. Usage: python3 tool/watch_strings.py
import json, collections, pathlib, re

S = collections.OrderedDict()
def s(key, vi, en, desc):
    S[key] = (vi, en, desc)

# W01 Hôm nay (tiles) · W11 Ban đêm
s('watchTileBottle', 'Bú bình', 'Bottle', 'Watch W01 tile title.')
s('watchTileBreast', 'Bú mẹ', 'Breast', 'Watch W01 tile title.')
s('watchTileSleep', 'Ngủ', 'Sleep', 'Watch W01 tile title.')
s('watchTileDiaper', 'Tã', 'Diaper', 'Watch W01 tile title.')
s('watchTilePump', 'Hút sữa', 'Pumping', 'Watch W01 tile title.')
s('watchTileReminder', 'Nhắc', 'Reminder', 'Watch W01 tile title.')
s('watchSinceFeed', 'từ cữ trước', 'since last feed', 'Watch W01 tile caption under the time since the last feed.')
s('watchSinceLast', 'từ lần trước', 'since last time', 'Watch W01 tile caption (diaper, pump).')
s('watchSleeping', 'đang ngủ', 'asleep', 'Watch W01 sleep tile caption while a sleep runs.')
s('watchAwake', 'đã thức', 'awake', 'Watch W01 sleep tile caption after waking (engineering, not drawn).')
s('watchFeedReminder', 'nhắc bú', 'feed reminder', 'Watch W01 reminder tile caption.')
s('watchNoneYet', 'chưa ghi', 'none yet', 'Watch W01 tile caption when nothing is logged (engineering, G-093).')
s('watchAgo', '{t} trước', '{t} ago', 'Watch W11 night list: time since the last entry.')
s('watchChooseBabyRow', 'Chọn bé', 'Choose baby', 'Watch W01 last row, opens W12.')
# W02 Bú bình
s('watchCrownHint', 'ml · xoay núm để chỉnh', 'ml · turn the crown to adjust', 'Watch W02 under the amount.')
s('watchSave', 'Lưu', 'Save', 'Watch W02 / W08 primary button.')
# W03 Bú mẹ
s('watchBreastStartHint', 'Bắt đầu bên nào?', 'Which side first?', 'Watch breast start screen (engineering, G-094).')
s('watchSideLeft', 'Trái', 'Left', 'Watch W03 side card.')
s('watchSideRight', 'Phải', 'Right', 'Watch W03 side card.')
s('watchSuggested', 'gợi ý', 'suggested', 'Watch breast start: the side opposite the last feed (engineering).')
s('watchBreastTotalLeft', 'Tổng {t} · đang bú bên trái', 'Total {t} · on the left', 'Watch W03 caption.')
s('watchBreastTotalRight', 'Tổng {t} · đang bú bên phải', 'Total {t} · on the right', 'Watch W03 caption.')
s('watchSwitchSide', 'Đổi bên', 'Switch side', 'Watch W03 button.')
s('watchStop', 'Dừng', 'Stop', 'Watch W03 button.')
# W04 Ngủ
s('watchSleepSince', 'từ {time}', 'since {time}', 'Watch W04 under the sleep timer.')
s('watchWokeUp', 'Bé đã dậy', 'Baby woke up', 'Watch W04 button.')
# W05 Thay tã
s('watchDiaperTitle', 'Thay tã', 'Diaper change', 'Watch W05 title.')
s('watchDiaperWet', 'Ướt', 'Wet', 'Watch W05 button.')
s('watchDiaperDirty', 'Bẩn', 'Dirty', 'Watch W05 button.')
s('watchDiaperBoth', 'Cả hai', 'Both', 'Watch W05 button.')
# W06 Đã lưu
s('watchLoggedWet', 'Đã ghi tã ướt', 'Wet diaper logged', 'Watch W06 title.')
s('watchLoggedDirty', 'Đã ghi tã bẩn', 'Dirty diaper logged', 'Watch W06 title (engineering).')
s('watchLoggedBoth', 'Đã ghi tã ướt và bẩn', 'Wet and dirty diaper logged', 'Watch W06 title (engineering).')
s('watchLoggedBottle', 'Đã ghi bú bình {ml} ml', '{ml} ml bottle logged', 'Watch W06 title (engineering).')
s('watchLoggedBreast', 'Đã ghi cữ bú mẹ', 'Breastfeed logged', 'Watch W06 title (engineering).')
s('watchLoggedSleep', 'Đã ghi giấc ngủ', 'Sleep logged', 'Watch W06 title (engineering).')
s('watchLoggedBy', '{time} · {name} ghi', '{time} · logged by {name}', 'Watch W06 line under the title (R-022).')
s('watchUndo', 'Hoàn tác', 'Undo', 'Watch W06 button.')
s('watchFailed', 'Chưa lưu được. Thử lại sau.', "Couldn't save. Try again later.", 'Watch save refused (engineering, G-097).')
# W12 Chọn bé
s('watchChooseBaby', 'Chọn bé', 'Choose baby', 'Watch W12 title.')
s('watchOneBabyNote', 'Đổi sang bé khác trên iPhone.', 'Switch to another baby on the iPhone.', 'Watch W12 note while the phone sends one baby (engineering).')
# W13 Chưa có mạng
s('watchOffline', 'Đã lưu trên đồng hồ. Sẽ gửi lên khi có mạng.', "Saved on the watch. It will be sent once you're online.", 'Watch W13 banner.')
s('watchPending', '{n} lần ghi chờ gửi', '{n} entries waiting to send', 'Watch W13 row.')
# Linking (G-092) and empty states (G-093)
s('watchLinkTitle', 'Kết nối iPhone', 'Connect your iPhone', 'Watch first run, not linked yet (engineering, G-092).')
s('watchLinkBody', 'Mở Child Life trên iPhone và đăng nhập, đồng hồ sẽ tự kết nối.', 'Open Child Life on your iPhone and sign in; the watch connects by itself.', 'Watch first run body (engineering, G-092).')
s('watchCannotLog', 'Bạn chưa có bé nào để ghi trên đồng hồ.', "There's no baby you can log for on the watch.", 'Watch empty state for a member who cannot log (engineering, G-093).')
s('watchDemo', 'Xem thử', 'Try it out', 'Watch first run, debug builds only: opens sample data.')

PLACEHOLDER = re.compile(r'\{(\w+)\}')

app = pathlib.Path(__file__).resolve().parent.parent
l10n = app / 'lib' / 'l10n'
arb = {}
for locale, idx in (('vi', 0), ('en', 1)):
    path = l10n / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    # watch* ids no longer in the table above are removed, so the catalogs never keep dead copy.
    for key in [k for k in data if k.lstrip('@').startswith('watch') and k.lstrip('@') not in S]:
        del data[key]
    for key, (vi, en, desc) in S.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            names = PLACEHOLDER.findall(vi)
            if names:
                meta['placeholders'] = collections.OrderedDict((n, {'type': 'String'}) for n in names)
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    arb[locale] = data

# Every watch* id in the ARB, read back from the catalogs (not from the table above).
keys = sorted(k for k in arb['vi'] if k.startswith('watch'))
catalog = collections.OrderedDict(sourceLanguage='en', strings=collections.OrderedDict(), version='1.0')
for key in keys:
    catalog['strings'][key] = {
        'extractionState': 'manual',
        'localizations': collections.OrderedDict(
            (locale, {'stringUnit': {'state': 'translated', 'value': arb[locale][key]}})
            for locale in ('en', 'vi')
        ),
    }
out = app / 'ios' / 'watch' / 'Localizable.xcstrings'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
print(len(keys), 'watch strings ->', out.relative_to(app))
