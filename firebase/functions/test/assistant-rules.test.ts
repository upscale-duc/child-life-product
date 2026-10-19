import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { parseExtraction } from '../src/assistant-model.js';
import { ruleReadText } from '../src/assistant-rules.js';

// Lumi L2 (D-088 §4.4): the rule reader against every phrase of the Lumi end-to-end cases. The
// scripted fake-model replies there are what a correct model returns under the extraction prompt;
// where the rules read a message, they must read it the same way (or the case is listed below as
// one whose script is deliberately wrong, to test a server backstop).

const zone = 'Asia/Ho_Chi_Minh';
const CASES = resolve(import.meta.dirname, '../../tests/assistant-e2e/cases');
/** Local "HH:mm" on the cases' anchor day (2026-10-15, UTC+7). */
const localAt = (hhmm: string) => new Date(`2026-10-15T${hhmm}:00+07:00`);

/** Cases whose scripted model is wrong on purpose (the backstops' tests), or reads differently. */
const wrongScript = new Set([
  'dev-01-con-dang-ngu', // the v3 model's observation (device bug)
  'dev-02c-dang-cho-bu-side-guess', // the model guessed a side
  'dev-03a-thay-ta-uot', // a "meal" from an old model
  'dev-03b-hut-sua-120',
  'dev-03c-be-nang-5-2kg',
  'br-15-side-guessed-by-model',
  'br-16-end-time-live', // live replies kept as recorded
  'br-17-end-time-in-time-live',
  'sl-19-model-misreads-hour',
  'pd-13-growth-read-as-expense',
  'pd-14-diaper-read-as-observation',
  'pd-15-pump-read-as-bottle',
  'pd-21-model-missed-weight',
  'pd-26-growth-head-read-as-length',
  'ob-06-eats-less-read-as-sleep',
  // The model path itself (provider down, timeout, rejected reply): run with the rules off.
  'ga-09-provider-failure',
  'ga-10-provider-timeout',
  'ga-11-rejected-output',
]);

interface Said {
  id: string;
  text: string;
  at: Date;
  /** L9: `u` = a v9 understanding script (no v8 items to compare). */
  model: { i?: { k: string; f?: Record<string, unknown> }[]; u?: unknown } | null;
}

function phrases(): Said[] {
  const out: Said[] = [];
  for (const file of readdirSync(CASES).filter((f) => f.endsWith('.json'))) {
    const cases = JSON.parse(readFileSync(resolve(CASES, file), 'utf8')).cases as {
      id: string;
      anchor?: string;
      turns: Record<string, unknown>[];
    }[];
    for (const c of cases) {
      let clock = localAt(c.anchor ?? '14:20');
      let first = true;
      c.turns.forEach((t, i) => {
        if (typeof t.say !== 'string') return;
        const at = t.at as string | undefined;
        if (!first || at) {
          clock = !at
            ? new Date(clock.getTime() + 20_000)
            : at.startsWith('+')
              ? new Date(clock.getTime() + Number(at.slice(1)) * 60_000)
              : localAt(at);
        }
        first = false;
        const m = Array.isArray(t.model) ? t.model[0] : t.model;
        out.push({
          id: `${c.id}#${i}`,
          text: t.say,
          at: clock,
          model: (m ?? null) as Said['model'],
        });
      });
    }
  }
  return out;
}

/** The scripted reply as plain values ("diaper|meal" = the first kind). */
function scripted(m: NonNullable<Said['model']>) {
  return (m.i ?? []).map((x) => ({ kind: x.k.split('|')[0], fields: x.f ?? {} }));
}

const zeroish = new Set(['dayOffset', 'endDayOffset']);

describe('rule reader (routine logs) vs the scripted model', () => {
  const all = phrases();
  const read = all.filter((p) => ruleReadText({ text: p.text, zone, anchor: p.at }) !== null);

  it('reads the same as a correct model wherever it reads', () => {
    const diffs: string[] = [];
    for (const p of read) {
      // L9: a turn scripted as a v9 understanding (`u`) has no v8 items to compare; the fake
      // e2e suite checks the rules' reading of those phrases by its outcome instead.
      if (wrongScript.has(p.id.split('#')[0]!) || !p.model || p.model.u) continue;
      const got = ruleReadText({ text: p.text, zone, anchor: p.at })!;
      const want = scripted(p.model);
      if (want.length !== got.intents.length) {
        diffs.push(
          `${p.id} "${p.text}": ${want.length} items scripted, rules ${got.intents.length}`,
        );
        continue;
      }
      want.forEach((w, k) => {
        const g = got.intents[k]!;
        if (g.kind !== w.kind) diffs.push(`${p.id} "${p.text}": kind ${g.kind} ≠ ${w.kind}`);
        const fields = g.fields as Record<string, unknown>;
        const keys = new Set([
          ...Object.keys(w.fields),
          ...Object.keys(fields).filter((key) => fields[key] !== null),
        ]);
        for (const key of keys) {
          let a = fields[key] ?? null;
          let b = w.fields[key] ?? null;
          if (zeroish.has(key)) {
            a ??= 0;
            b ??= 0;
          }
          // The prompt's "milk only when said": an old script may name the default.
          if (key === 'milk' && b === 'breast_milk' && a === null) continue;
          if (a !== b) diffs.push(`${p.id} "${p.text}": ${key} ${String(a)} ≠ ${String(b)}`);
        }
      });
    }
    expect(diffs).toEqual([]);
    // Most routine phrases of the cases are read by the rules (the rest go to the model).
    expect(read.length).toBeGreaterThanOrEqual(60);
  });

  it('every reading is a valid extraction (the worker parses it like a model reply)', () => {
    for (const p of read) {
      const got = ruleReadText({ text: p.text, zone, anchor: p.at })!;
      expect(parseExtraction(JSON.parse(JSON.stringify(got))).ok, p.text).toBe(true);
      for (const i of got.intents) {
        for (const e of i.evidence) {
          // Evidence is the person's own words (the planner checks it against the text).
          expect(p.text.normalize('NFC').includes(e.text), `${p.text} → ${e.text}`).toBe(true);
        }
      }
    }
  });
});

describe('rule reader: the routine phrases of the plan (D-088 §4.4)', () => {
  const at = localAt('14:20');
  const one = (text: string, anchor = at) => {
    const r = ruleReadText({ text, zone, anchor });
    expect(r, text).not.toBeNull();
    expect(r!.intents).toHaveLength(1);
    return r!.intents[0]!;
  };

  it('bottle: ml and a time as said (the server decides morning / evening)', () => {
    expect(one('bé bú 120ml lúc 8h').fields).toMatchObject({
      amountMl: 120,
      time: '08:00',
      dayOffset: 0,
    });
    expect(one('bé bú 120ml lúc 8h sáng').fields.time).toBe('08:00');
    expect(one('tối qua 9h bú bình 150ml').fields).toMatchObject({ time: '21:00', dayOffset: -1 });
    expect(one('be bu 90ml').missingFields).toEqual(['time']);
    expect(one('bú 120ml sữa công thức lúc 13h').fields.milk).toBe('formula');
    expect(one('vừa bú bình 100ml').fields).toMatchObject({ time: '14:20', dayOffset: 0 });
    expect(one('1 tiếng trước bú 90ml').fields.time).toBe('13:20');
  });

  it('breast: minutes and side; a running feed drives the timer', () => {
    expect(one('bú mẹ 15 phút bên trái lúc 13h').fields).toMatchObject({
      durationMin: 15,
      side: 'left',
      time: '13:00',
    });
    expect(one('đang cho bú bên phải').fields).toMatchObject({ phase: 'start', side: 'right' });
    expect(one('bú xong rồi').fields.phase).toBe('stop');
  });

  it('diaper, pump, growth', () => {
    expect(one('thay tã ướt').fields.diaper).toBe('wet');
    expect(one('thay tã ướt').missingFields).toEqual(['time']);
    expect(one('thay bỉm bẩn lúc 10h').fields).toMatchObject({ diaper: 'dirty', time: '10:00' });
    expect(one('hút 100ml').kind).toBe('pump');
    expect(one('hút 100ml').fields.amountMl).toBe(100);
    expect(one('hút sữa 120ml bên trái lúc 10h').fields).toMatchObject({
      amountMl: 120,
      side: 'left',
    });
    expect(one('bé nặng 5,2kg').fields.weightKg).toBe(5.2);
    expect(one('bé nặng 6kg2, dài 62cm').fields).toMatchObject({ weightKg: 6.2, lengthCm: 62 });
    expect(one('vòng đầu 40cm').fields.headCm).toBe(40);
  });

  it('sleep: start, stop, span, length', () => {
    expect(one('bé ngủ lúc 9h').fields).toMatchObject({ phase: 'start', time: '09:00' });
    expect(one('con đang ngủ').fields.phase).toBe('start');
    expect(one('bé dậy rồi').fields.phase).toBe('stop');
    expect(one('dậy lúc 6h').fields).toMatchObject({ phase: 'stop', endTime: '06:00' });
    expect(one('bé ngủ từ 13h đến 14h').fields).toMatchObject({
      time: '13:00',
      endTime: '14:00',
      dayOffset: 0,
      endDayOffset: 0,
    });
    expect(one('bé ngủ từ 9h tối đến 6h sáng').fields).toMatchObject({
      time: '21:00',
      dayOffset: -1,
      endTime: '06:00',
      endDayOffset: 0,
    });
    expect(one('ngủ 2 tiếng').fields.durationMin).toBe(120);
  });

  it('leaves to the model what is not one plain log', () => {
    for (const text of [
      'bé bú bao nhiêu rồi?',
      'à không, 150ml',
      'nhầm, 6h30 mới dậy',
      'mua sữa 500k',
      'thay tã rồi cho bú 90ml lúc 13h',
      'bé bú',
      'bé bú mẹ 100ml',
      'dạo này bé khó ngủ',
      'Bé đang ngủ. Vừa ngủ được 5p rồi',
      'đang ngủ và ngủ cách đây 5p',
      'lúc nãy bé bú 120ml',
      'nhắc mai 9h mua bỉm',
      'baby had 120 ml formula at 1pm',
      'bé uống thuốc hạ sốt 5ml',
      'hôm qua đi khám bé nặng 5kg8',
      'bé bú 120ml lúc 8h và 11h',
      'ờ bé vừa bú bình xong được một trăm hai mươi ml á',
      // Later than now (14:20): last night or a slip — the model decides.
      'bé bú 120ml lúc 16h',
    ]) {
      expect(ruleReadText({ text, zone, anchor: at }), text).toBeNull();
    }
  });
});
