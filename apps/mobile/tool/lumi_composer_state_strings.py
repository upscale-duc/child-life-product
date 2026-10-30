"""L8 (lumi-plan §11.3 #5): the composer's state line while a question waits. Run from apps/mobile."""
VI = '''  "asComposerAnswering": "Đang trả lời: {question}",
  "@asComposerAnswering": {
    "description": "Line above the Lumi composer while my own task waits on a question: what I type answers it. {question} is Lumi's question as shown in the thread (e.g. \\"Bé bú lúc mấy giờ?\\"). L8 lumi-plan §11.3 #5. EN is an engineering draft for owner review.",
    "placeholders": {
      "question": {
        "type": "String"
      }
    }
  },
  "asComposerDropQuestion": "Bỏ câu hỏi này",
  "@asComposerDropQuestion": {
    "description": "Screen-reader label of the × on the composer's \\"Đang trả lời\\" line: cancels that task, so the next message is read as a new one. L8 lumi-plan §11.3 #5."
  },
'''
EN = '''  "asComposerAnswering": "Replying to: {question}",
  "asComposerDropQuestion": "Drop this question",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asSend": "Gửi",\n'),
    ('lib/l10n/app_en.arb', EN, '  "asSend": "Send",\n'),
]:
    s = open(path, encoding='utf-8').read()
    if '"asComposerAnswering"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
