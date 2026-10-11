# v1.0 improvement · Onboarding (368:836) and returning sign-in (368:837). Vietnamese = Figma,
# English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/v1i_onboarding_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc):
    S[key] = (vi, en, desc)

# Existing ids whose copy changes in the v1.0 design (no new id, same meaning).
U = collections.OrderedDict()
def u(key, vi, en):
    U[key] = (vi, en)

u('welcomeTitle', 'Cùng con lớn lên,\nđồng hành từng bước.', 'Grow up together,\nevery step of the way.')
u('welcomeExplore', 'Bắt đầu chặng đầu cùng con', 'Start the first stage together')
u('signInSubtitle', 'Đăng nhập để bắt đầu hành trình cùng con.', 'Sign in to start the journey with your child.')

s('welcomeBody', 'Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời.', 'Care for, understand and keep your child’s journey — starting with the first year.', '01 Chào mừng body (368:998).')
s('journeyFeed', 'Bú bình · 120 ml', 'Bottle · 120 ml', 'Journey illustration card (368:967).')
s('journeyFeedWho', 'Mẹ ghi · 2 phút trước', 'Mum logged · 2 min ago', 'Journey illustration card (368:968).')
s('journeySmile', 'Lần đầu con cười', 'First smile', 'Journey illustration card (368:974).')
s('journeySmileSaved', 'Đã lưu vào Kỷ niệm', 'Saved to Memories', 'Journey illustration card (368:975).')
s('journeyLove', 'Bà nội thương ảnh của Teddy', 'Grandma loved Teddy’s photo', 'Journey illustration card (368:979).')
s('journeyStage1', '0–12 tháng', '0–12 months', 'Journey stage chip.')
s('journeyStage2', '1–3 tuổi', '1–3 years', 'Journey stage chip.')
s('journeyStage3', '3–6 tuổi', '3–6 years', 'Journey stage chip.')
s('journeyStage4', '6–12 tuổi', '6–12 years', 'Journey stage chip.')
s('a11yJourney', 'Hành trình lớn lên của con, từ năm đầu đời đến 12 tuổi', 'Your child’s growing-up journey, from the first year to 12', 'Journey illustration label.')
s('welcomeBackTitle', 'Chào mừng trở lại', 'Welcome back', 'R1 sheet title (368:1274).')
s('welcomeBackBody', 'Đăng nhập để tiếp tục hành trình cùng con.', 'Sign in to continue the journey with your child.', 'R1 sheet body (368:1276).')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, values in U.items():
        if key not in data:
            raise SystemExit(f'{key} is not an existing id')
        data[key] = values[idx]
    for key, (vi, en, desc) in S.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings,', len(U), 'updated')
