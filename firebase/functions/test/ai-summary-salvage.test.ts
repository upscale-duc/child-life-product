import { describe, expect, it } from 'vitest';
import { outputProblem } from '../src/ai-summary.js';

const facts = ['f_sleep', 'f_try'];
const x = { locale: 'vi' as const, factIds: facts, candidateIds: [] };
const section = (text: string, factIds: string[], kind = 'noticed') => ({ kind, text, factIds });

describe('handover output: sections are checked one by one', () => {
  it('a closing line with no fact is dropped, the grounded sections are shown', () => {
    const r = outputProblem(
      {
        sections: [
          section('Bé ngủ đều hơn mấy đêm qua.', ['f_sleep']),
          section('Chúc cả nhà một tuần nhẹ nhàng!', []),
        ],
        suggestionContentId: null,
        language: 'vi',
      },
      x,
    );
    expect(r).toMatchObject({ output: { sections: [{ factIds: ['f_sleep'] }] } });
  });

  it('a section with a forbidden claim or an unknown fact is dropped, not the answer', () => {
    const r = outputProblem(
      {
        sections: [
          section('Chắc chắn bé đã quen giờ ngủ.', ['f_sleep']),
          section('Hát nhẹ đã được thử và thấy có ích.', ['f_try']),
          section('Bé ăn ngon.', ['f_made_up']),
        ],
        suggestionContentId: null,
        language: 'vi',
      },
      x,
    );
    expect(r).toMatchObject({ output: { sections: [{ factIds: ['f_try'] }] } });
  });

  it('more than six grounded sections keep the first six', () => {
    const many = Array.from({ length: 8 }, (_, i) => section(`Điều ${i}`, ['f_sleep']));
    const r = outputProblem({ sections: many, suggestionContentId: null, language: 'vi' }, x);
    expect('output' in r && r.output.sections).toHaveLength(6);
  });

  it('nothing grounded left, or the wrong language: the template answers', () => {
    expect(
      outputProblem(
        { sections: [section('Chúc ngủ ngon!', [])], suggestionContentId: null, language: 'vi' },
        x,
      ),
    ).toEqual({ problem: 'invalid' });
    expect(
      outputProblem(
        {
          sections: [section('Slept well.', ['f_sleep'])],
          suggestionContentId: null,
          language: 'en',
        },
        x,
      ),
    ).toEqual({ problem: 'invalid' });
  });
});
