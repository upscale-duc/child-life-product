# D-143 (owner, 2026-10-30): onboarding no longer says "năm đầu đời" / "chặng đầu" (2), and the
# cross-age screens (profile, family, switcher, invites, setup) call the child by name or "con" /
# "child" instead of "bé" / "baby" (5). Vietnamese "con" only where the reader is a parent: the
# switcher, "theo dõi" and "được giao" lists are read by caregivers and relatives too, so they stay
# neutral there. Infant care screens keep "bé" / "baby".
# Updates existing ids only (values; the description gains a D-143 note). Idempotent.
# Usage: python3 tool/d143_child_terms_strings.py && flutter gen-l10n
import json, collections, pathlib

NOTE = ' D-143: cross-age wording.'
# key: (vi or None to keep, en or None to keep)
S = collections.OrderedDict()
def s(key, vi, en):
    S[key] = (vi, en)

# (2) Onboarding without the first-year framing.
s('welcomeBody', 'Chăm sóc, thấu hiểu và lưu giữ hành trình lớn lên của con.',
  'Care for, understand and keep your child’s story as they grow.')
s('welcomeExplore', 'Bắt đầu cùng con', 'Get started')
s('a11yJourney', 'Hành trình lớn lên của con, từ ngày đầu đến 12 tuổi',
  'Your child’s growing-up journey, from day one to 12')

# (5) Setup: whoever creates the profile may be a grandparent or a nanny (10a), so Vietnamese
# stays neutral there.
s('babyNicknamePlaceholder', 'Tên thân mật', 'Child’s name')
s('babyNicknameRequired', 'Nhập tên thân mật nhé.', 'Give your child a nickname.')
s('tourCreateProfile', 'Tạo hồ sơ', 'Create your child’s profile')
s('whoTitle', None, 'How are you related to the child?')
s('axTrackersSub', 'Chỉ hiện những ô bạn chọn trên Hôm nay. Đổi lại sau trong hồ sơ.', None)

# Switcher (every role reads it): neutral in Vietnamese.
s('babyPickerTitle', 'Chọn hồ sơ', 'Choose a child')
s('babyPickerAdd', 'Thêm hồ sơ', 'Add a child')
s('babyPickerLimit', 'Bạn tạo được tối đa {max} hồ sơ.', 'You can add up to {max} children.')
s('createBabyLimit', 'Mỗi tài khoản tạo được tối đa 3 hồ sơ.', 'Each account can add up to 3 children.')
s('createBabyFailed', 'Chưa tạo được hồ sơ. Kiểm tra mạng rồi thử lại nhé.', None)

# Hồ sơ / Tôi: these rows are a Cùng nuôi's (co-parent), so "con".
s('pfChildren', 'Các con', None)
s('meBabies', 'Hồ sơ các con', 'Your children')
s('meAssigned', None, 'Assigned children')
s('meFollowing', None, 'Children you follow')
s('meStorageShared', 'Dùng chung cho tất cả các con của bạn', 'Shared by all your children')
s('stFootnote', 'Dùng chung cho tất cả các con · ảnh ba và mẹ tải lên đều tính vào đây',
  'Shared by all your children · photos both parents upload count here')
s('bpAdd', 'Thêm hồ sơ', 'Add a child')
s('bpLoadFailed', 'Chưa tải được hồ sơ.', 'Couldn’t load the profile.')
s('rightBabyInfo', None, 'Child info')
s('acDeleteOwnsBabies', 'Cần chuyển chủ hồ sơ của các con trước khi xoá tài khoản.',
  'Transfer your children’s profiles before deleting your account.')
s('acTransferNone', 'Chưa có ai Cùng nuôi tất cả các con.', 'Nobody co-parents all the children yet.')
s('joinFromProfileHint', None, 'Invited to care for another child? Enter the 6-digit code from the invite.')

# Family and invites (written by the child's parents).
s('inviteRelationLabel', None, 'They are your child’s')
s('inviteCustomLabel', 'Là ai với con', 'Relation to your child')
s('memberRelation', 'Là ai với con', 'Relation to the child')
s('joinRoleLine', 'cùng chăm {baby} với vai trò', None)
s('lostAccessShareText', 'Mình không còn xem được hồ sơ trên Child Life nữa. Bạn gửi mình lời mời mới nhé?',
  'I can’t see the profile on Child Life anymore. Could you send me a new invite?')
s('myInviteSheetHint', 'Đồng ý xong, {baby} sẽ có trong danh sách của bạn.', 'Once you accept, {baby} joins your list.')

# Kỷ niệm is cross-age: English only (Vietnamese "bé" reads fine for Tự lưu's young faces).
s('autoSaveStep1', None, 'Pick your child and a few clear photos')
s('autoSavePickBabySub', None, 'Step 1 of 3 · You can add another child later in Settings.')
s('autoSaveBabies', None, 'Children and samples')
s('autoSaveAddBaby', None, 'Add a child')
s('ksVideoPrefilled', None, 'Filled in from the child’s profile')
s('vxNoDobBody', None, 'Parents add it in the child’s profile.')

# (4) The goals replace EN01's interests: reasons that named "điều bạn quan tâm" now fit both.
s('pv2BecauseInterest', 'Theo tuổi của bé và điều bạn chọn', 'Based on your baby’s age and what you picked')
s('hnForBabyBecause', 'Theo điều bạn chọn', 'Based on what you picked')
s('hnForBabyNoInterests', 'Chưa chọn gì', 'Nothing picked yet')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, pair in S.items():
        if key not in data:
            raise SystemExit(f'{key} missing in app_{locale}.arb')
        if pair[idx] is not None:
            data[key] = pair[idx]
        if locale == 'vi':
            meta = data.get('@' + key) or collections.OrderedDict()
            desc = meta.get('description', '')
            if NOTE.strip() not in desc:
                meta['description'] = (desc + NOTE).strip()
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
