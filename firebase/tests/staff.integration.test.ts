import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { defaultFlags, maskEmail } from '@child-life/contracts';
import { createSupportTicket, requestStorage } from '../functions/src/account.js';
import { MemoryError, createMemory } from '../functions/src/memories.js';
import {
  StaffError,
  badges,
  claimTicket,
  closeTicket,
  decideStorage,
  familyCode,
  listAudit,
  listStorageRequests,
  listTickets,
  overview,
  readFlags,
  replyTicket,
  rerunJob,
  setFlag,
  systemHealth,
  ticketDetail,
  type AccountLister,
  type Staff,
} from '../functions/src/staff.js';

// S15 server side against the Firestore emulator: the role matrix (P-121), reasons and the
// append-only audit (A12, R-183), storage grant / decline (A05, P-120), tickets (A03), job re-run
// (A07), flags and the upload kill switch (A10/A11, P-122), and that no answer carries captions,
// names or other family content.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z');
const GB = 1024 ** 3;
let app: App;
let db: Firestore;
const babyId = 'b_5715000000000000000a';
const familyId = 'f_s15';

const linh: Staff = { uid: 's_linh', name: 'Linh Trần', roles: ['ops', 'support'] };
const ha: Staff = { uid: 's_ha', name: 'Hà Nguyễn', roles: ['support'] };
const minh: Staff = { uid: 's_minh', name: 'Minh Phạm', roles: ['eng'] };
const lead: Staff = { uid: 's_lead', name: 'Trưởng nhóm', roles: ['lead'] };

const accounts: AccountLister = {
  list: async () => [
    {
      uid: 'mom',
      email: 'mai.nguyen@gmail.com',
      createdAt: new Date('2026-10-01T00:00:00Z'),
      verified: true,
    },
    {
      uid: 'dad',
      email: 'minh@gmail.com',
      createdAt: new Date('2026-10-02T00:00:00Z'),
      verified: false,
    },
  ],
};

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError || e instanceof MemoryError ? e.reason : String(e);
  }
};

const mom = { uid: 'mom', email: 'mai.nguyen@gmail.com', anonymous: false, locale: 'vi' as const };

beforeAll(() => {
  app = initializeApp({ projectId }, `staff-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://127.0.0.1:8080/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {
      method: 'DELETE',
    },
  );
  await db.doc(`families/${familyId}`).set({
    ownerUid: 'mom',
    quotaBytes: 10 * GB,
    usedBytes: 9.6 * GB,
    reservedBytes: 0,
    babyIds: [babyId],
    usage: { [babyId]: { photos: 300, videos: 20, photoBytes: 5.1 * GB, videoBytes: 4.2 * GB } },
  });
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    familyId,
    ownerUid: 'mom',
    state: 'active',
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  for (const [uid, role] of [
    ['mom', 'coParent'],
    ['dad', 'coParent'],
    ['grandma', 'relative'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      status: 'active',
      isOwner: uid === 'mom',
      displayName: uid,
      relation: 'other',
    });
  }
  await db.doc(`babies/${babyId}/records/r1`).set({
    babyId,
    type: 'bottle',
    createdAt: new Date(now.getTime() - 3_600_000),
    createdBy: 'mom',
    note: 'Bé uống 90 ml rất ngon',
  });
  await db.doc(`babies/${babyId}/memories/m1`).set({
    babyId,
    createdAt: new Date(now.getTime() - 7_200_000),
    caption: 'Ảnh riêng tư của Teddy',
    createdBy: 'mom',
  });
});

describe('the matrix (P-121)', () => {
  it('non-staff see nothing; each role only its actions', async () => {
    expect(await reason(listTickets(db, null, { status: 'open' }))).toBe('not-staff');
    const { id } = await requestStorage(
      db,
      mom,
      { requestId: randomUUID(), babyId, amountGb: 10 },
      now,
      {
        staffInbox: 's@x',
      },
    );
    expect(
      await reason(
        decideStorage(
          db,
          ha,
          { decision: 'grant', requestId: id, grantGb: 10, reason: 'ok ok', message: '' },
          now,
        ),
      ),
    ).toBe('role');
    // P-120: above 20 GB needs a team lead.
    expect(
      await reason(
        decideStorage(
          db,
          linh,
          { decision: 'grant', requestId: id, grantGb: 30, reason: 'nhiều video', message: '' },
          now,
        ),
      ),
    ).toBe('role');
    expect(
      await reason(rerunJob(db, ha, { jobId: 'x', reason: 'thử lại' }, now, async () => {})),
    ).toBe('role');
  });

  it('a reason is required for every mutation', async () => {
    expect(
      await reason(
        setFlag(
          db,
          minh,
          {
            key: 'video_upload',
            enabled: false,
            scope: 'all',
            percent: 0,
            notice: null,
            reason: '',
          },
          now,
        ),
      ),
    ).toBe('malformed');
  });
});

describe('A04/A05 storage', () => {
  it('a grant raises the quota, tells the family and is audited', async () => {
    const { id } = await requestStorage(
      db,
      mom,
      { requestId: randomUUID(), babyId, amountGb: 10, message: 'Con thứ hai mới sinh' },
      now,
      { staffInbox: 's@x' },
    );
    const list = await listStorageRequests(db, linh, { status: 'open' }, now, accounts);
    expect(list.kpis.pending).toBe(1);
    const row = list.rows[0]!;
    expect(row.family).toBe(familyCode(familyId));
    expect(row.family).toMatch(/^F-[A-Z2-9]{4}$/);
    expect(row).toMatchObject({
      babies: 1,
      people: 3,
      requestedGb: 10,
      message: 'Con thứ hai mới sinh',
    });
    expect(JSON.stringify(list)).not.toContain('Teddy');

    const r = await decideStorage(
      db,
      linh,
      {
        decision: 'grant',
        requestId: id,
        grantGb: 10,
        reason: 'Gia đình 2 bé, tăng 0,8 GB/tháng.',
        message: 'Đã thêm 10 GB!',
      },
      now,
    );
    expect(r.quotaBytes).toBe(20 * GB);
    expect((await db.doc(`storageRequests/${id}`).get()).get('status')).toBe('granted');
    const notice = (
      await db.doc(`babies/${babyId}/notifications/storage_granted_${id}`).get()
    ).data()!;
    expect(notice.kind).toBe('storageGranted');
    expect([...notice.recipients].sort()).toEqual(['dad', 'mom']);
    const mail = (await db.collection('mail').where('template', '==', 'storageGranted').get()).docs;
    expect(mail[0]!.get('to')).toBe('mai.nguyen@gmail.com');
    const log = await listAudit(db, linh, { category: 'storage', days: 7 }, now);
    expect(log.rows[0]).toMatchObject({
      actor: 'Linh Trần',
      role: 'Vận hành · Hỗ trợ',
      action: 'storage.grant',
      target: familyCode(familyId),
      reason: 'Gia đình 2 bé, tăng 0,8 GB/tháng.',
    });
    expect(
      await reason(
        decideStorage(
          db,
          linh,
          { decision: 'decline', requestId: id, reason: 'lặp lại', message: '' },
          now,
        ),
      ),
    ).toBe('already-decided');
  });

  it('a team lead may grant more; declines carry the reason', async () => {
    const a = await requestStorage(
      db,
      mom,
      { requestId: randomUUID(), babyId, amountGb: 20 },
      now,
      { staffInbox: 's@x' },
    );
    await decideStorage(
      db,
      lead,
      { decision: 'grant', requestId: a.id, grantGb: 40, reason: 'gia đình lớn', message: '' },
      now,
    );
    expect((await db.doc(`families/${familyId}`).get()).get('quotaBytes')).toBe(50 * GB);
    const b = await requestStorage(
      db,
      mom,
      { requestId: randomUUID(), babyId, amountGb: 20 },
      now,
      { staffInbox: 's@x' },
    );
    await decideStorage(
      db,
      linh,
      {
        decision: 'decline',
        requestId: b.id,
        reason: 'Đã mở rộng trong tháng.',
        message: 'Hẹn 30 ngày.',
      },
      now,
    );
    expect((await db.doc(`storageRequests/${b.id}`).get()).get('status')).toBe('declined');
  });
});

describe('A03 support', () => {
  it('masked emails; claim, reply with a macro, close — all audited', async () => {
    const { ticket } = await createSupportTicket(
      db,
      mom,
      {
        requestId: randomUUID(),
        category: 'memories',
        message: 'Không tải được video lên album\nChi tiết…',
        diagnostics: null,
        locale: 'vi',
      },
      now,
      { staffInbox: 's@x' },
    );
    const list = await listTickets(db, ha, { status: 'open' });
    expect(list.rows[0]).toMatchObject({
      ticket,
      email: maskEmail('mai.nguyen@gmail.com'),
      status: 'new',
    });
    expect(list.rows[0]!.email).toBe('m***@gmail.com');
    const id = list.rows[0]!.id;
    expect((await badges(db, ha)).tickets).toBe(1);
    expect(await reason(badges(db, null))).toBe('not-staff');
    const detail = await ticketDetail(db, ha, { ticketId: id });
    expect(detail).toMatchObject({ role: 'owner', family: { babies: 1, people: 3 } });
    await claimTicket(db, ha, { ticketId: id }, now);
    expect(await reason(claimTicket(db, linh, { ticketId: id }, now))).toBe('already-claimed');
    await replyTicket(
      db,
      ha,
      { ticketId: id, text: 'x', macro: 'wifiGuide', reason: 'Người dùng hỏi về video.' },
      now,
    );
    expect((await db.collection('mail').where('template', '==', 'supportReply').get()).size).toBe(
      1,
    );
    await closeTicket(db, ha, { ticketId: id, reason: 'Đã hướng dẫn xong.' }, now);
    expect((await badges(db, ha)).tickets).toBe(0);
    const log = await listAudit(db, ha, { category: 'support', days: 7 }, now);
    expect(log.rows.map((r) => r.action).sort()).toEqual([
      'support.claim',
      'support.close',
      'support.macro.wifiGuide',
    ]);
  });
});

describe('A07, A10/A11', () => {
  it('a failed deletion re-runs from its failed step with a reason', async () => {
    await db.doc('deletionJobs/del_x').set({
      kind: 'account',
      state: 'failed',
      failedStep: 'personal',
      step: 2,
      steps: ['a', 'b', 'c'],
      createdAt: now,
    });
    const ran: string[] = [];
    await rerunJob(
      db,
      minh,
      { jobId: 'del_x', reason: 'Kho lưu trữ đã ổn định lại.' },
      now,
      async (j) => {
        ran.push(j);
      },
    );
    expect(ran).toEqual(['del_x']);
    expect((await db.doc('deletionJobs/del_x').get()).data()).toMatchObject({
      state: 'queued',
      step: 2,
      attempts: 0,
    });
    expect(
      await reason(rerunJob(db, minh, { jobId: 'del_x', reason: 'lại' }, now, async () => {})),
    ).toBe('not-failed');
  });

  it('switching uploads off needs Kỹ thuật; new uploads wait, notes still save', async () => {
    expect(
      await reason(
        setFlag(
          db,
          linh,
          {
            key: 'media_upload',
            enabled: false,
            scope: 'all',
            percent: 0,
            notice: null,
            reason: 'quá tải',
          },
          now,
        ),
      ),
    ).toBe('role');
    await setFlag(
      db,
      minh,
      {
        key: 'media_upload',
        enabled: false,
        scope: 'all',
        percent: 0,
        notice: 'Tạm dừng tải ảnh.',
        reason: 'Kho lưu trữ gặp sự cố.',
      },
      now,
    );
    const compose = (items: unknown[]) => ({
      babyId,
      memoryId: `mem_${randomUUID().replace(/-/g, '')}`,
      batchId: `bat_${randomUUID().replace(/-/g, '')}`,
      caption: 'ghi chú',
      audience: 'family',
      notifyFamily: false,
      dateMode: 'capture',
      date: null,
      milestone: null,
      albumIds: [],
      items,
    });
    expect(
      await reason(
        createMemory(
          db,
          'mom',
          compose([
            {
              mediaId: `med_${'1'.repeat(32)}`,
              type: 'photo',
              sizeBytes: 1000,
              contentType: 'image/jpeg',
              captureAt: now.toISOString(),
              durationMs: null,
              width: 100,
              height: 100,
              hasPoster: false,
            },
          ]),
          now,
        ),
      ),
    ).toBe('uploads-paused');
    expect(await reason(createMemory(db, 'mom', compose([]), now))).toBe('ok');
    // Ops move a rollout step without changing on/off.
    await setFlag(
      db,
      linh,
      {
        key: 'ai_story_drafts',
        enabled: false,
        scope: 'percent',
        percent: 50,
        notice: null,
        reason: 'Chi phí ổn định.',
      },
      now,
    );
    const flags = await readFlags(db, linh);
    expect(flags.flags.media_upload).toMatchObject({ enabled: false, notice: 'Tạm dừng tải ảnh.' });
    expect(flags.flags.ai_story_drafts).toMatchObject({ scope: 'percent', percent: 50 });
    expect(flags.lastEdit.media_upload?.by).toBe('Minh Phạm');
    expect(defaultFlags.media_upload.enabled).toBe(false);
  });
});

describe('aggregates carry no family content (A02, A08)', () => {
  it('counts only', async () => {
    const o = await overview(db, linh, { days: 30 }, now, accounts);
    expect(o.kpis.activeFamilies).toBe(1);
    expect(o.kpis.newAccounts).toBe(2);
    expect(o.funnel.find((f) => f.step === 'verified')!.count).toBe(1);
    const s = await systemHealth(db, linh, now);
    expect(s.kpis.over80).toBe(1);
    expect(s.nearQuota[0]).toMatchObject({ family: familyCode(familyId), babies: 1 });
    const all = JSON.stringify([o, s]);
    for (const secret of ['Ảnh riêng tư', '90 ml', 'Teddy', 'mai.nguyen'])
      expect(all).not.toContain(secret);
  });
});
