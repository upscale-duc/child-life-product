import type { VaccineDef } from './vaccines.js';

/**
 * Routine childhood schedules outside Việt Nam (D-084), for the Sổ tiêm chủng of families who live
 * there (`families/{id}.country`, D-078). Taken from each country's official schedule on the date
 * in `checkedOn`; engineering drafts awaiting medical review, like the Việt Nam rows. Việt Nam's
 * schedule stays `vaccineSchedule` (editable on the portal as reference data, P-138); these ship
 * with the app. The Dart app reads a generated copy (apps/mobile/tool/vaccine_schedule.mjs).
 */
export interface CountryVaccineSchedule {
  country: string;
  /** "Lịch tiêm chủng trẻ em của CDC (Hoa Kỳ)": named on the book so parents know whose it is. */
  programmeName: { vi: string; en: string };
  sources: readonly { label: string; url: string }[];
  /** YYYY-MM-DD: when the official pages were read. */
  checkedOn: string;
  defs: readonly VaccineDef[];
}

export const countryVaccineSchedules: Readonly<Record<string, CountryVaccineSchedule>> = {
  US: {
    country: 'US',
    programmeName: {
      vi: 'Lịch tiêm chủng trẻ em của CDC (Hoa Kỳ)',
      en: 'CDC child immunisation schedule (United States)',
    },
    sources: [
      {
        label:
          'CDC — Child and adolescent immunization schedule by age (2025 schedule, addendum July 2, 2025; the version CDC posts on 2026-10-18)',
        url: 'https://www.cdc.gov/vaccines/hcp/imz-schedules/child-adolescent-age.html',
      },
      {
        label: 'CDC — Child immunization schedule notes (same version)',
        url: 'https://www.cdc.gov/vaccines/hcp/imz-schedules/child-adolescent-notes.html',
      },
      {
        label: 'CDC — Recommended immunizations for birth through 6 years old (parent version)',
        url: 'https://www.cdc.gov/vaccines/imz-schedules/child-easyread.html',
      },
      {
        label: 'CDC — Immunization schedules index (shows the July 2, 2025 schedules as current)',
        url: 'https://www.cdc.gov/vaccines/hcp/imz-schedules/index.html',
      },
      {
        label:
          'CDC — Hepatitis B immunization fact sheet (December 16, 2025 birth-dose change, later stayed)',
        url: 'https://www.cdc.gov/media/releases/2025/fact-sheet-hepatitis-b-immunization.html',
      },
      {
        label: 'CDC — January 5, 2026 release on the revised childhood schedule (later stayed)',
        url: 'https://www.cdc.gov/media/releases/2026/2026-cdc-acts-on-presidential-memorandum-to-update-childhood-immunization-schedule.html',
      },
      {
        label: 'CDC — About vitamin K deficiency bleeding (vitamin K shot at birth)',
        url: 'https://www.cdc.gov/vitamin-k-deficiency/about/index.html',
      },
    ],
    checkedOn: '2026-10-18',
    defs: [
      {
        id: 'vitk',
        name: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        short: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Tiêm một lần ngay sau sinh (trong 6 giờ đầu), giúp phòng xuất huyết do thiếu vitamin K.',
          en: 'One shot right after birth (within the first 6 hours) to help prevent bleeding from vitamin K deficiency.',
        },
      },
      {
        id: 'hepb',
        name: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        short: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        months: [0, 1, 6],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Mũi sơ sinh trong 24 giờ đầu, sau đó lúc 1–2 tháng và 6–18 tháng; giúp phòng lây viêm gan B từ mẹ sang con và về sau.',
          en: 'A birth dose within 24 hours, then doses at 1–2 months and 6–18 months; helps prevent hepatitis B from the mother and later in life.',
        },
      },
      {
        id: 'rsv',
        name: {
          vi: 'Kháng thể phòng RSV',
          en: 'RSV antibody (nirsevimab)',
        },
        short: {
          vi: 'RSV',
          en: 'RSV',
        },
        months: [0],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Một mũi kháng thể (không phải vắc xin) trước hoặc đầu mùa RSV, giúp phòng viêm phổi, viêm tiểu phế quản nặng; thường không cần nếu mẹ đã tiêm vắc xin RSV ít nhất 2 tuần trước sinh.',
          en: 'One antibody shot (not a vaccine) before or early in the RSV season to help prevent severe bronchiolitis and pneumonia; usually not needed if the mother had the RSV vaccine at least 2 weeks before birth.',
        },
      },
      {
        id: 'rota',
        name: {
          vi: 'Tiêu chảy do rota',
          en: 'Rotavirus',
        },
        short: {
          vi: 'Rota',
          en: 'Rotavirus',
        },
        months: [2, 4, 6],
        programme: 'epi',
        route: 'oral',
        minIntervalWeeks: 4,
        about: {
          vi: 'Vắc xin dạng uống, giúp phòng tiêu chảy do virus rota; tuỳ loại uống 2 hoặc 3 liều.',
          en: 'An oral vaccine that helps prevent diarrhoea caused by rotavirus; 2 or 3 doses depending on the product.',
        },
      },
      {
        id: 'dtap',
        name: {
          vi: 'Bạch hầu, ho gà, uốn ván (DTaP)',
          en: 'Diphtheria, tetanus, whooping cough (DTaP)',
        },
        short: {
          vi: 'DTaP',
          en: 'DTaP',
        },
        months: [2, 4, 6, 15, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng bạch hầu, ho gà, uốn ván; 3 mũi cơ bản, nhắc lúc 15–18 tháng và 4–6 tuổi.',
          en: 'Helps protect against diphtheria, whooping cough and tetanus; 3 primary doses, boosters at 15–18 months and 4–6 years.',
        },
      },
      {
        id: 'hib',
        name: {
          vi: 'Hib',
          en: 'Hib',
        },
        short: {
          vi: 'Hib',
          en: 'Hib',
        },
        months: [2, 4, 6, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng các bệnh nặng do vi khuẩn Hib như viêm màng não, viêm phổi; nhắc lại lúc 12–15 tháng.',
          en: 'Helps prevent serious Hib infections such as meningitis and pneumonia; booster at 12–15 months.',
        },
      },
      {
        id: 'pcv',
        name: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        short: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        months: [2, 4, 6, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng viêm phổi, viêm màng não, nhiễm trùng máu và viêm tai do phế cầu; nhắc lại lúc 12–15 tháng.',
          en: 'Helps prevent pneumonia, meningitis, blood infections and ear infections caused by pneumococcus; booster at 12–15 months.',
        },
      },
      {
        id: 'ipv',
        name: {
          vi: 'Bại liệt',
          en: 'Polio',
        },
        short: {
          vi: 'Bại liệt',
          en: 'Polio',
        },
        months: [2, 4, 6, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Vắc xin bại liệt dạng tiêm; mũi 3 lúc 6–18 tháng và mũi cuối lúc 4–6 tuổi.',
          en: 'The injected polio vaccine; dose 3 at 6–18 months and the last dose at 4–6 years.',
        },
      },
      {
        id: 'flu',
        name: {
          vi: 'Cúm',
          en: 'Flu',
        },
        short: {
          vi: 'Cúm',
          en: 'Flu',
        },
        months: [6],
        programme: 'epi',
        route: 'injection',
        yearly: true,
        about: {
          vi: 'Tiêm mỗi năm từ 6 tháng tuổi; năm đầu tiên trẻ dưới 9 tuổi cần 2 mũi cách nhau ít nhất 4 tuần.',
          en: 'Given every year from 6 months; in the first season, children under 9 need 2 doses at least 4 weeks apart.',
        },
      },
      {
        id: 'mmr',
        name: {
          vi: 'Sởi, quai bị, rubella (MMR)',
          en: 'Measles, mumps, rubella (MMR)',
        },
        short: {
          vi: 'MMR',
          en: 'MMR',
        },
        months: [12, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng sởi, quai bị và rubella; mũi 1 lúc 12–15 tháng, mũi 2 lúc 4–6 tuổi.',
          en: 'Helps protect against measles, mumps and rubella; dose 1 at 12–15 months, dose 2 at 4–6 years.',
        },
      },
      {
        id: 'var',
        name: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        short: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        months: [12, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 12,
        about: {
          vi: 'Giúp phòng bệnh thuỷ đậu; mũi 1 lúc 12–15 tháng, mũi 2 lúc 4–6 tuổi.',
          en: 'Helps protect against chickenpox; dose 1 at 12–15 months, dose 2 at 4–6 years.',
        },
      },
      {
        id: 'hepa',
        name: {
          vi: 'Viêm gan A',
          en: 'Hepatitis A',
        },
        short: {
          vi: 'Viêm gan A',
          en: 'Hepatitis A',
        },
        months: [12, 18],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 26,
        about: {
          vi: 'Giúp phòng viêm gan A lây qua thức ăn, nước uống; 2 mũi trong khoảng 12–23 tháng, cách nhau ít nhất 6 tháng.',
          en: 'Helps protect against hepatitis A, spread through food and water; 2 doses between 12 and 23 months, at least 6 months apart.',
        },
      },
    ],
  },
  AU: {
    country: 'AU',
    programmeName: {
      vi: 'Chương trình Tiêm chủng Quốc gia (Úc)',
      en: 'National Immunisation Program (Australia)',
    },
    sources: [
      {
        label:
          'Victorian Department of Health — Immunisation schedule Victoria, October 2026 (reproduces the National Immunisation Program schedule)',
        url: 'https://www.health.vic.gov.au/sites/default/files/2026-10/immunisation-schedule-victoria-october-2026.pdf',
      },
      {
        label:
          'Victorian Department of Health — Immunisation schedule Victoria and vaccine eligibility criteria (updated 1 October 2026)',
        url: 'https://www.health.vic.gov.au/immunisation/immunisation-schedule-victoria-and-vaccine-eligibility-criteria',
      },
      {
        label:
          'NSW Health — NSW immunisation schedule (vaccines funded under the NIP as of 1 October 2026)',
        url: 'https://www.health.nsw.gov.au/immunisation/app/Pages/schedule.aspx',
      },
      {
        label:
          'Victorian Department of Health — RSV immunisation (nirsevimab infant program 2026, updated 10 July 2026)',
        url: 'https://www.health.vic.gov.au/immunisation/respiratory-syncytial-virus-immunisation',
      },
      {
        label:
          'Better Health Channel (Victorian Department of Health) — Vitamin K and newborn babies',
        url: 'https://www.betterhealth.vic.gov.au/health/healthyliving/vitamin-k-and-newborn-babies',
      },
    ],
    checkedOn: '2026-10-18',
    defs: [
      {
        id: 'vitk',
        name: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        short: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Tiêm một lần sau sinh, giúp phòng xuất huyết do thiếu vitamin K.',
          en: 'Given once after birth to help prevent bleeding from vitamin K deficiency.',
        },
      },
      {
        id: 'hepb',
        name: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        short: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        months: [0],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi sơ sinh trong 7 ngày đầu (tốt nhất trong 24 giờ), giúp phòng lây viêm gan B từ mẹ sang con; các mũi sau nằm trong mũi 6in1.',
          en: 'The birth dose within 7 days (ideally within 24 hours) helps prevent hepatitis B passing from mother to baby; later doses are in the 6-in-1.',
        },
      },
      {
        id: 'rsv',
        name: {
          vi: 'Kháng thể phòng RSV',
          en: 'RSV antibody (nirsevimab)',
        },
        short: {
          vi: 'RSV',
          en: 'RSV',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Một mũi kháng thể (không phải vắc xin), thường tiêm trước khi xuất viện cho bé có mẹ chưa tiêm vắc xin RSV khi mang thai; giúp phòng viêm tiểu phế quản, viêm phổi nặng.',
          en: 'One antibody shot (not a vaccine), usually given before leaving hospital to babies whose mother did not have the RSV vaccine in pregnancy; helps prevent severe bronchiolitis and pneumonia.',
        },
      },
      {
        id: 'hexa',
        name: {
          vi: '6in1',
          en: '6-in-1',
        },
        short: {
          vi: '6in1',
          en: '6-in-1',
        },
        months: [2, 4, 6],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Một mũi phòng 6 bệnh: bạch hầu, ho gà, uốn ván, bại liệt, viêm gan B và Hib; có thể tiêm mũi đầu từ 6 tuần tuổi.',
          en: 'One shot against 6 diseases: diphtheria, whooping cough, tetanus, polio, hepatitis B and Hib; the first dose can be given from 6 weeks.',
        },
      },
      {
        id: 'rota',
        name: {
          vi: 'Tiêu chảy do rota',
          en: 'Rotavirus',
        },
        short: {
          vi: 'Rota',
          en: 'Rotavirus',
        },
        months: [2, 4],
        programme: 'epi',
        route: 'oral',
        minIntervalWeeks: 4,
        about: {
          vi: 'Vắc xin dạng uống, giúp phòng tiêu chảy do virus rota; liều 1 trước 15 tuần tuổi, liều 2 trước 25 tuần tuổi.',
          en: 'An oral vaccine that helps prevent diarrhoea caused by rotavirus; dose 1 before 15 weeks and dose 2 before 25 weeks of age.',
        },
      },
      {
        id: 'pcv',
        name: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        short: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        months: [2, 4, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng viêm phổi, viêm màng não, nhiễm trùng máu và viêm tai do phế cầu.',
          en: 'Helps prevent pneumonia, meningitis, blood infections and ear infections caused by pneumococcus.',
        },
      },
      {
        id: 'menb',
        name: {
          vi: 'Não mô cầu B',
          en: 'Meningococcal B',
        },
        short: {
          vi: 'Não mô cầu B',
          en: 'MenB',
        },
        months: [2, 4, 12],
        programme: 'service',
        route: 'injection',
        minIntervalWeeks: 8,
        about: {
          vi: 'Giúp phòng viêm màng não, nhiễm trùng máu do não mô cầu nhóm B; được khuyến nghị cho mọi trẻ nhỏ nhưng chỉ miễn phí ở một số bang hoặc nhóm trẻ.',
          en: 'Helps prevent meningitis and blood infection caused by meningococcus group B; recommended for all young children but free only in some states or groups.',
        },
      },
      {
        id: 'flu',
        name: {
          vi: 'Cúm',
          en: 'Flu',
        },
        short: {
          vi: 'Cúm',
          en: 'Flu',
        },
        months: [6],
        programme: 'epi',
        route: 'injection',
        yearly: true,
        about: {
          vi: 'Tiêm mỗi năm, miễn phí từ 6 tháng đến dưới 5 tuổi; lần đầu tiêm, trẻ dưới 2 tuổi cần 2 mũi cách nhau 4 tuần.',
          en: 'Given every year, free from 6 months to under 5 years; children under 2 having it for the first time need 2 doses 4 weeks apart.',
        },
      },
      {
        id: 'menacwy',
        name: {
          vi: 'Não mô cầu ACWY',
          en: 'Meningococcal ACWY',
        },
        short: {
          vi: 'Não mô cầu ACWY',
          en: 'MenACWY',
        },
        months: [12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Giúp phòng viêm màng não, nhiễm trùng máu do não mô cầu nhóm A, C, W và Y.',
          en: 'Helps prevent meningitis and blood infection caused by meningococcus groups A, C, W and Y.',
        },
      },
      {
        id: 'mmr',
        name: {
          vi: 'Sởi, quai bị, rubella',
          en: 'Measles, mumps, rubella',
        },
        short: {
          vi: 'Sởi, quai bị, rubella',
          en: 'MMR',
        },
        months: [12, 18],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng sởi, quai bị và rubella; mũi 18 tháng là mũi phối hợp có thêm thuỷ đậu (MMRV).',
          en: 'Helps protect against measles, mumps and rubella; the 18-month dose is a combined shot that also covers chickenpox (MMRV).',
        },
      },
      {
        id: 'var',
        name: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        short: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        months: [18],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Giúp phòng bệnh thuỷ đậu; tiêm trong mũi phối hợp MMRV lúc 18 tháng.',
          en: 'Helps protect against chickenpox; given in the combined MMRV shot at 18 months.',
        },
      },
      {
        id: 'dtapb',
        name: {
          vi: 'Nhắc bạch hầu, ho gà, uốn ván',
          en: 'Diphtheria, tetanus, whooping cough booster',
        },
        short: {
          vi: 'Nhắc DTaP',
          en: 'DTaP booster',
        },
        months: [18, 48],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi nhắc bạch hầu, ho gà, uốn ván lúc 18 tháng; mũi 4 tuổi có thêm bại liệt.',
          en: 'Booster for diphtheria, whooping cough and tetanus at 18 months; the 4-year dose also covers polio.',
        },
      },
      {
        id: 'hibb',
        name: {
          vi: 'Nhắc Hib',
          en: 'Hib booster',
        },
        short: {
          vi: 'Nhắc Hib',
          en: 'Hib booster',
        },
        months: [18],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi nhắc giúp duy trì bảo vệ khỏi các bệnh nặng do Hib như viêm màng não, viêm phổi.',
          en: 'A booster that keeps up protection against serious Hib infections such as meningitis and pneumonia.',
        },
      },
    ],
  },
  GB: {
    country: 'GB',
    programmeName: {
      vi: 'Lịch tiêm chủng định kỳ của NHS (Anh)',
      en: 'NHS routine childhood vaccination schedule (England)',
    },
    sources: [
      {
        label: 'GOV.UK (UKHSA) — Complete routine immunisation schedule from 1 September 2026',
        url: 'https://www.gov.uk/government/publications/the-complete-routine-immunisation-schedule/complete-routine-immunisation-schedule-from-1-july-2026',
      },
      {
        label:
          'GOV.UK (UKHSA) — The complete routine immunisation schedule (all versions and update history)',
        url: 'https://www.gov.uk/government/publications/the-complete-routine-immunisation-schedule',
      },
      {
        label: 'NHS — NHS vaccinations and when to have them',
        url: 'https://www.nhs.uk/vaccinations/nhs-vaccinations-and-when-to-have-them/',
      },
      {
        label: 'NHS — Child flu vaccine',
        url: 'https://www.nhs.uk/vaccinations/child-flu-vaccine/',
      },
      {
        label: 'Newcastle upon Tyne Hospitals NHS Foundation Trust — Vitamin K',
        url: 'https://www.newcastle-hospitals.nhs.uk/services/maternity/labour-and-birth/vitamin-k/',
      },
    ],
    checkedOn: '2026-10-18',
    defs: [
      {
        id: 'vitk',
        name: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        short: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Tiêm một lần ngay sau sinh (hoặc cho uống vài liều nếu bố mẹ chọn), giúp phòng xuất huyết do thiếu vitamin K.',
          en: 'Offered as one injection soon after birth (or several doses by mouth if parents prefer) to help prevent bleeding from vitamin K deficiency.',
        },
      },
      {
        id: 'sixin1',
        name: {
          vi: 'Bạch hầu, ho gà, uốn ván, bại liệt, Hib, viêm gan B (6 trong 1)',
          en: 'Diphtheria, whooping cough, tetanus, polio, Hib, hepatitis B (6-in-1)',
        },
        short: {
          vi: '6in1',
          en: '6-in-1',
        },
        months: [2, 3, 4, 18],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Một mũi phòng 6 bệnh: bạch hầu, ho gà, uốn ván, bại liệt, Hib và viêm gan B. Mũi lúc 18 tháng dành cho trẻ sinh từ 1/7/2024 trở đi.',
          en: 'One shot against six diseases: diphtheria, whooping cough, tetanus, polio, Hib and hepatitis B. The 18-month dose is for children born on or after 1 July 2024.',
        },
      },
      {
        id: 'rota',
        name: {
          vi: 'Tiêu chảy do rota',
          en: 'Rotavirus',
        },
        short: {
          vi: 'Rota',
          en: 'Rotavirus',
        },
        months: [2, 3],
        programme: 'epi',
        route: 'oral',
        about: {
          vi: 'Vắc xin dạng uống, giúp phòng tiêu chảy và nôn do virus rota.',
          en: 'An oral vaccine that helps prevent diarrhoea and vomiting caused by rotavirus.',
        },
      },
      {
        id: 'menb',
        name: {
          vi: 'Não mô cầu nhóm B',
          en: 'Meningococcal group B (MenB)',
        },
        short: {
          vi: 'Não mô cầu B',
          en: 'MenB',
        },
        months: [2, 3, 12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Giúp phòng viêm màng não và nhiễm khuẩn huyết do não mô cầu nhóm B.',
          en: 'Helps protect against meningitis and blood poisoning caused by meningococcal group B bacteria.',
        },
      },
      {
        id: 'pcv',
        name: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        short: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        months: [4, 12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Giúp phòng viêm phổi, viêm màng não và nhiễm khuẩn huyết do phế cầu.',
          en: 'Helps protect against pneumonia, meningitis and blood infections caused by pneumococcus.',
        },
      },
      {
        id: 'mmrv',
        name: {
          vi: 'Sởi, quai bị, rubella, thuỷ đậu (MMRV)',
          en: 'Measles, mumps, rubella and chickenpox (MMRV)',
        },
        short: {
          vi: 'MMRV',
          en: 'MMRV',
        },
        months: [12, 18],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Một mũi phòng 4 bệnh: sởi, quai bị, rubella và thuỷ đậu; từ tháng 1/2026 thay cho mũi MMR.',
          en: 'One shot against measles, mumps, rubella and chickenpox; from January 2026 it replaces the MMR vaccine.',
        },
      },
      {
        id: 'preschool',
        name: {
          vi: 'Bạch hầu, ho gà, uốn ván, bại liệt (4 trong 1, nhắc trước tuổi đi học)',
          en: 'Diphtheria, whooping cough, tetanus, polio (4-in-1 pre-school booster)',
        },
        short: {
          vi: '4in1 nhắc lại',
          en: '4-in-1 booster',
        },
        months: [40],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi nhắc trước khi đi học, từ 3 tuổi 4 tháng, giúp duy trì miễn dịch với bạch hầu, ho gà, uốn ván và bại liệt.',
          en: 'A booster before starting school, from 3 years 4 months, to keep up protection against diphtheria, whooping cough, tetanus and polio.',
        },
      },
      {
        id: 'flu',
        name: {
          vi: 'Cúm (xịt mũi)',
          en: 'Flu (nasal spray)',
        },
        short: {
          vi: 'Cúm',
          en: 'Flu',
        },
        months: [24],
        programme: 'epi',
        route: 'injection',
        yearly: true,
        about: {
          vi: 'Vắc xin cúm dạng xịt mũi, mỗi năm một lần từ 2 tuổi, thường vào mùa thu; trẻ không dùng được dạng xịt sẽ được tiêm.',
          en: 'A nasal spray flu vaccine given once a year from age 2, usually in autumn; children who cannot have the spray are offered an injection.',
        },
      },
    ],
  },
  SG: {
    country: 'SG',
    programmeName: {
      vi: 'Lịch tiêm chủng quốc gia cho trẻ em (Singapore)',
      en: 'National Childhood Immunisation Schedule (Singapore)',
    },
    sources: [
      {
        label: 'CDA — Vaccinations (National Childhood Immunisation Schedule, Table 1)',
        url: 'https://www.cda.gov.sg/public/vaccinations/',
      },
      {
        label: 'CDA — National Childhood Immunisation Schedule, updated 12 October 2026 (PDF)',
        url: 'https://isomer-user-content.by.gov.sg/18/34009f97-7100-4624-8eba-89fd5a2b4e3d/NCIS_October%202026.pdf',
      },
      {
        label: 'MOH — Childhood developmental screening and childhood vaccinations (subsidies)',
        url: 'https://www.moh.gov.sg/managing-expenses/schemes-and-subsidies/childhood-developmental-screening-and-childhood-vaccinations/',
      },
      {
        label:
          'Singapore General Hospital — Baby injections (vitamin K, hepatitis B, BCG at birth)',
        url: 'https://www.sgh.com.sg/our-specialties/neonatal-and-developmental-medicine/baby-injections',
      },
    ],
    checkedOn: '2026-10-18',
    defs: [
      {
        id: 'vitk',
        name: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        short: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Tiêm một lần vào đùi ngay sau sinh, giúp phòng xuất huyết do thiếu vitamin K.',
          en: 'Given once into the thigh soon after birth to help prevent bleeding from vitamin K deficiency.',
        },
      },
      {
        id: 'bcg',
        name: {
          vi: 'Lao (BCG)',
          en: 'Tuberculosis (BCG)',
        },
        short: {
          vi: 'Lao',
          en: 'BCG',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Tiêm ở bệnh viện sau sinh, giúp phòng bệnh lao, nhất là các thể lao nặng ở trẻ nhỏ.',
          en: 'Given in hospital after birth to help protect against tuberculosis, especially its severe forms in young children.',
        },
      },
      {
        id: 'hepb',
        name: {
          vi: 'Viêm gan B (mũi sơ sinh)',
          en: 'Hepatitis B (birth dose)',
        },
        short: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        months: [0],
        programme: 'hospital',
        route: 'injection',
        about: {
          vi: 'Mũi sơ sinh trong 24 giờ đầu; mũi 2 và 3 nằm trong vắc xin 6 trong 1 lúc 2 và 6 tháng.',
          en: 'The birth dose within the first 24 hours; doses 2 and 3 are part of the 6-in-1 vaccine at 2 and 6 months.',
        },
      },
      {
        id: 'sixfive',
        name: {
          vi: 'Bạch hầu, ho gà, uốn ván, bại liệt, Hib (6 trong 1 / 5 trong 1)',
          en: 'Diphtheria, whooping cough, tetanus, polio, Hib (6-in-1 / 5-in-1)',
        },
        short: {
          vi: '6in1 / 5in1',
          en: '6-in-1 / 5-in-1',
        },
        months: [2, 4, 6, 18],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Phòng bạch hầu, ho gà, uốn ván, bại liệt và Hib; lúc 2 và 6 tháng dùng 6 trong 1 (thêm viêm gan B), lúc 4 và 18 tháng dùng 5 trong 1.',
          en: 'Protects against diphtheria, whooping cough, tetanus, polio and Hib; the 6-in-1 (adding hepatitis B) is used at 2 and 6 months and the 5-in-1 at 4 and 18 months.',
        },
      },
      {
        id: 'pcv',
        name: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        short: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        months: [4, 6, 12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Giúp phòng viêm phổi, viêm màng não và viêm tai giữa do phế cầu.',
          en: 'Helps protect against pneumonia, meningitis and ear infections caused by pneumococcus.',
        },
      },
      {
        id: 'mmr',
        name: {
          vi: 'Sởi, quai bị, rubella (MMR)',
          en: 'Measles, mumps, rubella (MMR)',
        },
        short: {
          vi: 'MMR',
          en: 'MMR',
        },
        months: [12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi 1 phòng sởi, quai bị, rubella lúc 12 tháng, tiêm riêng với thuỷ đậu; mũi 2 là MMRV lúc 15 tháng.',
          en: 'The first dose against measles, mumps and rubella at 12 months, given separately from chickenpox; the second dose is MMRV at 15 months.',
        },
      },
      {
        id: 'var',
        name: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox (varicella)',
        },
        short: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        months: [12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi 1 phòng thuỷ đậu lúc 12 tháng, tiêm riêng với MMR; mũi 2 nằm trong MMRV lúc 15 tháng.',
          en: 'The first dose against chickenpox at 12 months, given separately from MMR; the second dose is part of MMRV at 15 months.',
        },
      },
      {
        id: 'mmrv',
        name: {
          vi: 'Sởi, quai bị, rubella, thuỷ đậu (MMRV)',
          en: 'Measles, mumps, rubella and chickenpox (MMRV)',
        },
        short: {
          vi: 'MMRV',
          en: 'MMRV',
        },
        months: [15],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi 2 của sởi, quai bị, rubella và thuỷ đậu, gộp trong một mũi lúc 15 tháng.',
          en: 'The second dose against measles, mumps, rubella and chickenpox, combined in one shot at 15 months.',
        },
      },
      {
        id: 'flu',
        name: {
          vi: 'Cúm mùa',
          en: 'Seasonal flu',
        },
        short: {
          vi: 'Cúm',
          en: 'Flu',
        },
        months: [6, 7],
        programme: 'epi',
        route: 'injection',
        yearly: true,
        minIntervalWeeks: 4,
        about: {
          vi: 'Khuyến cáo cho mọi trẻ từ 6 tháng đến dưới 5 tuổi; lần đầu tiêm 2 mũi cách nhau 4 tuần, sau đó mỗi năm hoặc mỗi mùa cúm một mũi.',
          en: 'Recommended for all children from 6 months to under 5 years; two doses 4 weeks apart the first time, then one dose each year or flu season.',
        },
      },
    ],
  },
  JP: {
    country: 'JP',
    programmeName: {
      vi: 'Lịch tiêm chủng định kỳ của Nhật Bản',
      en: 'Japan routine immunisation schedule',
    },
    sources: [
      {
        label:
          'Japan Institute for Health Security (JIHS, formerly NIID) — Routine immunisation schedule and notes, as of 1 August 2026 (ver. 2026.08.01)',
        url: 'https://id-info.jihs.go.jp/immunization/schedule/2026/20260801_routine-note_r1.pdf',
      },
      {
        label:
          'Japan Institute for Health Security (JIHS) — Immunisation schedule page (routine and optional vaccines, updated 24 September 2026)',
        url: 'https://id-info.jihs.go.jp/immunization/schedule/currently/index.html',
      },
      {
        label:
          'Ministry of Health, Labour and Welfare — Vaccination (予防接種) information, standard ages for routine vaccines',
        url: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/kenkou_iryou/kenkou/kekkaku-kansenshou/yobou-sesshu/index.html',
      },
      {
        label:
          'Japan Pediatric Society and 15 societies — Proposal on preventing vitamin K deficiency bleeding in newborns and infants (30 November 2021)',
        url: 'https://www.jaog.or.jp/wp/wp-content/uploads/2021/12/20211215.pdf',
      },
    ],
    checkedOn: '2026-10-18',
    defs: [
      {
        id: 'vitk',
        name: {
          vi: 'Vitamin K2 (uống)',
          en: 'Vitamin K2 (by mouth)',
        },
        short: {
          vi: 'Vitamin K',
          en: 'Vitamin K',
        },
        months: [0, 1],
        programme: 'hospital',
        route: 'oral',
        about: {
          vi: 'Siro vitamin K2 cho uống khi bé bắt đầu bú, lúc 1 tuần tuổi và lúc khám 1 tháng; nhiều nơi cho uống mỗi tuần đến 3 tháng. Giúp phòng xuất huyết do thiếu vitamin K.',
          en: 'Vitamin K2 syrup by mouth when feeding starts, at 1 week and at the 1-month check; many hospitals give it weekly until 3 months. Helps prevent bleeding from vitamin K deficiency.',
        },
      },
      {
        id: 'hepb',
        name: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        short: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        months: [2, 3, 7],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Ba mũi trong năm đầu, mũi 3 khoảng 7–8 tháng tuổi. Bé có mẹ mang virus viêm gan B được tiêm ngay sau sinh theo lịch riêng.',
          en: 'Three doses in the first year, the third at about 7–8 months. Babies of mothers with hepatitis B start at birth on a separate schedule.',
        },
      },
      {
        id: 'rota',
        name: {
          vi: 'Tiêu chảy do rota',
          en: 'Rotavirus',
        },
        short: {
          vi: 'Rota',
          en: 'Rotavirus',
        },
        months: [2, 3, 4],
        programme: 'epi',
        route: 'oral',
        minIntervalWeeks: 4,
        about: {
          vi: 'Vắc xin dạng uống, giúp phòng tiêu chảy do virus rota. Có loại 2 liều và loại 3 liều; liều đầu cần uống trước 15 tuần tuổi.',
          en: 'An oral vaccine that helps prevent diarrhoea caused by rotavirus. There is a 2-dose and a 3-dose type; the first dose must be given before 15 weeks of age.',
        },
      },
      {
        id: 'fivein1',
        name: {
          vi: 'Bạch hầu, ho gà, uốn ván, bại liệt, Hib (5 trong 1)',
          en: 'Diphtheria, whooping cough, tetanus, polio, Hib (5-in-1)',
        },
        short: {
          vi: '5 trong 1',
          en: '5-in-1',
        },
        months: [2, 3, 4, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 3,
        about: {
          vi: 'Một mũi phòng 5 bệnh: bạch hầu, ho gà, uốn ván, bại liệt và Hib. Ba mũi từ 2 tháng tuổi, mũi nhắc khoảng 1 tuổi.',
          en: 'One shot against five diseases: diphtheria, whooping cough, tetanus, polio and Hib. Three doses from 2 months, a booster at about 1 year.',
        },
      },
      {
        id: 'pcv',
        name: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        short: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        months: [2, 3, 4, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng viêm phổi, viêm màng não và nhiễm trùng máu do phế cầu. Mũi nhắc lúc 12–15 tháng tuổi.',
          en: 'Helps protect against pneumonia, meningitis and blood infections caused by pneumococcus. Booster at 12–15 months.',
        },
      },
      {
        id: 'bcg',
        name: {
          vi: 'Lao (BCG)',
          en: 'Tuberculosis (BCG)',
        },
        short: {
          vi: 'Lao',
          en: 'BCG',
        },
        months: [5],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Tiêm một lần lúc 5–8 tháng tuổi, giúp phòng các thể lao nặng ở trẻ nhỏ.',
          en: 'Given once at 5–8 months; helps protect against severe forms of tuberculosis in young children.',
        },
      },
      {
        id: 'mr',
        name: {
          vi: 'Sởi, rubella (MR)',
          en: 'Measles, rubella (MR)',
        },
        short: {
          vi: 'Sởi, rubella',
          en: 'MR',
        },
        months: [12, 60],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi 1 ngay khi tròn 1 tuổi, mũi 2 trong năm trước khi vào tiểu học. Giúp phòng sởi và rubella.',
          en: 'First dose soon after the first birthday, second in the year before starting primary school. Helps protect against measles and rubella.',
        },
      },
      {
        id: 'varicella',
        name: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        short: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        months: [12, 18],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 12,
        about: {
          vi: 'Hai mũi: mũi 1 lúc 12–15 tháng tuổi, mũi 2 cách 6–12 tháng. Giúp phòng thuỷ đậu.',
          en: 'Two doses: the first at 12–15 months, the second 6–12 months later. Helps protect against chickenpox.',
        },
      },
      {
        id: 'mumps',
        name: {
          vi: 'Quai bị',
          en: 'Mumps',
        },
        short: {
          vi: 'Quai bị',
          en: 'Mumps',
        },
        months: [12, 60],
        programme: 'service',
        route: 'injection',
        about: {
          vi: 'Tiêm tự nguyện, có trả phí: mũi 1 lúc 1 tuổi, mũi 2 trong năm trước khi vào tiểu học. Giúp phòng quai bị.',
          en: 'Optional and paid: first dose at 1 year, second in the year before primary school. Helps protect against mumps.',
        },
      },
      {
        id: 'je',
        name: {
          vi: 'Viêm não Nhật Bản',
          en: 'Japanese encephalitis',
        },
        short: {
          vi: 'Viêm não NB',
          en: 'Japanese enceph.',
        },
        months: [36, 37, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 1,
        about: {
          vi: 'Lúc 3 tuổi tiêm 2 mũi cách nhau 1–4 tuần, lúc 4 tuổi tiêm mũi 3; mũi nhắc lúc 9 tuổi. Giúp phòng viêm não Nhật Bản.',
          en: 'Two doses 1–4 weeks apart at age 3, a third at age 4, and a booster at 9. Helps protect against Japanese encephalitis.',
        },
      },
      {
        id: 'flu',
        name: {
          vi: 'Cúm',
          en: 'Flu',
        },
        short: {
          vi: 'Cúm',
          en: 'Flu',
        },
        months: [6, 7],
        programme: 'service',
        route: 'injection',
        yearly: true,
        about: {
          vi: 'Tiêm tự nguyện, có trả phí, từ 6 tháng tuổi. Trẻ dưới 13 tuổi tiêm 2 mũi mỗi mùa, cách nhau 2–4 tuần, trước khoảng giữa tháng 12.',
          en: 'Optional and paid, from 6 months. Children under 13 get two doses each season, 2–4 weeks apart, ideally by mid-December.',
        },
      },
    ],
  },
  KR: {
    country: 'KR',
    programmeName: {
      vi: 'Lịch tiêm chủng quốc gia của Hàn Quốc',
      en: 'South Korea National Immunization Program schedule',
    },
    sources: [
      {
        label:
          "Korea Disease Control and Prevention Agency (KDCA) — Children's national immunisation standard schedule 2026 (표준예방접종일정표 2026)",
        url: 'https://nip.kdca.go.kr/irhp/images/egovframework/rte/infm/Immunization_Schedule_for_Children_2026.jpg',
      },
      {
        label:
          'Korea Disease Control and Prevention Agency (KDCA) — National Immunization Program, vaccination information page',
        url: 'https://nip.kdca.go.kr/irhp/infm/goVcntInfo.do?menuLv=1&menuCd=115',
      },
      {
        label:
          'Korea Disease Control and Prevention Agency (KDCA) — National Immunization Program (English)',
        url: 'https://kdca.go.kr/eng/4408/subview.do',
      },
    ],
    checkedOn: '2026-10-18',
    defs: [
      {
        id: 'bcg',
        name: {
          vi: 'Lao (BCG)',
          en: 'Tuberculosis (BCG)',
        },
        short: {
          vi: 'Lao',
          en: 'BCG',
        },
        months: [0],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Tiêm trong da một lần trong 4 tuần đầu sau sinh, giúp phòng các thể lao nặng ở trẻ nhỏ.',
          en: 'One injection into the skin within 4 weeks of birth; helps protect against severe forms of tuberculosis in young children.',
        },
      },
      {
        id: 'hepb',
        name: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        short: {
          vi: 'Viêm gan B',
          en: 'Hepatitis B',
        },
        months: [0, 1, 6],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Mũi đầu ngay sau sinh, giúp phòng lây viêm gan B từ mẹ sang con. Nếu bé tiêm 6 trong 1 lúc 2, 4, 6 tháng thì không cần tiêm riêng các mũi sau.',
          en: 'The first dose at birth helps prevent hepatitis B passing from mother to baby. If your baby has the 6-in-1 at 2, 4 and 6 months, the later separate doses are not needed.',
        },
      },
      {
        id: 'dtap',
        name: {
          vi: 'Bạch hầu, ho gà, uốn ván',
          en: 'Diphtheria, whooping cough, tetanus',
        },
        short: {
          vi: 'Bạch hầu, ho gà',
          en: 'DTaP',
        },
        months: [2, 4, 6, 15, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Ba mũi lúc 2, 4, 6 tháng, nhắc lúc 15–18 tháng và 4–6 tuổi. Thường tiêm chung với bại liệt, Hib (và viêm gan B) trong một mũi 4, 5 hoặc 6 trong 1.',
          en: 'Three doses at 2, 4 and 6 months, boosters at 15–18 months and 4–6 years. Often given with polio, Hib (and hepatitis B) in one 4-, 5- or 6-in-1 shot.',
        },
      },
      {
        id: 'polio',
        name: {
          vi: 'Bại liệt',
          en: 'Polio',
        },
        short: {
          vi: 'Bại liệt',
          en: 'Polio',
        },
        months: [2, 4, 6, 48],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Vắc xin tiêm, giúp phòng bại liệt. Mũi 3 lúc 6–18 tháng, nhắc lúc 4–6 tuổi; thường nằm trong mũi tiêm kết hợp.',
          en: 'An injected vaccine that helps protect against polio. Third dose at 6–18 months, booster at 4–6 years; usually part of a combined shot.',
        },
      },
      {
        id: 'hib',
        name: {
          vi: 'Hib',
          en: 'Hib',
        },
        short: {
          vi: 'Hib',
          en: 'Hib',
        },
        months: [2, 4, 6, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng viêm màng não, viêm phổi do vi khuẩn Hib. Mũi nhắc lúc 12–15 tháng; thường nằm trong mũi tiêm kết hợp.',
          en: 'Helps protect against meningitis and pneumonia caused by Hib bacteria. Booster at 12–15 months; often part of a combined shot.',
        },
      },
      {
        id: 'pcv',
        name: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        short: {
          vi: 'Phế cầu',
          en: 'Pneumococcal',
        },
        months: [2, 4, 6, 12],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 4,
        about: {
          vi: 'Giúp phòng viêm phổi, viêm màng não và nhiễm trùng máu do phế cầu. Mũi nhắc lúc 12–15 tháng tuổi.',
          en: 'Helps protect against pneumonia, meningitis and blood infections caused by pneumococcus. Booster at 12–15 months.',
        },
      },
      {
        id: 'rota',
        name: {
          vi: 'Tiêu chảy do rota',
          en: 'Rotavirus',
        },
        short: {
          vi: 'Rota',
          en: 'Rotavirus',
        },
        months: [2, 4, 6],
        programme: 'epi',
        route: 'oral',
        minIntervalWeeks: 4,
        about: {
          vi: 'Vắc xin dạng uống, giúp phòng tiêu chảy do virus rota. Có loại 2 liều (2, 4 tháng) và loại 3 liều (2, 4, 6 tháng).',
          en: 'An oral vaccine that helps prevent diarrhoea caused by rotavirus. There is a 2-dose type (2 and 4 months) and a 3-dose type (2, 4 and 6 months).',
        },
      },
      {
        id: 'mmr',
        name: {
          vi: 'Sởi, quai bị, rubella (MMR)',
          en: 'Measles, mumps, rubella (MMR)',
        },
        short: {
          vi: 'MMR',
          en: 'MMR',
        },
        months: [12, 48],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Mũi 1 lúc 12–15 tháng, mũi 2 lúc 4–6 tuổi. Giúp phòng sởi, quai bị và rubella.',
          en: 'First dose at 12–15 months, second at 4–6 years. Helps protect against measles, mumps and rubella.',
        },
      },
      {
        id: 'varicella',
        name: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        short: {
          vi: 'Thuỷ đậu',
          en: 'Chickenpox',
        },
        months: [12],
        programme: 'epi',
        route: 'injection',
        about: {
          vi: 'Tiêm một mũi lúc 12–15 tháng tuổi, giúp phòng thuỷ đậu.',
          en: 'One dose at 12–15 months; helps protect against chickenpox.',
        },
      },
      {
        id: 'hepa',
        name: {
          vi: 'Viêm gan A',
          en: 'Hepatitis A',
        },
        short: {
          vi: 'Viêm gan A',
          en: 'Hepatitis A',
        },
        months: [12, 18],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 26,
        about: {
          vi: 'Hai mũi trong khoảng 12–35 tháng tuổi, cách nhau ít nhất 6 tháng. Giúp phòng viêm gan A.',
          en: 'Two doses between 12 and 35 months, at least 6 months apart. Helps protect against hepatitis A.',
        },
      },
      {
        id: 'je',
        name: {
          vi: 'Viêm não Nhật Bản',
          en: 'Japanese encephalitis',
        },
        short: {
          vi: 'Viêm não NB',
          en: 'Japanese enceph.',
        },
        months: [12, 13, 24, 72],
        programme: 'epi',
        route: 'injection',
        minIntervalWeeks: 1,
        about: {
          vi: 'Lịch vắc xin bất hoạt: 2 mũi lúc 12–23 tháng cách 1 tháng, mũi 3 lúc 24–35 tháng, nhắc lúc 6 và 12 tuổi. Nếu chọn vắc xin sống chỉ cần 2 mũi (12–23 và 24–35 tháng).',
          en: 'Inactivated vaccine: two doses a month apart at 12–23 months, a third at 24–35 months, boosters at 6 and 12 years. The live vaccine needs only two doses (12–23 and 24–35 months).',
        },
      },
      {
        id: 'flu',
        name: {
          vi: 'Cúm',
          en: 'Flu',
        },
        short: {
          vi: 'Cúm',
          en: 'Flu',
        },
        months: [6, 7],
        programme: 'epi',
        route: 'injection',
        yearly: true,
        about: {
          vi: 'Miễn phí từ 6 tháng tuổi, tiêm mỗi năm trước mùa cúm. Năm đầu tiên tiêm 2 mũi cách nhau 4 tuần.',
          en: 'Free from 6 months, given every year before flu season. Two doses 4 weeks apart the first year.',
        },
      },
    ],
  },
};

/**
 * The schedule for a family in [country]: that country's when the app has it, else null (Việt
 * Nam's schedule is used, with the "follow your local clinic" notice for other countries).
 */
export function countryScheduleOf(
  country: string | null | undefined,
): CountryVaccineSchedule | null {
  if (!country || country === 'VN') return null;
  return countryVaccineSchedules[country] ?? null;
}
