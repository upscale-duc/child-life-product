# Lumi AI — audit

Lumi đã là một assistant có tool và domain scope, không chỉ chatbot. Deterministic paths/authorization có nhiều kiểm thử; **chất lượng model và chi phí thật ở snapshot prompt mới chưa đủ bằng chứng**.

## Provider, prompts và processing

- `index.ts` khai báo secret `OPENAI_API_KEY`, `OPENAI_MODEL` default `gpt-4.1-mini`; `OPENAI_MODEL_UNDERSTANDING` có thể override, default rỗng→fallback model chính. Đây là **default trong source**, không xác nhận model đang deploy. [E42 · `OPENAI_MODEL / OPENAI_MODEL_UNDERSTANDING / assistantGateway`](../../firebase/functions/src/index.ts#L1407).
- `openAiModelGateway` gọi Chat Completions bằng fetch, strict JSON schema, temperature 0, request `store:false`, AbortSignal, output caps; understanding/extract/word/image tách request. Prompt version theo understandingVersion; schema allowlist và evidence spans. [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767).
- `startTask`→scope/consent/rules/dialogue→worker/model nếu cần→trusted read/prepare→part/draft→confirm domain writer→settle quota; inline và async worker có lease/idempotency. Model không tự chọn uid/path/collection hay thực thi tool tùy ý. [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767); [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E45 · `assistantPool / assistantUsage / recentUsage`](../../firebase/functions/src/assistant-usage.ts#L78).
- Text care/spending/reminder drafts và timer flows có code; meal logging trong chat còn unsupported theo prompt/notice, trong khi solids read context đã có. Không gắn nhãn toàn bộ Ăn dặm qua Lumi là “chưa có”. [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767); [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954).

## Context và personalization

| Context                            | Hành vi / trạng thái                                                                                                                                                                                                                                                                                                                            |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Child scope                        | Server loadTrustedScope gắn baby/family/role/timezone/country; switch child route có allowlist. Implemented. [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954) |
| Today/care                         | day overview, feed/sleep/diaper/pump/timers và nguồn/asOf/caveat missing logs. Implemented, emulator test không cần provider hay credits. [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954)                                                                                      |
| Growth                             | Snapshot nguồn, tuổi/giới tính cần thiết, chart route; không tự diễn giải chẩn đoán. Code có, professional quality không được chứng nhận                                                                                                                                                                                                        |
| Vaccines/reminders/spending/solids | Tool read theo domain rights; spending private; notes/reaction là self-report. Implemented                                                                                                                                                                                                                                                      |
| Milestones/stage/library/first aid | Published content, age/country filters, illustrative/review marker và nguồn; không phải semantic RAG toàn tài liệu                                                                                                                                                                                                                              | Implemented; live coverage và VI/EN usefulness chưa đo                                                                                                                                       |
| Notebook/routine                   | Shared active confirmed notes lọc theo role/expiry; private notes không tự biến thành family facts; unusual routine làm giảm suy luận                                                                                                                                                                                                           | Implemented, xem personalization-v2 + assistant-care. [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398) |
| Memories storytelling              | weekly stories/paragraph assist dùng pipeline AI riêng; Lumi tool allowlist không chứa một memory-story generator chung                                                                                                                                                                                                                         | Partially connected; không giả định mọi output AI đều đi qua Lumi                                                                                                                            |

## Safety, y tế và quyền

`healthSignalsIn` kiểm dấu hiệu trước model/credit; worker trả health_support từ catalog và region. Model prompt cấm diagnosis/dose, healthSigns typed schema, server chọn health route. Care suggestions xuất phát approved/rule content và facts; model wording không được tự bịa số. [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767); [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954).

Đây là evidence về kiến trúc safety, **không chứng minh sensitivity/accuracy y khoa hay mọi câu hỏi nguy cấp đều bị nhận ra**. Audit không đưa lời khuyên y tế, không đánh giá lâm sàng. Cần clinical/content review và bộ eval ngôn ngữ phù hợp trước rollout.

Conversation: private owner + current membership hoặc shared coParent/caregiver; spending route riêng; attachments có retention/delete sweeper. Account/baby delete có purge tasks/messages/drafts/photo/execution ledger; confirmed family records có lifecycle riêng. [E28 · `activeMember / canReadCare / assistantSharer`](../../firebase/firestore.rules#L18); [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E46 · `purgeAssistantForUser / purgeAssistantForBaby / TTL`](../../firebase/functions/src/assistant-lifecycle.ts#L89).

`store:false` là tham số request. **Không đủ để tuyên bố vendor zero retention hoặc chính sách xử lý dữ liệu pháp lý đã xác minh**. Source comments gọi “no retention” mạnh hơn bằng chứng request. Khi implementation/privacy review cần đối chiếu cấu hình/tài khoản/hợp đồng provider thực tế; audit không truy cập chúng.

## Credits, failure và cost

Credit ledger household dùng grants/period/monthly timezone, reserve/commit/release, quotaOps; health/rule reads miễn phí, model-backed useful output theo policy. Các check này khác token cost nội bộ. Không đề xuất đổi credits hay pricing. [E45 · `assistantPool / assistantUsage / recentUsage`](../../firebase/functions/src/assistant-usage.ts#L78).

Worker có modelCalls, timings, timeout/fallback/retry và staff estimatedCostVnd. Không nói thiếu monitoring hoàn toàn. [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E47 · `staff estimates modelCalls × unit cost`](../../firebase/functions/src/assistant-staff.ts#L223).

### LUM-01 · P1 — token usage bị bỏ qua

Gateway parse response chỉ đọc `choices[0].message.content`; không giữ provider `usage` hay model trả về. Staff estimate bằng calls × hằng cost, ví dụ `assistantCallCostVnd=300`; không biết input/output/cached token, understanding override, failed paid calls hoặc variance của image/model. [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767); [E42 · `OPENAI_MODEL / OPENAI_MODEL_UNDERSTANDING / assistantGateway`](../../firebase/functions/src/index.ts#L1407); [E47 · `staff estimates modelCalls × unit cost`](../../firebase/functions/src/assistant-staff.ts#L223).

Thiết kế: emit per-call metadata không content: provider/model actual, operation, promptVersion, status, token usage nếu có, duration, task attempt/call id. Aggregate cost có bảng giá/version nội bộ được duyệt; unknown usage không được gán 0. Giữ credit ledger nguyên. Budget guard có thể bắt đầu từ cảnh báo và reconciliation, tránh coi estimate là invoice hay đảm bảo hard budget under concurrency.

### LUM-02 · P1 — thiếu bằng chứng live eval ở revision mới

`docs/assistant/phase2-review-2026-10-20.md` ghi chưa live eval prompt v2 cho read changes; `docs/assistant/eval-2026-10-15.md` và test-report 16/10 là lịch sử, không chứng minh prompt/schema mới. Audit đã chạy Functions/contracts và assistant_reads/lumi Flutter, integration reads deterministic, không gọi model thật. Trạng thái quality VI/EN: **Unable to verify**, không phải đã fail.

Chuẩn bị locked fixtures expected intent/time/role/sources/credits/privacy, chạy scripted provider để regression; live eval bằng synthetic/approved data ở model/prompt revision cụ thể trong lượt triển khai có budget được duyệt. So sánh adversarial/mixed VI-EN/negation/medical ambiguity; lưu aggregate + redacted failures, không raw child chats trong analytics.

**Đã đóng 2026-10-21 (L10):** live eval `assistant-understand-v2` trên gpt-4.1-mini, 31 lượt gọi: 18/18 câu của owner, 10/13 câu đọc Phase 2 qua model (3 lệch ghi ở `docs/assistant/eval-2026-10-21-l10.md`, đều đã được luật đọc đúng ở đường mặc định); 18 câu owner thành replay fixtures; fake e2e 340/341 (ga-11 baseline có lý do).

## Tránh backlog trùng

Không xây lại chatbot, tool permissions, health route, confirmation cards, credits, usage screen hay conversation deletion. Ưu tiên cost fidelity, live quality evidence, local session boundary (FAM-01), data ngày/tuổi, deep-link đúng bé và chỉ mở thêm memory/recap tool sau khi nguồn và quyền đã rõ.
