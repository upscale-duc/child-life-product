import { describe, expect, it } from 'vitest';
import {
  understandingSchema,
  unknownTime,
  type Understanding,
  type UnderstandingEvent,
} from '@child-life/contracts';
import {
  buildUnderstandRequest,
  fakeModelGateway,
  fromLegacyExtraction,
  parseUnderstanding,
  understandingExamples,
  understandingJsonSchema,
  type ExtractInput,
} from '../src/assistant-model.js';
import { resolveUnderstanding, targetOf } from '../src/assistant-understanding.js';
import type { PreviousTurn } from '../src/assistant-text.js';

// Lumi L9 (P-169): understanding v1 — the request, the strict schema, the legacy translation and
// the ONE resolver of time and precedence, on the owner's sentences (lumi-plan §2, §11, §12).
// Synthetic text only; no network.

const ZONE = 'Asia/Ho_Chi_Minh';
/** 16:57 in Vietnam on 2026-10-19 (the §12 report). */
const AT = new Date('2026-10-19T09:57:00Z');
const local = (iso: string | null | undefined) =>
  iso
    ? new Intl.DateTimeFormat('en-GB', {
        timeZone: ZONE,
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      }).format(new Date(iso))
    : null;

const ev = (
  kind: UnderstandingEvent['kind'],
  status: UnderstandingEvent['status'],
  x: Partial<Pick<UnderstandingEvent, 'started' | 'ended' | 'durationMin' | 'fields'>> = {},
): UnderstandingEvent => ({
  kind,
  status,
  started: x.started ?? null,
  ended: x.ended ?? null,
  durationMin: x.durationMin ?? null,
  fields: x.fields ?? {},
  evidence: [],
  uncertainFields: [],
});
const ago = (minutes: number) => ({ how: 'ago' as const, minutes, hhmm: null, dayOffset: null });
const clock = (hhmm: string, dayOffset = 0) => ({
  how: 'clock' as const,
  minutes: null,
  hhmm,
  dayOffset,
});
const u = (
  act: Understanding['act'],
  events: UnderstandingEvent[],
  more: Partial<Understanding> = {},
): Understanding => ({
  act,
  target: null,
  confidence: 0.9,
  events,
  reads: [],
  ask: null,
  care: null,
  healthSigns: [],
  ...more,
});
const previous = (drafts: PreviousTurn['drafts']): PreviousTurn => ({
  taskId: 't0',
  text: '',
  drafts,
});
const waitingSleep: PreviousTurn = previous([
  {
    id: 'd1',
    taskId: 't0',
    state: 'draft',
    payload: {
      kind: 'sleep',
      startedAt: '2026-10-19T09:30:00Z',
      endedAt: '2026-10-19T09:40:00Z',
      durationMin: 10,
      linked: null,
    },
    recordLink: null,
  },
]);

const resolve = (
  understanding: Understanding,
  text: string,
  more: Partial<Parameters<typeof resolveUnderstanding>[0]> = {},
) =>
  resolveUnderstanding({
    u: understanding,
    text,
    anchor: AT,
    zone: ZONE,
    answers: new Map(),
    previous: null,
    ...more,
  });

describe('understanding v1: time semantics (§12.3 #2)', () => {
  it('"Bé đã ngủ được 10p trước đó và vẫn đang ngủ": ongoing, started ago 10 → a timer from 16:47, no span', () => {
    const r = resolve(
      u('log', [ev('sleep', 'ongoing', { started: ago(10) })]),
      'Bé đã ngủ được 10p trước đó và vẫn đang ngủ',
      { previous: waitingSleep },
    );
    expect(r.act).toBe('log');
    const i = r.ext.intents[0]!;
    expect(i.resolved).toMatchObject({ at: null, endAt: null, timer: { action: 'start' } });
    expect(local(i.resolved!.timer!.at)).toBe('16:47');
    expect(i.correctsPrevious).toBe(false);
  });

  it('"Bé đang ngủ. Vừa ngủ được 5p rồi" / "ngủ cách đây 5p": the timer from 5 minutes ago', () => {
    for (const text of ['Bé đang ngủ. Vừa ngủ được 5p rồi', 'Đang ngủ và ngủ cách đây 5p']) {
      const r = resolve(u('log', [ev('sleep', 'ongoing', { started: ago(5) })]), text);
      expect(local(r.ext.intents[0]!.resolved!.timer!.at)).toBe('16:52');
      expect(r.ext.intents[0]!.resolved!.ambiguous).toEqual([]);
    }
  });

  it('"bé ngủ từ 11h20" at 11:26: ongoing at a written clock → the timer from 11:20 today', () => {
    const r = resolve(
      u('log', [ev('sleep', 'ongoing', { started: clock('11:20') })]),
      'bé ngủ từ 11h20',
      {
        anchor: new Date('2026-10-19T04:26:00Z'),
      },
    );
    expect(local(r.ext.intents[0]!.resolved!.timer!.at)).toBe('11:20');
  });

  it('"Bé đã bú bình 180ml": finished with no time → now (no question)', () => {
    const r = resolve(
      u('log', [ev('bottle', 'finished', { started: unknownTime, fields: { amountMl: 180 } })]),
      'Bé đã bú bình 180ml',
    );
    expect(local(r.ext.intents[0]!.resolved!.at)).toBe('16:57');
    expect(r.ext.intents[0]!.fields.amountMl).toBe(180);
  });

  it('in a batch where another log has a time, a log without one is left to fill, not now', () => {
    const r = resolve(
      u('log', [
        ev('bottle', 'finished', { started: clock('07:00'), fields: { amountMl: 100 } }),
        ev('bottle', 'finished', { started: unknownTime, fields: { amountMl: 60 } }),
      ]),
      'sáng nay 7h bú 100ml rồi bú thêm 60ml',
    );
    expect(local(r.ext.intents[0]!.resolved!.at)).toBe('07:00');
    expect(r.ext.intents[1]!.resolved!.at).toBeNull();
  });

  it('"vừa bú mẹ 20 phút": ended now with a length → started 20 minutes ago (derived)', () => {
    const r = resolve(
      u('log', [ev('breast', 'finished', { ended: ago(0), durationMin: 20 })]),
      'vừa bú mẹ 20 phút',
    );
    expect(r.ext.intents[0]!.resolved).toMatchObject({ derived: 'start' });
    expect(local(r.ext.intents[0]!.resolved!.at)).toBe('16:37');
  });

  it('"bé dậy rồi": a sleep that ended now with no start → a timer stop (the planner asks the start when none runs)', () => {
    const r = resolve(u('log', [ev('sleep', 'finished', { ended: ago(0) })]), 'bé dậy rồi');
    expect(r.ext.intents[0]!.resolved).toMatchObject({ at: null, timer: { action: 'stop' } });
    expect(local(r.ext.intents[0]!.resolved!.endAt)).toBe('16:57');
  });

  it('"ngủ 9 tiếng": a length with no end point → nothing resolved (the start is asked)', () => {
    const r = resolve(
      u('log', [
        ev('sleep', 'finished', { started: unknownTime, ended: unknownTime, durationMin: 540 }),
      ]),
      'ngủ 9 tiếng',
    );
    expect(r.ext.intents[0]!.resolved).toMatchObject({ at: null, endAt: null, timer: null });
    expect(r.ext.intents[0]!.fields.durationMin).toBe(540);
  });

  it('"bé ngủ từ 13h đến 14h": two clocks → the span; "10 giờ tối" at 07:00 → last night', () => {
    const r = resolve(
      u('log', [ev('sleep', 'finished', { started: clock('13:00'), ended: clock('14:00') })]),
      'bé ngủ từ 13h đến 14h',
    );
    expect([
      local(r.ext.intents[0]!.resolved!.at),
      local(r.ext.intents[0]!.resolved!.endAt),
    ]).toEqual(['13:00', '14:00']);
    const night = resolve(
      u('log', [
        ev('bottle', 'finished', { started: clock('22:00', -1), fields: { amountMl: 120 } }),
      ]),
      'bé bú 120ml lúc 10 giờ tối',
      {
        anchor: new Date('2026-10-19T00:00:00Z'),
      },
    );
    expect(night.ext.intents[0]!.resolved!.at).toBe('2026-10-18T15:00:00.000Z');
  });

  it('a written "8h" at 21:30 is the one open clock (asked once); a period word or an answer closes it', () => {
    const at = new Date('2026-10-19T14:30:00Z');
    const open = resolve(
      u('log', [ev('bottle', 'finished', { started: clock('08:00'), fields: { amountMl: 120 } })]),
      'bé bú bình 120ml lúc 8h',
      { anchor: at },
    );
    expect(open.ext.intents[0]!.resolved!.ambiguous).toEqual(['8:00']);
    expect(local(open.ext.intents[0]!.resolved!.at)).toBe('20:00');
    const said = resolve(
      u('log', [ev('bottle', 'finished', { started: clock('08:00'), fields: { amountMl: 120 } })]),
      'bé bú bình 120ml lúc 8h sáng',
      { anchor: at },
    );
    expect(said.ext.intents[0]!.resolved!.ambiguous).toEqual([]);
    expect(local(said.ext.intents[0]!.resolved!.at)).toBe('08:00');
    const answered = resolve(
      u('log', [ev('bottle', 'finished', { started: clock('08:00'), fields: { amountMl: 120 } })]),
      'bé bú bình 120ml lúc 8h',
      {
        anchor: at,
        answers: new Map([
          ['time.ampm', { choiceId: null, text: 'Sáng. Hiện tại thì biết sáng hay tối chứ' }],
        ]),
      },
    );
    expect(answered.ext.intents[0]!.resolved!.ambiguous).toEqual([]);
    expect(local(answered.ext.intents[0]!.resolved!.at)).toBe('08:00');
  });

  it('LUMI-04 guard: "1h trua" read as 12:00 by the model → the words win (13:00), flagged', () => {
    const r = resolve(
      u('log', [
        {
          ...ev('sleep', 'finished', { started: clock('12:00'), ended: clock('14:00') }),
          evidence: [
            { field: 'started', text: '1h trua' },
            { field: 'ended', text: '2h chieu' },
          ],
        },
      ]),
      'be ngu tu 1h trua den 2h chieu',
    );
    expect(local(r.ext.intents[0]!.resolved!.at)).toBe('13:00');
    expect(r.ext.intents[0]!.resolved!.misread).toEqual(['startedAt']);
  });
});

describe('understanding v1: precedence (§12.3 #3)', () => {
  it('an ongoing state is never a correction, even when the model calls it one', () => {
    const r = resolve(
      u('correct', [ev('sleep', 'ongoing', { started: ago(10) })], { target: 'i1' }),
      'Bé đã ngủ được 10p trước đó và vẫn đang ngủ',
      { previous: waitingSleep },
    );
    expect(r.act).toBe('log');
    expect(r.ext.intents[0]!.correctsPrevious).toBe(false);
    expect(r.ext.intents[0]!.correctsId).toBeUndefined();
  });

  it('"Ko ý tôi là …" (no correcting word) stays a log; "180 chứ không phải 120" with a target corrects it', () => {
    const r = resolve(
      u('correct', [ev('sleep', 'ongoing', { started: ago(10) })], { target: 'i1' }),
      'Ko ý tôi là đã ngủ trước đó 10p và vẫn đang ngủ',
      {
        previous: waitingSleep,
      },
    );
    expect(r.act).toBe('log');
    const bottle = previous([
      {
        id: 'd9',
        taskId: 't0',
        state: 'draft',
        payload: { kind: 'bottle', amountMl: 120, occurredAt: AT.toISOString(), milk: 'formula' },
        recordLink: null,
      },
    ]);
    const c = resolve(
      u(
        'correct',
        [ev('bottle', 'finished', { started: unknownTime, fields: { amountMl: 180 } })],
        { target: 'i1' },
      ),
      '180 chứ không phải 120',
      {
        previous: bottle,
      },
    );
    expect(c.act).toBe('correct');
    expect(c.ext.intents[0]).toMatchObject({
      correctsPrevious: true,
      corrects: 'bottle',
      correctsId: 'd9',
    });
    expect(c.ext.replyTo).toBe('draft');
  });

  it('correct / undo need a target that exists; a bare value while a draft waits counts without a correcting word', () => {
    const none = resolve(
      u(
        'correct',
        [ev('bottle', 'finished', { started: unknownTime, fields: { amountMl: 180 } })],
        { target: 'i7' },
      ),
      '180 chứ',
      { previous: waitingSleep },
    );
    expect(none.act).toBe('log');
    const undo = resolve(u('undo', [], { target: 'i1' }), 'remove the last sleep log please', {
      previous: waitingSleep,
    });
    expect(undo.act).toBe('undo');
    expect(undo.undo?.id).toBe('d1');
    expect(resolve(u('undo', [], { target: null }), 'remove it').act).toBe('meta');
    const bare = resolve(
      u(
        'correct',
        [ev('bottle', 'finished', { started: unknownTime, fields: { amountMl: 180 } })],
        { target: 'i1' },
      ),
      '180',
      {
        previous: previous([
          {
            id: 'd9',
            taskId: 't0',
            state: 'draft',
            payload: { kind: 'bottle', amountMl: 120, occurredAt: null, milk: null },
            recordLink: null,
          },
        ]),
      },
    );
    expect(bare.act).toBe('correct');
  });

  it('answer with events is a log; talk / none / meta with events is a log; log with nothing is none or read', () => {
    expect(
      resolve(
        u('answer', [ev('bottle', 'finished', { started: unknownTime })]),
        '13:00 bé bú 120ml',
      ).act,
    ).toBe('log');
    expect(
      resolve(
        u('talk', [ev('bottle', 'finished', { started: unknownTime })]),
        'cảm ơn, bé bú 120ml',
      ).act,
    ).toBe('log');
    expect(resolve(u('log', []), 'hmm').act).toBe('none');
    expect(
      resolve(
        u('log', [], { reads: [{ tool: 'care_summary', dayOffset: 0 }] }),
        'hôm nay bé bú mấy cữ',
      ).act,
    ).toBe('read');
    expect(resolve(u('answer', []), 'Bây giờ').ext).toMatchObject({
      intents: [],
      replyTo: 'question',
    });
  });

  it('continue takes the instant of the latest item; without one it is a log', () => {
    const saved = previous([
      {
        id: 'd2',
        taskId: 't0',
        state: 'saved',
        payload: {
          kind: 'bottle',
          amountMl: 120,
          occurredAt: '2026-10-19T02:00:00Z',
          milk: 'formula',
        },
        recordLink: null,
        recordId: 'r1',
      },
    ]);
    const r = resolve(
      u('continue', [ev('sleep', 'ongoing', { started: clock('10:00') })]),
      'rồi ngủ lúc 10h',
      { previous: saved, anchor: new Date('2026-10-19T03:30:00Z') },
    );
    expect(r.act).toBe('continue');
    expect(r.after?.toISOString()).toBe('2026-10-19T02:00:00.000Z');
    expect(
      resolve(
        u('continue', [ev('sleep', 'ongoing', { started: clock('10:00') })]),
        'rồi ngủ lúc 10h',
      ).act,
    ).toBe('log');
  });

  it('targetOf: "i2" is the second item the model saw, "kind:sleep" the latest of that kind', () => {
    const two = previous([
      {
        id: 'a',
        taskId: 't0',
        state: 'draft',
        payload: { kind: 'bottle', amountMl: 120, occurredAt: null, milk: null },
        recordLink: null,
      },
      {
        id: 'b',
        taskId: 't0',
        state: 'saved',
        payload: { kind: 'sleep', startedAt: null, endedAt: null, durationMin: 30, linked: null },
        recordLink: null,
        recordId: 'r',
      },
    ]);
    expect(targetOf('i2', two)?.id).toBe('b');
    expect(targetOf('kind:sleep', two)?.id).toBe('b');
    expect(targetOf('i3', two)).toBeNull();
  });
});

describe('understanding v1: the request, the schema, the legacy translation', () => {
  const input: ExtractInput = {
    text: 'Bé đã ngủ được 10p trước đó và vẫn đang ngủ',
    locale: 'vi',
    anchor: { date: '2026-10-19', time: '16:57', weekday: 'Monday', zone: ZONE },
    clarifications: [],
    allowedIntents: [
      'bottle',
      'breast',
      'sleep',
      'pump',
      'diaper',
      'growth',
      'observation',
      'expense',
      'reminder',
    ],
    allowedReads: ['care_summary', 'sleep_facts', 'usage_snapshot'],
    previous: {
      text: null,
      drafts: [{ id: 'i1', kind: 'sleep', saved: false, durationMin: 10 }],
      question: null,
      turns: [],
    },
  };

  it('is a strict JSON-schema chat completion: the act, the events with their time line, the few-shot examples', () => {
    const req = buildUnderstandRequest(input, 'gpt-4.1-mini') as {
      messages: { role: string; content: string }[];
      response_format: { json_schema: { strict: boolean; schema: Record<string, unknown> } };
      temperature: number;
      store: boolean;
    };
    expect(req.store).toBe(false);
    expect(req.temperature).toBe(0);
    expect(req.response_format.json_schema.strict).toBe(true);
    const system = req.messages[0]!.content;
    for (const x of understandingExamples) expect(system).toContain(x.text);
    expect(understandingExamples.length).toBeGreaterThanOrEqual(20);
    // The owner sentences of §12 are examples with the ongoing reading.
    const ex = understandingExamples.find(
      (x) => x.text === 'Bé đã ngủ được 10p trước đó và vẫn đang ngủ',
    )!;
    expect(ex.output).toMatchObject({
      act: 'log',
      events: [{ kind: 'sleep', status: 'ongoing', started: { how: 'ago', minutes: 10 } }],
    });
    expect(system).not.toContain('phase');
    expect(system).not.toContain('correctsPrevious');
    const user = JSON.parse(req.messages[1]!.content) as Record<string, unknown>;
    expect(user.untrusted_user_text).toBe(input.text);
    expect(user.previous_turn).toEqual(input.previous);
    const schema = req.response_format.json_schema.schema as {
      properties: Record<string, unknown>;
      required: string[];
    };
    expect(schema.required).toEqual([
      'act',
      'target',
      'confidence',
      'events',
      'reads',
      'ask',
      'care',
      'healthSigns',
    ]);
    const kinds = (
      schema.properties.events as {
        items: { anyOf: { properties: { kind: { enum: string[] } } }[] };
      }
    ).items.anyOf.map((b) => b.properties.kind.enum[0]);
    expect(kinds).toEqual(input.allowedIntents);
    const sleep = (schema.properties.events as { items: { anyOf: { required: string[] }[] } }).items
      .anyOf[2]!;
    expect(sleep.required).toEqual([
      'kind',
      'status',
      'started',
      'ended',
      'durationMin',
      'fields',
      'evidence',
      'uncertainFields',
    ]);
    // An expense has no time line.
    const expense = (schema.properties.events as { items: { anyOf: { required: string[] }[] } })
      .items.anyOf[7]!;
    expect(expense.required).toEqual(['kind', 'status', 'fields', 'evidence', 'uncertainFields']);
    expect(understandingJsonSchema([], [])).toMatchObject({
      properties: { events: { items: { type: 'string' } } },
    });
  });

  it('parses the v9 shape strictly and a v8 reply through the legacy translation', () => {
    const v9 = {
      act: 'log',
      target: null,
      confidence: 0.95,
      events: [
        {
          kind: 'sleep',
          status: 'ongoing',
          started: { how: 'ago', minutes: 10, hhmm: null, dayOffset: null },
          ended: null,
          durationMin: null,
          fields: {},
          evidence: [{ field: 'started', text: 'đã ngủ được 10p trước đó' }],
          uncertainFields: [],
        },
      ],
      reads: [],
      ask: null,
      care: null,
      healthSigns: [],
    };
    expect(parseUnderstanding(v9)).toMatchObject({ ok: true, value: { act: 'log' } });
    expect(understandingSchema.safeParse({ ...v9, act: 'delete' }).success).toBe(false);
    expect(parseUnderstanding({ ...v9, events: [{ ...v9.events[0], phase: 'start' }] }).ok).toBe(
      false,
    );
    expect(parseUnderstanding({ nope: true }).ok).toBe(false);
    const v8 = parseUnderstanding({
      intents: [
        {
          kind: 'sleep',
          fields: { time: '11:20', dayOffset: 0, phase: 'start' },
          evidence: [{ field: 'time', text: '11h20' }],
          uncertainFields: [],
          missingFields: [],
        },
        {
          kind: 'bottle',
          fields: { amountMl: 180 },
          evidence: [{ field: 'amountMl', text: '180ml' }],
          uncertainFields: [],
          missingFields: ['time'],
          correctsPrevious: true,
          corrects: 'bottle',
        },
      ],
      reads: [],
      clarification: null,
      care: null,
      healthSigns: [],
      smallTalk: false,
      outOfScope: false,
    });
    expect(v8.ok).toBe(true);
    const value = (v8 as { value: Understanding }).value;
    expect(value.act).toBe('correct');
    expect(value.target).toBe('kind:bottle');
    expect(value.events[0]).toMatchObject({
      kind: 'sleep',
      status: 'ongoing',
      started: { how: 'clock', hhmm: '11:20' },
      evidence: [{ field: 'started', text: '11h20' }],
    });
    expect(value.events[1]).toMatchObject({
      kind: 'bottle',
      status: 'finished',
      started: { how: 'unknown' },
      fields: { amountMl: 180 },
    });
    const stop = fromLegacyExtraction({
      intents: [
        {
          kind: 'sleep',
          fields: { endTime: '06:00', dayOffset: 0, phase: 'stop' } as never,
          evidence: [],
          uncertainFields: [],
          missingFields: [],
        },
      ],
      reads: [],
      clarification: null,
    });
    expect(stop.events[0]).toMatchObject({
      status: 'finished',
      started: { how: 'unknown' },
      ended: { how: 'clock', hhmm: '06:00' },
    });
  });

  it('the fake gateway answers `understand` from the same script as `extract`', async () => {
    const gw = fakeModelGateway({ extract: [{ act: 'meta' }] });
    expect(await gw.understand!(input, new AbortController().signal)).toEqual({ act: 'meta' });
    expect(gw.calls.extract).toHaveLength(1);
  });
});
