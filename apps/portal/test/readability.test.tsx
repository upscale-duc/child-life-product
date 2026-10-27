import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { Input } from '../src/components/ui/input';
import { Field, FilterBar } from '../src/content-kit';
import { ApiContext, type Api } from '../src/api';
import { StaffContext } from '../src/context';
import { levelsForRoles } from '@child-life/contracts';
import { messages } from '../src/messages';
import copyBaseline from './design-review/copy-baseline.json';
import { createIntl } from 'react-intl';
import { PrintStudioScreen } from '../src/screens/PrintStudio';
import { Segmented, TableScroll } from '../src/ui';

const render = (children: ReactNode) =>
  renderToStaticMarkup(
    <IntlProvider locale="vi" messages={messages.vi}>
      {children}
    </IntlProvider>,
  );

describe('portal readability and access', () => {
  it('links a shared field label, helper and validation error to the input', () => {
    const html = render(
      <Field label="Tên phiên bản" help="Nhập tên" error="Tên không được trống">
        <Input defaultValue="" />
      </Field>,
    );
    const id = /<input[^>]*\bid="([^"]+)"/.exec(html)?.[1];
    expect(id).toBeTruthy();
    expect(html).toContain(`for="${id}"`);
    expect(html).toContain(`aria-describedby="${id}-description"`);
    expect(html).toContain('aria-invalid="true"');
    expect(html).toContain(`id="${id}-description"`);
    expect(html).toContain('role="alert"');
    expect(html).not.toContain('Nhập tên');
  });

  it('preserves explicit input IDs and existing descriptions', () => {
    const html = render(
      <Field label="Số ngày" help="Từ 1 đến 60">
        <Input id="lead-days" aria-describedby="range-unit" />
      </Field>,
    );
    expect(html).toContain('for="lead-days"');
    expect(html).toContain('aria-describedby="range-unit lead-days-description"');
  });

  it('shows the result count before filters are applied, without a redundant clear action', () => {
    const html = render(
      <FilterBar active={false} onClear={() => {}} shown={4} total={4}>
        <span>Bộ lọc</span>
      </FilterBar>,
    );
    expect(html).toContain('4 / 4 kết quả');
    expect(html).not.toContain('Xoá bộ lọc');
  });

  it('keeps one tab stop for a segmented control and makes wide tables keyboard-scrollable', () => {
    const html = render(
      <>
        <Segmented
          label="Khoảng ngày"
          value={30}
          onChange={() => {}}
          options={[7, 30, 90].map((value) => ({ value, label: String(value) }))}
        />
        <TableScroll>
          <table>
            <tbody>
              <tr>
                <td>Mã</td>
              </tr>
            </tbody>
          </table>
        </TableScroll>
      </>,
    );
    expect(html.match(/tabindex="0"/g)?.length).toBe(2);
    expect(html.match(/tabindex="-1"/g)?.length).toBe(2);
    expect(html).toContain('aria-label="Bảng dữ liệu · có thể cuộn ngang"');
  });

  it('does not show an empty order list while Print Studio is loading', () => {
    const api: Api = { call: () => new Promise(() => {}) };
    const html = render(
      <ApiContext.Provider value={api}>
        <StaffContext.Provider
          value={{
            uid: 's1',
            name: 'Review',
            email: 'review@example.test',
            roles: ['owner'],
            levels: levelsForRoles(['owner']),
          }}
        >
          <PrintStudioScreen />
        </StaffContext.Provider>
      </ApiContext.Provider>,
    );
    expect(html).toContain('Đang tải');
    expect(html).not.toContain('Chưa có đơn in');
    expect(html).not.toContain('Danh mục &amp; giao hàng');
  });

  it('keeps the notification default-content action distinct from pausing delivery', () => {
    expect(messages.vi['ntf.tpl.pause']).toBe('Dùng bản mặc định');
    expect(messages.vi['ntf.tpl.pause.body']).toContain('Thông báo vẫn được gửi');
    expect(messages.vi['ntf.settings.push']).toContain('Tạm dừng');
  });
});

// Keep variables and legal/health preview copy intact when simplifying staff-facing text.
// A copy regression here can break a counter, warning or financial value at runtime.

describe('reviewed bilingual copy', () => {
  for (const [id, before] of Object.entries(copyBaseline)) {
    it(`${id} keeps its variables and formats in both locales`, () => {
      for (const locale of ['vi', 'en'] as const) {
        const previous = before[locale];
        const current = messages[locale][id]!;
        const variables = (text: string) =>
          [...new Set([...text.matchAll(/\{([a-zA-Z][\w]*)[,}]/g)].map((m) => m[1]!))].sort();
        expect(variables(current)).toEqual(variables(previous));
        const values: Record<string, number | ((chunks: ReactNode[]) => ReactNode[])> = {};
        for (const name of variables(current)) values[name] = 1;
        for (const match of current.matchAll(/<([a-zA-Z]+)>/g))
          values[match[1]!] = (chunks) => chunks;
        const errors: string[] = [];
        const intl = createIntl({
          locale,
          messages: messages[locale],
          onError: (error) => errors.push(error.message),
        });
        intl.formatMessage({ id }, values);
        expect(errors).toEqual([]);
      }
    });
  }
});
