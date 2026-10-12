# Tiện ích tab and the new Chăm sóc (v1.0 improvement 450:6424 / 450:6597 / 450:6873). Vietnamese =
# Figma, English = engineering draft (D-012). Idempotent. Usage: python3 tool/utilities_tab_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

s('tabUtilities', 'Tiện ích', 'Utilities', 'Dock tab replacing Gia đình (450:6597).')
s('utTitle', 'Tiện ích', 'Utilities', 'Tiện ích title.')
s('utForBaby', 'Cho bé', 'For the baby', 'Tiện ích section.')
s('utSpendingMonth', 'Tháng này {amount}', 'This month {amount}', 'Chi tiêu row (full amount).', amount='String')
s('utMySpending', 'Khoản tôi đã chi', 'What I paid', 'Chi tiêu row for someone allowed to record (450:6873).')
s('utMySpendingSub', 'Bạn được phép ghi khoản chi', 'You may record what you paid', 'Row subline (who granted it is not stored).')
s('utMembers', 'Thành viên & chia sẻ', 'Members & sharing', 'Gia đình row.')
s('utMembersCount', '{count} người', pl('1 person', '{count} people'), 'Members row subline.', count='int')
s('utMembersPending', '{count} lời mời đang chờ', pl('1 invite pending', '{count} invites pending'), 'Members row subline, after the count.', count='int')
s('utMembersView', 'Xem thành viên gia đình', 'See family members', 'Members row for caregivers and relatives.')
s('utInvite', 'Mời người thân', 'Invite family', 'Gia đình row (Cùng nuôi).')
s('utInviteSub', 'Ông bà, người chăm cùng theo dõi bé', 'Grandparents and caregivers follow the baby with you', 'Invite row subline.')
s('careNutrition', 'Dinh dưỡng', 'Nutrition', 'Chăm sóc coming-soon tile (450:6424).')
s('careNutritionSub', 'Sữa, vi chất theo giai đoạn', 'Milk and nutrients by stage', 'Tile subline.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
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
