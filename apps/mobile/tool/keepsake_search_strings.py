# Thiệp · Video: search and saved templates (owner, 2026-10-30: "có search và bookmark"), and
# "Cần 5 ảnh" when a template needs an exact number (was "Cần 5–5 ảnh"). Vietnamese is the source;
# English is an engineering draft for owner review (D-012). Idempotent.
# Usage: python3 tool/keepsake_search_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
S['ksSearchHint'] = ('Tìm mẫu theo tên hoặc dịp', 'Search by name or occasion',
                     'Thiệp · Video search field placeholder.', {})
S['ksSavedChip'] = ('Đã lưu', 'Saved', 'Thiệp · Video filter chip: the templates this person saved.', {})
S['ksSaveTemplate'] = ('Lưu mẫu {name}', 'Save {name}',
                       'Screen reader label of the bookmark under a template; {name} is the template name.',
                       {'name': 'String'})
S['ksUnsaveTemplate'] = ('Bỏ lưu mẫu {name}', 'Remove {name} from Saved',
                         'Screen reader label of a filled bookmark; {name} is the template name.',
                         {'name': 'String'})
S['ksSavedToast'] = ('Đã lưu mẫu, xem lại ở mục Đã lưu nhé', 'Saved. You’ll find it under Saved.',
                     'Toast after saving a template.', {})
S['ksUnsavedToast'] = ('Đã bỏ lưu mẫu', 'Removed from Saved', 'Toast after unsaving a template.', {})
S['ksSavedEmptyTitle'] = ('Chưa lưu mẫu nào', 'No saved templates yet',
                          'Đã lưu chip with nothing saved (on this page).', {})
S['ksSavedEmptyBody'] = ('Chạm biểu tượng lưu dưới mẫu bạn thích để tìm lại nhanh ở đây.',
                         'Tap the bookmark under a template you like to find it here later.',
                         'Đã lưu chip with nothing saved.', {})
S['ksSearchEmptyTitle'] = ('Không có mẫu nào khớp “{query}”', 'No templates match “{query}”',
                           'Search with no result; {query} is what was typed.', {'query': 'String'})
S['ksSearchEmptyBody'] = ('Bạn thử từ khác, hoặc xoá tìm kiếm để xem tất cả mẫu nhé.',
                          'Try another word, or clear the search to see every template.',
                          'Search with no result.', {})
S['ksVideoNeedsExact'] = ('Cần {n} ảnh', '{n, plural, =1{Needs 1 photo} other{Needs {n} photos}}',
                          'Template list: a template that needs exactly {n} photos (instead of "Cần 5–5 ảnh").',
                          {'n': 'int'})

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
            m = collections.OrderedDict(description=desc)
            if ph:
                m['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = m
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
