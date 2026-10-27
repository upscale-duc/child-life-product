import assert from 'node:assert/strict';
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
const { chromium } = await import(
  pathToFileURL(
    process.env.PORTAL_PLAYWRIGHT_MODULE ||
      '/tmp/child-life-portal-browser/node_modules/playwright/index.mjs',
  ).href
);
const b = await chromium.launch({
  executablePath:
    process.env.PORTAL_CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
});
let checks = 0;
async function open(path, extra = '', width = 1440) {
  const p = await b.newPage({ viewport: { width, height: 1000 } });
  await p.goto(
    'http://127.0.0.1:5181/test/design-review/index.html?path=' + encodeURIComponent(path) + extra,
  );
  await p.waitForTimeout(500);
  return p;
}
let p = await open('/features', '', 390);
assert.equal(await p.evaluate(() => document.documentElement.scrollWidth), 390);
checks++;
const tabs = p.getByRole('tablist').first();
await tabs.getByRole('tab').first().focus();
await p.keyboard.press('End');
await p.waitForTimeout(200);
assert.match(await p.getByRole('tab', { selected: true }).first().innerText(), /Lịch sử/);
checks++;
await p.close();
p = await open('/analytics');
await p.getByRole('tab', { name: 'Tổng quan', exact: true }).focus();
await p.keyboard.press('ArrowRight');
await p.waitForTimeout(200);
assert.match(new URL(p.url()).pathname, /acquisition/);
checks++;
await p.close();
p = await open('/');
await p.getByRole('button', { name: 'Tìm trang', exact: true }).click();
await p.locator('[cmdk-input]').fill('xu ly don in');
await p.waitForTimeout(200);
assert.equal(await p.getByRole('option', { name: /Print Studio/ }).count(), 1);
checks++;
await p.getByRole('option', { name: /Print Studio/ }).click();
await p.waitForTimeout(200);
assert.equal(new URL(p.url()).pathname, '/print-studio');
checks++;
const config = p.getByRole('button', { name: 'Danh mục & giao hàng', exact: true });
assert.equal(await config.getAttribute('aria-expanded'), 'false');
await config.click();
assert.equal(await config.getAttribute('aria-expanded'), 'true');
await p.getByLabel('Thời gian giao dự kiến (ngày)').fill('6');
assert.equal(await p.getByLabel('Thời gian giao dự kiến (ngày)').inputValue(), '6');
checks++;
await p.close();
p = await open('/print-studio', '&state=loading');
assert.match(await p.locator('body').innerText(), /Đang tải/);
assert.doesNotMatch(await p.locator('body').innerText(), /Chưa có đơn in/);
checks++;
await p.close();
p = await open('/print-studio', '&state=error');
assert.equal(await p.getByRole('button', { name: 'Thử lại', exact: true }).count(), 1);
assert.equal(await p.getByRole('alert').count(), 1);
checks++;
await p.close();
p = await open('/articles/new');
const before = await p.locator('input:not([type=hidden])').count();
assert.ok(before > 0);
const linked = await p.locator('label[for]').evaluateAll((labels) =>
  labels
    .filter((l) => {
      const c = document.getElementById(l.htmlFor);
      return c && ['INPUT', 'TEXTAREA'].includes(c.tagName);
    })
    .map((l) => ({ label: l.textContent, id: l.htmlFor })),
);
assert.ok(linked.length > 0);
checks++;
await p.close();
p = await open('/notifications/templates/memories.new_moments');
assert.match(await p.locator('body').innerText(), /Khoảnh khắc mới|Mẫu nội dung/);
checks++;
await p.close();
await b.close();
fs.writeFileSync(
  '/tmp/portal-interactions-result.json',
  JSON.stringify({ checks, passed: true }, null, 2),
);
console.log(checks + ' browser interaction checks passed');
