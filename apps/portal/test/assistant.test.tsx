import {
  assistantOutcomeKinds,
  assistantPoolPlans,
  assistantSwitchKeys,
  attachmentRetentions,
  attachmentStates,
  draftKinds,
  draftStates,
  taskModalities,
  taskStates,
  type StaffAssistantSwitches,
  type StaffAssistantTask,
  type StaffAssistantUsage,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api } from '../src/api';
import { StaffContext, routeOf, routePaths } from '../src/context';
import { messages } from '../src/messages';
import { allowedRoute } from '../src/Shell';
import {
  AssistantScreen,
  ModelDetails,
  SwitchRecent,
  SwitchesView,
  TaskBreakdown,
  TaskLookup,
  TaskTechnical,
  TaskView,
  UsageView,
  lookupTask,
} from '../src/screens/Assistant';
import { launchedFlagDefaults, levelsForRoles, type StaffRole } from './fixtures';

// Trợ lý AI (slice A6): Usage, Tasks lookup, Switches. Server-rendered, no network: callables go
// to a fake api that records them.
const now = new Date('2026-10-15T05:00:00Z');
const taskId = `tk_${'a'.repeat(32)}`;

const usage: StaffAssistantUsage = {
  since: '2026-09-15T17:00:00.000Z',
  truncated: { tasks: false, ops: false },
  pool: [
    {
      plan: 'free',
      committed: 12,
      released: 3,
      held: 1,
      chat: 9,
      summaries: 3,
      households: 4,
      exhausted: 2,
    },
    {
      plan: 'premium',
      committed: 30,
      released: 6,
      held: 0,
      chat: 30,
      summaries: 0,
      households: 2,
      exhausted: 0,
    },
    {
      plan: 'beta',
      committed: 5,
      released: 0,
      held: 0,
      chat: 4,
      summaries: 1,
      households: 1,
      exhausted: 0,
    },
  ],
  daily: Array.from({ length: 30 }, (_, i) => ({
    day: new Date(Date.UTC(2026, 8, 16 + i)).toISOString().slice(0, 10),
    committed: i === 29 ? 7 : 1,
    released: i === 29 ? 2 : 0,
  })),
  tasks: {
    total: 40,
    byState: { ready: 30, failed: 4, blocked: 2, awaiting_clarification: 4 },
    byOutcome: { drafts: 20, answer: 8, health_route: 2, unreadable: 3, none: 7 },
    byModality: { text: 34, image: 6 },
    health: 2,
    errors: [
      { code: 'OCR_UNREADABLE', count: 3 },
      { code: 'USAGE_EXHAUSTED', count: 2 },
    ],
  },
  model: {
    calls: 38,
    tasksWithCalls: 35,
    estimatedCostVnd: 15_000,
    byModel: [
      { model: 'openai:gpt-4.1-mini', promptVersion: 'assistant-v3', tasks: 35, calls: 38 },
    ],
    timeToReady: { samples: 30, p50Ms: 4200, p95Ms: 12_500 },
  },
  budget: { monthlyBudgetVnd: 15_000_000, month: '2026-10', spentVnd: 250_000 },
  credits: {
    free: 20,
    premium: 200,
    textCredits: 1,
    imageCredits: 3,
    aiSummaryCredits: 1,
    stored: true,
  },
};

const task: StaffAssistantTask = {
  taskId,
  family: 'F-7Q2K',
  baby: 'B-K3QZ',
  scope: 'child',
  visibility: 'shared',
  state: 'ready',
  modality: 'text',
  plan: 'free',
  pool: 'free',
  credits: 1,
  usage: 'committed',
  errorCode: null,
  outcome: { kind: 'drafts', drafts: 2, parts: ['draft_reference', 'draft_reference'] },
  health: false,
  round: 1,
  clarifications: [{ field: 'time.ampm', round: 1, answered: true }],
  attempt: 1,
  modelCalls: 2,
  model: 'openai:gpt-4.1-mini',
  promptVersion: 'assistant-v3',
  policyVersion: 'assistant-qa-v3/policy-v2',
  careTopic: null,
  createdAt: '2026-10-15T04:00:00.000Z',
  updatedAt: '2026-10-15T04:00:05.000Z',
  readyAt: '2026-10-15T04:00:04.000Z',
  clarificationExpiresAt: null,
  leaseUntil: null,
  reservation: {
    id: 'assistant_tk_aaaaaaaa…',
    window: 'assistant_cal_2026-10',
    units: 1,
    state: 'committed',
    reservedAt: '2026-10-15T04:00:00.000Z',
    committedAt: '2026-10-15T04:00:04.000Z',
    releasedAt: null,
    releaseReason: null,
  },
  drafts: [
    {
      id: 'dr_aaaaaaaa…_0',
      kind: 'bottle',
      state: 'saved',
      revision: 2,
      missingFields: [],
      uncertainFields: ['time'],
      warnings: ['overlap'],
      errorCode: null,
      expiresAt: '2026-10-16T04:00:00.000Z',
      savedAt: '2026-10-15T04:30:00.000Z',
    },
    {
      id: 'dr_aaaaaaaa…_1',
      kind: 'sleep',
      state: 'needs_review',
      revision: 1,
      missingFields: ['end'],
      uncertainFields: [],
      warnings: [],
      errorCode: null,
      expiresAt: '2026-10-16T04:00:00.000Z',
      savedAt: null,
    },
  ],
  attachments: [
    { state: 'deletion_pending', retention: 'keep_with_record', rejected: true, deleted: false },
  ],
  events: [
    { sequence: 1, type: 'accepted', at: '2026-10-15T04:00:00.000Z' },
    { sequence: 2, type: 'drafts_ready', at: '2026-10-15T04:00:04.000Z' },
  ],
};

const switches: StaffAssistantSwitches = {
  flags: {
    assistant: { enabled: true, scope: 'internal', percent: 0, notice: null, families: ['F-7Q2K'] },
    assistant_live: { enabled: false, scope: 'all', percent: 0, notice: 'Tạm dừng' },
    assistant_images: launchedFlagDefaults.assistant_images,
    assistant_care: launchedFlagDefaults.assistant_care,
    assistant_writes: { enabled: true, scope: 'all', percent: 100, notice: null },
    assistant_upsell: launchedFlagDefaults.assistant_upsell,
  },
  lastEdit: { assistant_live: { by: 'Minh Kỹ sư', at: '2026-10-15T03:00:00.000Z' } },
  recent: [
    {
      action: 'flags.off',
      target: 'assistant_live',
      by: 'Minh Kỹ sư',
      at: '2026-10-15T03:00:00.000Z',
      reason: 'nhà cung cấp lỗi',
      detail: null,
    },
  ],
};

type Call = { name: string; data: unknown };
function fakeApi(answers: Record<string, unknown> = {}) {
  const calls: Call[] = [];
  const api: Api = {
    call: <T,>(name: string, data?: unknown) => {
      calls.push({ name, data });
      return name in answers
        ? Promise.resolve(answers[name] as T)
        : Promise.reject(new ApiError('permission-denied', 'role'));
    },
  };
  return { api, calls };
}

function html(
  node: ReactNode,
  roles: StaffRole[] = ['admin'],
  locale: 'vi' | 'en' = 'vi',
  api: Api = fakeApi().api,
) {
  return renderToStaticMarkup(
    <IntlProvider
      locale={locale}
      defaultLocale="vi"
      messages={messages[locale]}
      onError={(e) => {
        throw e;
      }}
    >
      <ApiContext.Provider value={api}>
        <StaffContext.Provider
          value={{
            uid: 's1',
            email: 'linh@example.com',
            name: 'Linh Trần',
            roles,
            levels: levelsForRoles(roles),
          }}
        >
          {node}
        </StaffContext.Provider>
      </ApiContext.Provider>
    </IntlProvider>,
  );
}
const text = (raw: string) =>
  raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ');
const buttons = (raw: string) =>
  [...raw.matchAll(/<button[^>]*>(.*?)<\/button>/g)].map((m) => text(m[1]!).trim());
const tabs = (raw: string) =>
  [...raw.matchAll(/<button[^>]*role="tab"[^>]*>(.*?)<\/button>/g)].map((m) => text(m[1]!).trim());
const attr = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;');
// Nothing on a read-only view sends anything: no field, no switch, no submit.
const noControls = (raw: string) =>
  expect(raw).not.toMatch(/<input|<textarea|role="switch"|type="submit"/);

describe('Trợ lý AI › screen', () => {
  it('has Mức dùng, Tra cứu tác vụ and Công tắc tabs; the sidebar keeps it to premium.view', () => {
    const raw = html(<AssistantScreen />);
    expect(tabs(raw)).toEqual(['Mức dùng', 'Tra cứu tác vụ', 'Công tắc']);
    expect(raw).toContain('aria-selected="true"');
    expect(text(raw)).toContain('Trợ lý AI');
    // Another tab can open first; only its content is mounted.
    const lookup = html(<AssistantScreen initialTab="tasks" />);
    expect(text(lookup)).toContain('Tra cứu một tác vụ');
    expect(routePaths.assistant).toBe('/assistant');
    expect(routeOf('/assistant')).toBe('assistant');
    for (const role of ['owner', 'admin', 'ops', 'eng'] as StaffRole[]) {
      expect(allowedRoute(levelsForRoles([role]), 'assistant')).toBe('assistant');
    }
    for (const role of ['support', 'analyst', 'expert', 'qa'] as StaffRole[]) {
      expect(allowedRoute(levelsForRoles([role]), 'assistant')).not.toBe('assistant');
    }
  });
});

describe('Trợ lý AI › Mức dùng', () => {
  it('leads with spend against the AI budget, failures and households out of credits', async () => {
    const { api, calls } = fakeApi({ staffAssistantUsage: usage });
    const data = await api.call<StaffAssistantUsage>('staffAssistantUsage');
    expect(calls).toEqual([{ name: 'staffAssistantUsage', data: undefined }]);
    const raw = html(<UsageView data={data} now={now} />, ['ops']);
    const t = text(raw);
    expect(t).toContain('không có tin nhắn, ảnh, nội dung bản nháp hay tên');
    // Spend vs budget: 250.000 đ of 15.000.000 đ, the assistant's own calls and cost.
    expect(t).toContain('Ngân sách AI · Tháng 10');
    expect(t).toContain('250.000 đ / 15 triệu đ');
    expect(t).toContain('Ngày 15/31 trong tháng');
    expect(t).toContain('Trợ lý, 30 ngày: 38 lần gọi AI · ước tính 15.000 đ');
    expect(raw).toContain('role="progressbar"');
    expect(t).not.toContain('Đã dùng hết ngân sách');
    expect(t).toContain('Tác vụ 30 ngày 40');
    expect(t).toContain('2 hỗ trợ sức khoẻ · 2 bị chặn');
    expect(t).toContain('Tác vụ lỗi 4');
    expect(t).toContain('Mã lỗi nhiều nhất: OCR_UNREADABLE');
    expect(t).toContain('Hộ hết credit 2');
    expect(t).toContain('Credit đã tính 47');
    expect(t).toContain('9 đã trả lại · 1 đang giữ');
    expect(t).toContain('Miễn phí');
    expect(t).toContain('Beta');
    expect(t).toContain('9 chat · 3 tóm tắt');
    expect(t).toContain('USAGE_EXHAUSTED');
    expect(t).toContain('Tác vụ ảnh 3 credit');
    expect(t).toContain('Tóm tắt AI 1 credit');
    // Breakdowns and model counters fold away, with what is inside said on the fold.
    expect(t).toContain('34 chữ · 6 ảnh · 2 hỗ trợ sức khoẻ');
    expect(t).toContain('38 lần gọi · p95 12,5 giây');
    // Credits are edited in Premium (D-075 #1): a link, no editing here.
    expect(buttons(raw)).toContain('Sửa ở Premium');
    noControls(raw);
    expect(t).not.toContain('Có quá nhiều bản ghi');
    const en = text(html(<UsageView data={data} now={now} />, ['ops'], 'en'));
    expect(en).toContain('Credits counted 47');
    expect(en).toContain('Households out of credits 2');
    expect(en).toContain('9 chat · 3 summaries');
    expect(en).toContain('Photo task 3 credits');
    expect(en).toContain('Assistant, 30 days: 38 AI calls · estimated');
  });

  it('warns first when the shared AI budget passes 80% or runs out', () => {
    const near = text(
      html(
        <UsageView
          data={{ ...usage, budget: { ...usage.budget, spentVnd: 12_750_000 } }}
          now={now}
        />,
      ),
    );
    expect(near).toContain('Đã dùng 85% ngân sách AI tháng này');
    expect(near).toContain('dùng chung với tóm tắt AI và gợi ý câu chuyện');
    const over = text(
      html(
        <UsageView
          data={{ ...usage, budget: { ...usage.budget, spentVnd: 15_000_000 } }}
          now={now}
        />,
      ),
    );
    expect(over).toContain('Đã dùng hết ngân sách AI tháng này');
  });

  it('the folded breakdown and model counters show states, outcomes, models and timings', () => {
    const b = text(html(<TaskBreakdown tasks={usage.tasks} />));
    expect(b).toContain('Đang hỏi lại');
    expect(b).toContain('Ảnh không đọc được');
    expect(b).toContain('Chưa có kết quả');
    expect(b).toContain('Tác vụ chữ 34');
    expect(b).toContain('Hỗ trợ sức khoẻ 2');
    const m = text(html(<ModelDetails model={usage.model} />));
    expect(m).toContain('38 lần gọi · 35 tác vụ');
    expect(m).toContain('15.000 đ');
    expect(m).toContain('openai:gpt-4.1-mini');
    expect(m).toContain('assistant-v3');
    expect(m).toContain('4,2 giây trung vị · 12,5 giây p95 · 30 mẫu');
  });

  it('says when the bounded reads were cut, and an empty month reads as such', () => {
    const tasks = { total: 0, byState: {}, byOutcome: {}, byModality: {}, health: 0, errors: [] };
    const model = {
      calls: 0,
      tasksWithCalls: 0,
      estimatedCostVnd: 0,
      byModel: [],
      timeToReady: { samples: 0, p50Ms: null, p95Ms: null },
    };
    const t = text(
      html(
        <UsageView
          data={{
            ...usage,
            truncated: { tasks: true, ops: false },
            tasks,
            model,
            credits: { ...usage.credits, stored: false },
          }}
          now={now}
        />,
      ),
    );
    expect(t).toContain('Có quá nhiều bản ghi trong 30 ngày');
    expect(t).toContain('Không có lỗi');
    expect(t).toContain('Đang dùng mặc định');
    expect(t).toContain('0 lần gọi · p95 —');
    expect(text(html(<TaskBreakdown tasks={tasks} />))).toContain(
      'Chưa có tác vụ nào trong 30 ngày.',
    );
    expect(text(html(<ModelDetails model={model} />))).toContain('Chưa có mẫu');
  });
});

describe('Trợ lý AI › Tra cứu tác vụ', () => {
  it('a malformed id never reaches the server; a good one calls staffAssistantTask', async () => {
    const { api, calls } = fakeApi({ staffAssistantTask: task });
    expect(await lookupTask(api, 'tk_123')).toEqual({
      ok: false,
      problem: 'assistant.lookup.hint',
    });
    expect(calls).toEqual([]);
    expect(await lookupTask(api, `  ${taskId.toUpperCase().replace('TK_', 'tk_')} `)).toEqual({
      ok: true,
      task,
    });
    expect(calls).toEqual([{ name: 'staffAssistantTask', data: { taskId } }]);
    expect(await lookupTask(fakeApi().api, taskId)).toEqual({ ok: false, problem: 'error.role' });
    const missing: Api = {
      call: () => Promise.reject(new ApiError('not-found', 'no-task')),
    };
    expect(await lookupTask(missing, taskId)).toEqual({ ok: false, problem: 'error.notFound' });
  });

  it('shows states, codes, counts and times only, read-only', () => {
    const raw = html(<TaskView task={task} now={now} />, ['ops']);
    const t = text(raw);
    expect(t).toContain(taskId);
    expect(t).toContain('F-7Q2K · B-K3QZ');
    expect(t).toContain('Về bé · luồng chung');
    expect(t).toContain('Sẵn sàng');
    expect(t).toContain('Thời gian đến sẵn sàng 4 giây');
    expect(t).toContain('1 credit · đã tính');
    expect(t).toContain('Bản nháp · 2 bản nháp');
    expect(t).toContain('time.ampm · vòng 1 · đã trả lời');
    // Model and versions fold away; the fold names the model.
    expect(t).toContain('Kỹ thuật openai:gpt-4.1-mini');
    const tech = text(html(<TaskTechnical task={task} now={now} />));
    expect(tech).toContain('2 lần gọi · 1 lần chạy');
    expect(tech).toContain('assistant-v3 · assistant-qa-v3/policy-v2');
    expect(t).toContain('Đã tính');
    expect(t).toContain('assistant_cal_2026-10 · assistant_tk_aaaaaaaa…');
    expect(t).toContain('Bú bình');
    expect(t).toContain('Cần xem lại');
    expect(t).toContain('time, overlap');
    expect(t).toContain('end');
    expect(t).toContain('Đang xoá');
    expect(t).toContain('giữ với chi tiêu');
    expect(t).toContain('Ảnh bị từ chối');
    expect(t).toContain('drafts_ready');
    // The only buttons copy the codes (and fold the technical section).
    noControls(raw);
    for (const code of [taskId, 'F-7Q2K', 'B-K3QZ']) {
      expect(raw).toContain(`aria-label="Chép ${code}"`);
    }
    const en = text(html(<TaskView task={task} now={now} />, ['ops'], 'en'));
    expect(en).toContain('About the baby · shared thread');
    expect(en).toContain('time.ampm · round 1 · answered');
  });

  it('the lookup panel carries the no-content note; a health task without reservation', () => {
    const raw = html(<TaskLookup />, ['ops']);
    const t = text(raw);
    expect(t).toContain('Tra cứu một tác vụ');
    // One field and a submit button that stays off until an id is typed.
    expect(raw).toMatch(/<button[^>]*type="submit"[^>]*disabled=""/);
    expect(t).toContain('không có tin nhắn, nội dung bản nháp, câu trả lời hỏi lại');
    const h = text(
      html(
        <TaskView
          task={{
            ...task,
            outcome: null,
            health: true,
            credits: 0,
            usage: 'none',
            reservation: null,
            drafts: [],
            attachments: [],
            events: [],
            clarifications: [],
          }}
          now={now}
        />,
      ),
    );
    expect(h).toContain('Không giữ credit');
    expect(h).toContain('Tác vụ này không có bản nháp.');
    expect(h).toContain('Tác vụ này không có ảnh.');
    expect(h).toContain('Chưa có sự kiện.');
    expect(h).toContain('Hỗ trợ sức khoẻ Có');
  });
});

describe('Trợ lý AI › Công tắc', () => {
  const switchCount = (raw: string) => (raw.match(/role="switch"/g) ?? []).length;
  const disabledCount = (raw: string) =>
    (raw.match(/<button[^>]*role="switch"[^>]*disabled=""/g) ?? []).length;

  it('lists the six switches with what turning off does and the recent changes', () => {
    const raw = html(<SwitchesView data={switches} onChanged={() => {}} />, ['eng']);
    const t = text(raw);
    for (const key of assistantSwitchKeys) {
      expect(t).toContain(messages.vi[`flag.${key}`]!);
      expect(t).toContain(messages.vi[`flag.${key}.desc`]!);
      // What turning off does sits behind the "?" next to the name.
      expect(raw).toContain(`aria-label="Khi tắt: ${attr(messages.vi[`flag.${key}.offEffect`]!)}"`);
    }
    expect(t).toContain('chỉ Kỹ sư, Admin hoặc Owner; luôn cần lý do');
    expect(t).toContain('1 gia đình được chọn');
    expect(t).toContain('Đang tắt');
    expect(t).toContain('Minh · ');
    // Recent changes fold away; the fold counts them.
    expect(t).toContain('Thay đổi gần đây 1 thay đổi');
    const recent = text(html(<SwitchRecent recent={switches.recent} />));
    expect(recent).toContain('Minh · ');
    expect(recent).toContain('nhà cung cấp lỗi');
    expect(text(html(<SwitchRecent recent={[]} />))).toContain('Chưa có thay đổi nào.');
    expect(switchCount(raw)).toBe(6);
    // Kỹ sư may switch (flags.toggle) …
    expect(disabledCount(raw)).toBe(0);
    expect(buttons(raw)).toContain('Mở Tính năng');
  });

  it('… Vận hành sees them but cannot flip them (same rule as Tính năng)', () => {
    const raw = html(<SwitchesView data={switches} onChanged={() => {}} />, ['ops']);
    expect(switchCount(raw)).toBe(6);
    expect(disabledCount(raw)).toBe(6);
    const en = text(html(<SwitchesView data={switches} onChanged={() => {}} />, ['ops'], 'en'));
    expect(en).toContain('a reason is always required');
  });
});

describe('Trợ lý AI › messages', () => {
  it('every dynamic id exists in both catalogs', () => {
    const ids = [
      'nav.assistant',
      ...(['usage', 'tasks', 'switches'] as const).map((t) => `assistant.tab.${t}`),
      ...assistantPoolPlans.map((p) => `assistant.plan.${p}`),
      ...taskStates.map((s) => `assistant.state.${s}`),
      ...[...assistantOutcomeKinds, 'none'].map((k) => `assistant.outcome.${k}`),
      ...taskModalities.map((m) => `assistant.modality.${m}`),
      ...['none', 'reserved', 'committed', 'released'].map((u) => `assistant.usage.${u}`),
      ...draftKinds.map((k) => `assistant.draft.kind.${k}`),
      ...draftStates.map((s) => `assistant.draft.state.${s}`),
      ...attachmentStates.map((s) => `assistant.attachment.state.${s}`),
      ...attachmentRetentions.map((r) => `assistant.attachment.retention.${r}`),
      ...(['free', 'premium', 'text', 'image', 'summary'] as const).map(
        (k) => `assistant.credits.${k}`,
      ),
      ...assistantSwitchKeys.flatMap((k) => [`flag.${k}`, `flag.${k}.desc`, `flag.${k}.offEffect`]),
    ];
    for (const locale of ['vi', 'en'] as const) {
      for (const id of ids) expect(messages[locale][id], `${locale} ${id}`).toBeTruthy();
    }
  });
});
