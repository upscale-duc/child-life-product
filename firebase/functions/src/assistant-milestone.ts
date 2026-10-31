import type { Firestore } from 'firebase-admin/firestore';
import {
  familyCan,
  foldVi,
  hasVietnameseMarks,
  referenceMilestoneSchema,
  type AssistantPart,
} from '@child-life/contracts';
import type { TrustedScope } from './assistant-common.js';

/**
 * Lumi L5 (Mốc): "bé biết lẫy rồi" is still the Nhịp sinh hoạt observation it always was (a new
 * skill); when the skill is one of the reference milestones, a Cùng nuôi (`moments.create`, like
 * the app) is also offered "Ghi nhận mốc": the milestone's page opens its own record sheet with the
 * day, where a photo is added and the card offer follows (lumi-plan §6). Nothing is saved by Lumi;
 * no model call of its own.
 */

type Locale = 'vi' | 'en';

/**
 * Reference ids and the words parents use, written with their diacritics; text without any mark is
 * matched folded. More specific words first ("vịn đứng" before "đứng").
 */
const words: [string, string][] = [
  [
    'first_word',
    'từ đầu tiên|gọi mẹ|gọi ba|gọi bố|nói mẹ|nói ba|nói bố|first word|said mama|said dada',
  ],
  ['cruises', 'đi men|vịn đi|cruising|cruises|cruised'],
  ['stands', 'vịn đứng|đứng được|tự đứng|biết đứng|pulls up|pulled up|pulling up|stands|stood'],
  [
    'first_steps',
    'tự đi|biết đi|đi được|chập chững|bước đầu tiên|first steps|walks|walked|walking',
  ],
  ['sits_up', 'ngồi vững|ngồi được|tự ngồi|biết ngồi|sits up|sat up|sitting up'],
  ['rolls_over', 'lẫy|lật người|lật|rolled over|rolls over|rolling over'],
  ['crawls', 'bò|crawls|crawled|crawling'],
  ['laughs', 'cười thành tiếng|cười khanh khách|cười ha ha|laughs|laughed'],
  ['first_smile', 'mỉm cười|biết cười|cười đáp|smiles|smiled'],
  ['babbles', 'bập bẹ|babbles|babbled|babbling'],
  ['coos', 'ê a|coos|cooing'],
  ['waves_bye', 'vẫy tay|bai bai|bye bye|waves|waved'],
  ['claps_excited', 'vỗ tay|claps|clapped'],
  ['lifts_head', 'giữ đầu|ngóc đầu|cứng cổ|holds (?:her|his) head|lifts (?:her|his) head'],
  ['peekaboo', 'ú òa|ú oà|peekaboo|peek-a-boo'],
  ['pincer_grasp', 'nhặt đồ|bốc đồ nhỏ|pincer'],
  ['transfers_hands', 'chuyền tay|chuyền đồ'],
  ['reaches_for_toy', 'với tay|với lấy|reaches for|reached for'],
  ['hands_to_mouth', 'mút tay|đưa tay lên miệng'],
  ['pushes_up_arms', 'chống tay'],
  ['kicks_ball', 'đá bóng|kicks a ball|kicked a ball'],
  ['runs', 'biết chạy|chạy được|runs|ran'],
  ['jumps_two_feet', 'bật nhảy|nhảy hai chân|biết nhảy|jumps|jumped'],
  ['scribbles', 'vẽ nguệch ngoạc|scribbles|scribbled'],
  ['stacks_blocks', 'chồng khối|xếp khối|xếp chồng|stacks|stacked'],
  ['uses_fork', 'tự xúc|tự cầm thìa|tự cầm nĩa|feeds (?:her|him)self'],
  ['climbs_furniture', 'trèo|leo lên|climbs|climbed'],
  ['points_to_ask', 'chỉ tay|points|pointed'],
  ['two_word_phrases', 'nói câu|ghép hai từ|two words together'],
  ['says_three_words', 'nói được vài từ|nói vài từ|a few words'],
  ['stranger_wariness', 'lạ người|ngại người lạ|sợ người lạ'],
];

const bounded = (alts: string) =>
  new RegExp(String.raw`(?<![\p{L}\p{N}])(?:${alts})(?![\p{L}\p{N}])`, 'u');

/** The reference milestone [text] names (the first one said), or null. */
export function milestoneSaidIn(text: string): string | null {
  const marked = hasVietnameseMarks(text);
  let t = text.normalize('NFC').toLocaleLowerCase('vi');
  if (!marked) t = foldVi(t);
  let best: { id: string; at: number } | null = null;
  for (const [id, alts] of words) {
    const m = bounded(marked ? alts : foldVi(alts)).exec(t);
    if (!m) continue;
    if (!best || m.index < best.at) best = { id, at: m.index };
    // A longer phrase took these words ("vịn đứng"): the shorter ones never see them again.
    t = t.slice(0, m.index) + ' '.repeat(m[0].length) + t.slice(m.index + m[0].length);
  }
  return best?.id ?? null;
}

const L = (vi: string, en: string) => ({ vi, en });
const ddmm = (date: string) => {
  const [, m, d] = date.split('-');
  return `${Number(d)}/${Number(m)}`;
};

/**
 * The "Ghi nhận mốc" offer for [referenceId] seen on [date] (YYYY-MM-DD), or null when the member
 * cannot record milestones or the milestone is not published.
 */
export async function milestoneInvitePart(
  db: Firestore,
  s: TrustedScope,
  referenceId: string,
  date: string,
  locale: Locale,
): Promise<AssistantPart | null> {
  if (!familyCan(s.member, 'moments.create')) return null;
  const [published, record] = await Promise.all([
    db.collection('contentMilestones').where('status', '==', 'published').get(),
    db.doc(`babies/${s.babyId}/milestones/p_${referenceId}`).get(),
  ]);
  const reference = published.docs
    .map((d) => referenceMilestoneSchema.safeParse(d.data()))
    .find((r) => r.success && r.data.id === referenceId);
  if (!reference?.success) return null;
  const title = reference.data.title[locale];
  const seen =
    record.exists && record.get('deleted') !== true && record.get('status') === 'observed';
  const on = record.get('date');
  const text = seen
    ? typeof on === 'string'
      ? L(
          `Mốc “${title}” đã được ghi nhận ngày ${ddmm(on)}.`,
          `“${title}” is already recorded as a milestone (${ddmm(on)}).`,
        )
      : L(`Mốc “${title}” đã được ghi nhận.`, `“${title}” is already recorded as a milestone.`)
    : L(
        `“${title}” cũng là một mốc phát triển. Chạm Ghi nhận mốc để lưu ngày ${ddmm(date)} và thêm ảnh.`,
        `“${title}” is also a development milestone. Tap Record milestone to save ${ddmm(date)} and add a photo.`,
      );
  return {
    type: 'text',
    schemaVersion: 1,
    text: text[locale],
    code: 'MILESTONE_SEEN',
    link: seen
      ? `/utilities/milestones/${referenceId}`
      : `/utilities/milestones/${referenceId}?record=${date}`,
  };
}
