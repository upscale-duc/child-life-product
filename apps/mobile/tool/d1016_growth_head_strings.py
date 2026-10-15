# Owner decisions 2026-10-16: head circumference ("Vòng đầu") in Tăng trưởng — the growth form,
# history, record detail, 20d / 20i WHO head-circumference-for-age, the baby profile, Lumi's growth
# draft — and LUMI-16, Lumi asking the amount of a purchase typed without one ("Hết bao nhiêu
# tiền?"). Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/d1016_growth_head_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

HEAD = ' Owner decision 2026-10-16 (head circumference). EN is an engineering draft for owner review.'
AMOUNT = ' LUMI-16, owner decision 2026-10-16 (a purchase without an amount). EN is an engineering draft for owner review.'

s('growthHeadOptional', 'Vòng đầu · tùy chọn', 'Head circumference · optional', '28 head circumference label.' + HEAD)
s('growthHeadRange', 'Vòng đầu từ 20 đến 60 cm.', 'Head circumference from 20 to 60 cm.', 'Head circumference out of range.' + HEAD)
s('headCm', 'vòng đầu {v} cm', 'head {v} cm', 'Head circumference in a measurement line ("vòng đầu 39 cm").' + HEAD, v='String')
s('growthHeadTab', 'Vòng đầu', 'Head', '20d / 20i toggle.' + HEAD)
s('growthMeasureNone', 'Chưa có số đo này. Thêm khi đo cho bé lần tới.', 'Nothing measured yet. Add it at the next measurement.', '20d: the selected measure (e.g. head circumference) has no value yet.' + HEAD)
s('detailHead', 'Vòng đầu', 'Head circumference', '21 record detail row.' + HEAD)
s('bpHead', 'Vòng đầu · {when}', 'Head · {when}', '13 baby profile tile.' + HEAD, when='String')
s('whoBelowHeadNote', 'Vòng đầu của {name} đang nhỏ hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.', '{name}’s head circumference is below the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.', '20d note.' + HEAD, name='String')
s('whoAboveHeadNote', 'Vòng đầu của {name} đang lớn hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.', '{name}’s head circumference is above the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.', '20d note.' + HEAD, name='String')
s('asFieldHead', 'Vòng đầu · tùy chọn', 'Head circumference · optional', 'Lumi growth editor field.' + HEAD)
s('asGapHead', 'Chưa có vòng đầu (cm)', 'No head circumference yet (cm)', 'Lumi inline fix: head circumference missing.' + HEAD)
s('asGapHeadUnsure', 'Vòng đầu {cm} cm có đúng không?', 'Is the head circumference {cm} cm right?', 'Lumi inline fix: head circumference to check.' + HEAD, cm='String')
s('asFixEnterHead', 'Nhập vòng đầu', 'Enter head circumference', 'Lumi inline fix chip: opens the editor.' + HEAD)
s('asFixDropHead', 'Bỏ vòng đầu', 'Remove head circumference', 'Lumi inline fix chip: keep the measurement without it.' + HEAD)
s('asAskAmount', 'Hết bao nhiêu tiền?', 'How much did it cost?', 'Lumi on a typed purchase without an amount, above the amount field.' + AMOUNT)

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        # Never take over another screen's key.
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
