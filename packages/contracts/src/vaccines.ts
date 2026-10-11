import { z } from 'zod';
import { authorSchema } from './care.js';

/**
 * Sổ tiêm chủng (Figma "Label · Tiêm chủng", VX 0 – VX 9a; plan in docs/product/vaccination-plan.md,
 * P-133). The reference schedule below is the one drawn (14 rows, 30 doses from birth to 24 months)
 * plus the polio row of the 5in1 path. Programme and route of the rows the design leaves blank follow
 * Vietnamese practice and await medical review; the app never warns about ages or intervals (R-012).
 * The Dart app reads a generated copy: apps/mobile/tool/vaccine_schedule.mjs →
 * lib/features/vaccines/vaccine_schedule.g.dart.
 */

/** Tiêm chủng mở rộng (free), Dịch vụ (paid), or given at the maternity hospital. */
export const vaccineProgrammes = ['epi', 'service', 'hospital', 'choice'] as const;
export type VaccineProgramme = (typeof vaccineProgrammes)[number];

export const vaccineRoutes = ['injection', 'oral'] as const;
export type VaccineRoute = (typeof vaccineRoutes)[number];

type Text = { vi: string; en: string };

export interface VaccineDef {
  id: string;
  /** Matrix label (VX 1). */
  name: Text;
  /** Timeline label (VX 1b) when it differs. */
  short: Text;
  /** Months of age for each dose; 0 = at birth. */
  months: number[];
  programme: VaccineProgramme;
  route: VaccineRoute;
  /** VX 7 one-line description (reference copy, for review). */
  about: Text;
  /** VX 7 "Khoảng cách", only where the design or the leaflet states it. */
  minIntervalWeeks?: number;
  /** "hằng năm" (flu). */
  yearly?: boolean;
  /** Shown only on the 5in1 path (VX 2 "uống/tiêm thêm bại liệt"). */
  only5in1?: boolean;
  /** The 6in1 / 5in1 series (VX 2 "Chọn một trong hai"). */
  dtpSeries?: boolean;
}

export const vaccineScheduleVersion = 1;

export const vaccineSchedule: readonly VaccineDef[] = [
  {
    id: 'vitk',
    name: { vi: 'Vitamin K', en: 'Vitamin K' },
    short: { vi: 'Vitamin K', en: 'Vitamin K' },
    months: [0],
    programme: 'hospital',
    route: 'injection',
    about: {
      vi: 'Tiêm một lần sau sinh, giúp phòng xuất huyết do thiếu vitamin K.',
      en: 'Given once after birth to help prevent bleeding from vitamin K deficiency.',
    },
  },
  {
    id: 'bcg',
    name: { vi: 'Lao (BCG)', en: 'Tuberculosis (BCG)' },
    short: { vi: 'Lao', en: 'BCG' },
    months: [0],
    programme: 'epi',
    route: 'injection',
    about: {
      vi: 'Giúp phòng bệnh lao, nhất là các thể lao nặng ở trẻ nhỏ.',
      en: 'Helps protect against tuberculosis, especially its severe forms in young children.',
    },
  },
  {
    id: 'hepb',
    name: { vi: 'Viêm gan B', en: 'Hepatitis B' },
    short: { vi: 'Viêm gan B', en: 'Hepatitis B' },
    months: [0],
    programme: 'epi',
    route: 'injection',
    about: {
      vi: 'Mũi sơ sinh trong 24 giờ đầu, giúp phòng lây viêm gan B từ mẹ sang con.',
      en: 'The birth dose within the first 24 hours helps prevent hepatitis B passing from mother to baby.',
    },
  },
  {
    id: 'dtp',
    name: { vi: '6in1 hoặc 5in1', en: '6-in-1 or 5-in-1' },
    short: { vi: '6in1', en: '6-in-1' },
    months: [2, 3, 4, 18],
    programme: 'choice',
    route: 'injection',
    dtpSeries: true,
    minIntervalWeeks: 4,
    about: {
      vi: 'Phòng bạch hầu, ho gà, uốn ván, Hib, viêm gan B; 6in1 phòng thêm bại liệt trong cùng một mũi.',
      en: 'Protects against diphtheria, whooping cough, tetanus, Hib and hepatitis B; 6-in-1 adds polio in the same shot.',
    },
  },
  {
    id: 'polio',
    name: { vi: 'Bại liệt', en: 'Polio' },
    short: { vi: 'Bại liệt', en: 'Polio' },
    months: [2, 3, 4],
    programme: 'epi',
    route: 'oral',
    only5in1: true,
    about: {
      vi: 'Trên lịch 5in1 của Tiêm chủng mở rộng, bại liệt được cho uống hoặc tiêm thêm.',
      en: 'On the free programme’s 5-in-1 schedule, polio is given separately, by mouth or injection.',
    },
  },
  {
    id: 'rota',
    name: { vi: 'Rota', en: 'Rotavirus' },
    short: { vi: 'Rota', en: 'Rotavirus' },
    months: [2, 3, 4],
    programme: 'service',
    route: 'oral',
    minIntervalWeeks: 4,
    about: {
      vi: 'Vắc xin dạng uống, giúp phòng tiêu chảy do virus Rota.',
      en: 'An oral vaccine that helps prevent diarrhoea caused by rotavirus.',
    },
  },
  {
    id: 'pcv',
    name: { vi: 'Phế cầu', en: 'Pneumococcal' },
    short: { vi: 'Phế cầu', en: 'Pneumococcal' },
    months: [2, 3, 4, 12],
    programme: 'service',
    route: 'injection',
    about: {
      vi: 'Giúp phòng viêm phổi, viêm màng não và viêm tai giữa do phế cầu.',
      en: 'Helps protect against pneumonia, meningitis and ear infections caused by pneumococcus.',
    },
  },
  {
    id: 'flu',
    name: { vi: 'Cúm mùa', en: 'Seasonal flu' },
    short: { vi: 'Cúm', en: 'Flu' },
    months: [6, 7],
    programme: 'service',
    route: 'injection',
    yearly: true,
    about: {
      vi: 'Năm đầu tiêm 2 mũi, sau đó nhắc lại hằng năm.',
      en: 'Two doses the first year, then once a year.',
    },
  },
  {
    id: 'menbc',
    name: { vi: 'Não mô cầu BC', en: 'Meningococcal B+C' },
    short: { vi: 'Não mô cầu BC', en: 'Meningococcal B+C' },
    months: [6, 8],
    programme: 'service',
    route: 'injection',
    about: {
      vi: 'Giúp phòng viêm màng não do não mô cầu nhóm B và C.',
      en: 'Helps protect against meningitis caused by meningococcus groups B and C.',
    },
  },
  {
    id: 'menacyw',
    name: { vi: 'Não mô cầu ACYW', en: 'Meningococcal ACYW' },
    short: { vi: 'Não mô cầu ACYW', en: 'Meningococcal ACYW' },
    months: [9, 12],
    programme: 'service',
    route: 'injection',
    about: {
      vi: 'Giúp phòng viêm màng não do não mô cầu nhóm A, C, Y, W.',
      en: 'Helps protect against meningitis caused by meningococcus groups A, C, Y and W.',
    },
  },
  {
    id: 'measles',
    name: { vi: 'Sởi', en: 'Measles' },
    short: { vi: 'Sởi', en: 'Measles' },
    months: [9],
    programme: 'epi',
    route: 'injection',
    about: { vi: 'Giúp phòng bệnh sởi.', en: 'Helps protect against measles.' },
  },
  {
    id: 'mmr',
    name: { vi: 'Sởi – Quai bị – Rubella', en: 'Measles – Mumps – Rubella' },
    short: { vi: 'Sởi – Quai bị – Rubella', en: 'MMR' },
    months: [12, 18],
    programme: 'service',
    route: 'injection',
    about: {
      vi: 'Giúp phòng sởi, quai bị và rubella trong cùng một mũi.',
      en: 'Helps protect against measles, mumps and rubella in one shot.',
    },
  },
  {
    id: 'je',
    name: { vi: 'Viêm não Nhật Bản', en: 'Japanese encephalitis' },
    short: { vi: 'Viêm não NB', en: 'Japanese enceph.' },
    months: [9, 10, 24],
    programme: 'epi',
    route: 'injection',
    about: {
      vi: 'Giúp phòng viêm não Nhật Bản do muỗi truyền.',
      en: 'Helps protect against Japanese encephalitis, spread by mosquitoes.',
    },
  },
  {
    id: 'varicella',
    name: { vi: 'Thuỷ đậu', en: 'Chickenpox' },
    short: { vi: 'Thuỷ đậu', en: 'Chickenpox' },
    months: [9, 15],
    programme: 'service',
    route: 'injection',
    about: { vi: 'Giúp phòng bệnh thuỷ đậu.', en: 'Helps protect against chickenpox.' },
  },
  {
    id: 'hepa',
    name: { vi: 'Viêm gan A', en: 'Hepatitis A' },
    short: { vi: 'Viêm gan A', en: 'Hepatitis A' },
    months: [13, 18],
    programme: 'service',
    route: 'injection',
    about: { vi: 'Giúp phòng viêm gan A.', en: 'Helps protect against hepatitis A.' },
  },
];

/** `rota_1`: one document per dose. */
export const vaccineDoseKeySchema = z.string().regex(/^[a-z0-9]{2,12}_[1-9]$/);
export const doseKeyOf = (vaccineId: string, dose: number) => `${vaccineId}_${dose}`;

/** VX 3 / VX 5 "Nơi tiêm": Bệnh viện · Dịch vụ · Trạm y tế. */
export const vaccinePlaces = ['hospital', 'service', 'station'] as const;
export type VaccinePlace = (typeof vaccinePlaces)[number];

export const vaccineLimits = {
  facilityMax: 80,
  reactionMax: 300,
  reasonMax: 200,
  bookPhotosMax: 10,
} as const;

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const clock = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);

/**
 * `babies/{babyId}/vaccines/{doseKey}`: a dose given (date optional for the setup list, VX 0),
 * declined ("Không tiêm mũi này", VX 9a) or rescheduled ("Dời lịch"). Undone doses have no document.
 */
export const vaccineDoseSchema = z.object({
  vaccineId: z.string(),
  dose: z.number().int().min(1).max(9),
  status: z.enum(['given', 'declined', 'planned']),
  givenOn: isoDate.nullable(),
  givenTime: clock.nullable(),
  place: z.enum(vaccinePlaces).nullable(),
  facility: z.string().max(vaccineLimits.facilityMax).nullable(),
  reaction: z.string().max(vaccineLimits.reactionMax).nullable(),
  declineReason: z.string().max(vaccineLimits.reasonMax).nullable(),
  /** "Dời lịch": the new planned date. */
  plannedOn: isoDate.nullable(),
  photoPath: z.string().nullable(),
  createdBy: z.string(),
  author: authorSchema,
  createdAt: z.date(),
  updatedAt: z.date(),
  updatedBy: z.string(),
});
export type VaccineDose = z.infer<typeof vaccineDoseSchema>;

/** `babies/{babyId}/vaccinePlan/main`: Cùng nuôi's choices for the book. */
export const vaccinePlanSchema = z.object({
  /** VX 2 "Chọn một trong hai"; null until chosen (the matrix shows "6in1 hoặc 5in1"). */
  dtp: z.enum(['6in1', '5in1']).nullable(),
  /** VX 0 done or skipped. */
  setupDone: z.boolean(),
  /**
   * The date the schedule counts from (the date of birth), kept by Cùng nuôi so caregivers, who
   * cannot read the private profile, see the same planned dates (P-133).
   */
  scheduleFrom: isoDate.nullable(),
  /** VX 2 "Nhắc trước 3 ngày" for every milestone. */
  remind: z.boolean(),
  recipients: z.array(z.string()).max(20),
  bookPhotos: z.array(z.string()).max(vaccineLimits.bookPhotosMax),
  updatedAt: z.date(),
  updatedBy: z.string(),
});
export type VaccinePlan = z.infer<typeof vaccinePlanSchema>;

/** Rows that apply to a plan (polio only on the 5in1 path). */
export const scheduleFor = (dtp: '6in1' | '5in1' | null) =>
  vaccineSchedule.filter((v) => !v.only5in1 || dtp === '5in1');

/**
 * DOB + [months] calendar months; a day the month does not have falls back to its last day
 * (31 Jan + 1 month → 28/29 Feb). Dates are YYYY-MM-DD in the baby's zone.
 */
export function plannedDate(dateOfBirth: string, months: number): string {
  const [y, m, d] = dateOfBirth.split('-').map(Number) as [number, number, number];
  const total = m - 1 + months;
  const year = y + Math.floor(total / 12);
  const month = (total % 12) + 1;
  const last = new Date(Date.UTC(year, month, 0)).getUTCDate();
  const day = Math.min(d, last);
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}
