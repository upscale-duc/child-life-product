import { describe, expect, it } from 'vitest';
import { vaccineGivenIn, vaccineLogLink } from '../src/assistant-vaccine.js';

const today = '2026-10-31';
const ids = (text: string) => vaccineGivenIn(text, today)?.mentions.map((m) => m.ids[0]);

// Lumi L5: a dose said as given, read by rules (no model) → the book's form on that dose.
describe('vaccineGivenIn', () => {
  it.each([
    ['bé vừa tiêm 6in1 mũi 2', ['dtp'], 2],
    ['be vua tiem 6in1 mui 2', ['dtp'], 2],
    ['hôm nay bé tiêm mũi thứ hai 5 trong 1', ['dtp'], 2],
    ['vừa cho bé uống rota xong', ['rota'], null],
    ['bé tiêm phế cầu mũi nhắc rồi', ['pcv'], 'booster'],
    ['she had her MMR shot today', ['mmr'], null],
    ['bé An vừa tiêm sởi', ['measles'], null],
  ])('%s', (text, want, dose) => {
    expect(ids(text)).toEqual(want);
    expect(vaccineGivenIn(text, today)?.mentions[0]?.dose).toEqual(dose);
  });

  it('two vaccines, each with its own dose', () => {
    const g = vaccineGivenIn('sáng nay bé tiêm 6in1 mũi 3 và uống rota mũi 2', today)!;
    expect(g.mentions.map((m) => [m.ids[0], m.dose])).toEqual([
      ['dtp', 3],
      ['rota', 2],
    ]);
  });

  it('reads the day, the place and the facility', () => {
    expect(vaccineGivenIn('hôm qua bé tiêm viêm gan B ở VNVC Hoàng Cầu', today)).toMatchObject({
      givenOn: '2026-10-30',
      place: 'service',
      facility: 'VNVC Hoàng Cầu',
    });
    expect(vaccineGivenIn('bé tiêm lao ngày 28/10 tại bệnh viện Từ Dũ', today)).toMatchObject({
      givenOn: '2026-10-28',
      place: 'hospital',
      facility: 'bệnh viện Từ Dũ',
    });
    expect(vaccineGivenIn('bé tiêm 6in1 ở trạm y tế phường, ổn lắm', today)).toMatchObject({
      givenOn: today,
      place: 'station',
      facility: 'trạm y tế phường',
    });
  });

  it('"bé vừa tiêm xong" with no name is still a dose (Lumi asks which)', () => {
    expect(vaccineGivenIn('bé vừa tiêm xong', today)?.mentions).toEqual([]);
  });

  it.each([
    'khi nào bé tiêm mũi 6in1 tiếp theo?',
    'bé tiêm 6in1 chưa',
    'mai đi tiêm 6in1',
    'tuần sau bé tiêm phế cầu',
    'bé bú 120ml rồi đi tiêm 6in1',
    'bé vừa uống vitamin D',
    'bé bị cúm hôm qua',
    'she had the flu yesterday',
    'when is the next shot?',
    'bé tiêm 6in1 hết 1tr2',
    'bé tiêm 6in1 ngày 5/13',
  ])('not a dose given: %s', (text) => expect(vaccineGivenIn(text, today)).toBeNull());
});

describe('vaccineLogLink', () => {
  it('names the dose, the day and the place', () => {
    expect(
      vaccineLogLink('dtp_2', { givenOn: today, place: 'service', facility: 'VNVC Hoàng Cầu' }),
    ).toBe(
      '/care/vaccines?log=dtp_2&on=2026-10-31&place=service&facility=VNVC+Ho%C3%A0ng+C%E1%BA%A7u',
    );
    expect(vaccineLogLink(null, { givenOn: today, place: null, facility: null })).toBe(
      '/care/vaccines',
    );
  });
});
