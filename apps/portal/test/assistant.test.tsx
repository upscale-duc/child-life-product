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
  AssistantTabs,
  SwitchesView,
  TaskLookup,
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

describe('Trợ lý AI › screen', () => {
  it('has Mức dùng, Tra cứu tác vụ and Công tắc tabs; the sidebar keeps it to premium.view', () => {
    const raw = html(<AssistantTabs label="Mục" value="usage" onChange={() => {}} />);
    expect(buttons(raw)).toEqual(['Mức dùng', 'Tra cứu tác vụ', 'Công tắc']);
    expect(text(html(<AssistantScreen />))).toContain('Trợ lý AI');
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
  it('shows the pool by budget, tasks, errors, model counters and links to Premium', async () => {
    const { api, calls } = fakeApi({ staffAssistantUsage: usage });
    const data = await api.call<StaffAssistantUsage>('staffAssistantUsage');
    expect(calls).toEqual([{ name: 'staffAssistantUsage', data: undefined }]);
    const raw = html(<UsageView data={data} />, ['ops']);
    const t = text(raw);
    expect(t).toContain('không có tin nhắn, ảnh, nội dung bản nháp hay tên');
    expect(t).toContain('Tác vụ 30 ngày 40');
    expect(t).toContain('2 hỗ trợ sức khoẻ · 2 bị chặn');
    expect(t).toContain('Credit đã tính 47');
    expect(t).toContain('9 đã trả lại · 1 đang giữ');
    expect(t).toContain('Mã lỗi nhiều nhất: OCR_UNREADABLE');
    expect(t).toContain('Lần gọi AI 38');
    expect(t).toContain('Ước tính 15.000 đ');
    expect(t).toContain('Miễn phí');
    expect(t).toContain('Beta');
    expect(t).toContain('9 chat · 3 tóm tắt');
    expect(t).toContain('Đang hỏi lại');
    expect(t).toContain('Ảnh không đọc được');
    expect(t).toContain('Chưa có kết quả');
    expect(t).toContain('USAGE_EXHAUSTED');
    expect(t).toContain('openai:gpt-4.1-mini');
    expect(t).toContain('4,2 giây trung vị · 12,5 giây p95 · 30 mẫu');
    expect(t).toContain('Tác vụ ảnh 3 credit');
    expect(t).toContain('Tóm tắt AI 1 credit');
    // Credits are edited in Premium (D-075 #1): a link, no editing here.
    expect(buttons(raw)).toEqual(['Sửa ở Premium']);
    expect(t).not.toContain('Có quá nhiều bản ghi');
    const en = text(html(<UsageView data={data} />, ['ops'], 'en'));
    expect(en).toContain('Credits counted 47');
    expect(en).toContain('9 chat · 3 summaries');
    expect(en).toContain('Photo task 3 credits');
  });

  it('says when the bounded reads were cut, and an empty month reads as such', () => {
    const t = text(
      html(
        <UsageView
          data={{
            ...usage,
            truncated: { tasks: true, ops: false },
            tasks: { total: 0, byState: {}, byOutcome: {}, byModality: {}, health: 0, errors: [] },
            model: {
              calls: 0,
              tasksWithCalls: 0,
              estimatedCostVnd: 0,
              byModel: [],
              timeToReady: { samples: 0, p50Ms: null, p95Ms: null },
            },
            credits: { ...usage.credits, stored: false },
          }}
        />,
      ),
    );
    expect(t).toContain('Có quá nhiều bản ghi trong 30 ngày');
    expect(t).toContain('Chưa có tác vụ nào trong 30 ngày.');
    expect(t).toContain('Không có lỗi');
    expect(t).toContain('Chưa có mẫu');
    expect(t).toContain('Đang dùng mặc định');
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
    expect(t).toContain('1 credit · đã tính');
    expect(t).toContain('Bản nháp · 2 bản nháp');
    expect(t).toContain('time.ampm · vòng 1 · đã trả lời');
    expect(t).toContain('2 lần gọi · 1 lần chạy');
    expect(t).toContain('assistant-v3 · assistant-qa-v3/policy-v2');
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
    expect(buttons(raw)).toEqual([]);
    const en = text(html(<TaskView task={task} now={now} />, ['ops'], 'en'));
    expect(en).toContain('About the baby · shared thread');
    expect(en).toContain('time.ampm · round 1 · answered');
  });

  it('the lookup panel carries the no-content note; a health task without reservation', () => {
    const t = text(html(<TaskLookup />, ['ops']));
    expect(t).toContain('Tra cứu một tác vụ');
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
      expect(t).toContain(messages.vi[`flag.${key}.offEffect`]!);
    }
    expect(t).toContain('chỉ Kỹ sư, Admin hoặc Owner; luôn cần lý do');
    expect(t).toContain('1 gia đình được chọn');
    expect(t).toContain('Minh · ');
    expect(t).toContain('nhà cung cấp lỗi');
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
