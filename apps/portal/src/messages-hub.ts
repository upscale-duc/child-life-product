/**
 * "Tính năng & Premium" hub (D-089) and the merged Hệ thống & AI page (owner, 2026-10-21).
 * Vietnamese is the source; English is drafted by engineering for owner review (D-012). The
 * catalogue's names and help (`hub.feature.<key>`, `hub.feature.<key>.help`) are the `labelId` /
 * `helpId` of `featureCatalogue`; `hub.why.<code>` reads `featureExplanations`.
 */
export const hubVi: Record<string, string> = {
  'hub.title': 'Tính năng & Premium',
  'hub.tabs': 'Mục Tính năng & Premium',
  'hub.tab.features': 'Tính năng',
  'hub.tab.families': 'Gia đình',
  'hub.tab.plan': 'Gói Premium',
  'hub.tab.switches': 'Công tắc hệ thống',
  'hub.tab.history': 'Lịch sử',
  'hub.rules.title': 'Ai được dùng một tính năng (theo thứ tự)',
  'hub.rules.kill': 'Công tắc khẩn tắt: không ai dùng được.',
  'hub.rules.override': 'Gia đình được bật hoặc tắt riêng ở tab Gia đình: theo đúng lựa chọn đó.',
  'hub.rules.premium':
    'Gói Premium: mọi gia đình có Premium (trả phí, hoặc được cấp) dùng được, bất kể phát hành; gia đình khác theo phát hành và thấy màn hình Premium khi thanh toán đã bật.',
  'hub.rules.beta':
    'Gói Beta: gia đình trong danh sách beta và gia đình trong phạm vi phát hành; miễn phí, có nhãn Beta.',
  'hub.rules.free': 'Gói Miễn phí: gia đình trong phạm vi phát hành.',

  'hub.group.records': 'Ghi chép',
  'hub.group.keepsakes': 'Kỷ niệm',
  'hub.group.personalization': 'Cá nhân hoá',
  'hub.group.assistant': 'Trợ lý AI',
  'hub.group.content': 'Nội dung',

  'hub.feature.rhythm': 'Nhịp lớn lên',
  'hub.feature.rhythm.help': 'Lịch tham khảo theo tuổi và check-in hằng ngày cho từng bé.',
  'hub.feature.personalization': 'Gợi ý cá nhân hoá & Nhịp nâng cao',
  'hub.feature.personalization.help':
    'Gợi ý liên mục theo ghi chép của gia đình và phần nâng cao của Nhịp lớn lên (nhóm A).',
  'hub.feature.ai_assist': 'AI tóm tắt và giải thích',
  'hub.feature.ai_assist.help':
    'Tóm tắt có căn cứ từ ghi chép của bé. Gia đình chưa có Premium dùng trong số credit trợ lý của mình.',
  'hub.feature.assistant': 'Trợ lý (chat, ảnh, hướng dẫn chăm sóc)',
  'hub.feature.assistant.help':
    'Trợ lý chat; ảnh, hướng dẫn chăm sóc và lời mời nâng cấp là công tắc thành phần. Premium có quỹ credit lớn hơn.',
  'hub.feature.templates_premium': 'Mẫu kỷ niệm Premium',
  'hub.feature.templates_premium.help':
    'Các mẫu kỷ niệm Cao cấp (nhóm B). Mẫu nào là Cao cấp vẫn chọn ở Mẫu kỷ niệm.',
  'hub.feature.milestone_cards': 'Thiệp cột mốc',
  'hub.feature.milestone_cards.help': 'Thiệp kỷ niệm khi bé đạt một cột mốc.',
  'hub.feature.memory_story': 'Video kỷ niệm',
  'hub.feature.memory_story.help': 'Video dựng từ ảnh và video của bé, xuất trên máy chủ.',
  'hub.feature.auto_save': 'Tự lưu kỷ niệm',
  'hub.feature.auto_save.help': 'Gợi ý ảnh trong thư viện máy để lưu vào kỷ niệm (beta trên iOS).',
  'hub.feature.ai_story_drafts': 'Nháp câu chuyện AI',
  'hub.feature.ai_story_drafts.help':
    'AI viết nháp câu chuyện từ ảnh và ghi chép; ba mẹ sửa rồi mới lưu.',

  'hub.tier.free': 'Miễn phí',
  'hub.tier.premium': 'Premium',
  'hub.tier.beta': 'Beta',
  'hub.tier.label': 'Gói của “{feature}”',
  'hub.tier.credits': '+ dùng thử bằng credit',
  'hub.tier.title': 'Đổi gói “{feature}”: {from} → {to}?',
  'hub.tier.counting': 'Đang đếm số gia đình bị ảnh hưởng…',
  'hub.tier.confirm': 'Chuyển sang {tier}',
  'hub.tier.done': 'Đã chuyển “{feature}” sang {tier}',
  'hub.tierNote.free.premium':
    '{n, plural, other {# gia đình}} đang dùng sẽ giữ quyền 30 ngày, đến hết {date}. Sau đó chỉ gia đình có Premium (trả phí hoặc được cấp) dùng được; gia đình khác thấy màn hình Premium khi thanh toán đã bật.',
  'hub.tierNote.beta.premium':
    '{n, plural, other {# gia đình}} trong beta sẽ giữ quyền 30 ngày, đến hết {date}. Sau đó chỉ gia đình có Premium (trả phí hoặc được cấp) dùng được.',
  'hub.tierNote.premium.free':
    'Hiện {n, plural, other {# gia đình}} có Premium. Sau khi đổi, gia đình nào dùng được chỉ theo phạm vi phát hành.',
  'hub.tierNote.premium.beta':
    'Hiện {n, plural, other {# gia đình}} có Premium. Sau khi đổi, chỉ gia đình trong danh sách beta hoặc trong phạm vi phát hành dùng được, miễn phí, có nhãn Beta.',
  'hub.tierNote.free.beta':
    '{n, plural, other {# gia đình}} đang dùng vẫn dùng tiếp (có nhãn Beta). Thêm gia đình vào danh sách beta để mở riêng.',
  'hub.tierNote.beta.free':
    '{n, plural, other {# gia đình}} đang dùng. Sau khi đổi, gia đình chỉ nằm trong danh sách beta mà ngoài phạm vi phát hành sẽ không dùng được nữa.',

  'hub.kpi.premiumFamilies': 'Gia đình có Premium',
  'hub.kpi.premiumFoot': '{paid} trả phí · {admin} được cấp',
  'hub.kpi.tier.free': 'Tính năng miễn phí',
  'hub.kpi.tier.premium': 'Tính năng Premium',
  'hub.kpi.tier.beta': 'Tính năng Beta',

  'hub.col.feature': 'Tính năng',
  'hub.col.tier': 'Gói',
  'hub.col.rollout': 'Phát hành',
  'hub.col.families': 'Gia đình',
  'hub.col.kill': 'Công tắc khẩn',
  'hub.col.detail': 'Chi tiết',
  'hub.col.now': 'Hiện tại',
  'hub.col.override': 'Bật riêng',
  'hub.col.beta': 'Beta',

  'hub.rollout.label': 'Phát hành “{feature}”',
  'hub.rollout.none': 'Theo gói, không có công tắc',
  'hub.rollout.off': 'Chưa phát hành',
  'hub.rollout.internal': 'Nội bộ',
  'hub.rollout.internalSome': '{n, plural, other {Nội bộ + # gia đình}}',
  'hub.rollout.p10': '10% gia đình',
  'hub.rollout.p25': '25% gia đình',
  'hub.rollout.p50': '50% gia đình',
  'hub.rollout.all': 'Mọi gia đình',
  'hub.rollout.title': 'Phát hành “{feature}”',
  'hub.rollout.families': 'Gia đình được chọn (ngoài nhóm nội bộ)',
  'hub.rollout.done': 'Đã đổi phát hành “{feature}”',
  'hub.rolloutNote.off':
    'Chưa mở cho ai theo phát hành. Gia đình có Premium (với gói Premium), gia đình trong beta và gia đình được bật riêng vẫn dùng được.',
  'hub.rolloutNote.internal': 'Gia đình nội bộ và các gia đình chọn dưới đây.',
  'hub.rolloutNote.p10': '10% gia đình, chọn ngẫu nhiên và cố định theo từng gia đình.',
  'hub.rolloutNote.p25': '25% gia đình, chọn ngẫu nhiên và cố định theo từng gia đình.',
  'hub.rolloutNote.p50': '50% gia đình, chọn ngẫu nhiên và cố định theo từng gia đình.',
  'hub.rolloutNote.all': 'Mọi gia đình.',
  'hub.rolloutNote.premium':
    'Gói Premium: gia đình có Premium luôn dùng được; phát hành chỉ quyết định khi nào gia đình khác thấy màn hình Premium.',
  'hub.rolloutNote.killed': 'Công tắc khẩn đang tắt: phạm vi mới chỉ có hiệu lực khi bật lại.',

  'hub.kill.label': 'Công tắc khẩn “{feature}”',
  'hub.kill.off': 'Đã tắt',
  'hub.kill.offTitle': 'Tắt khẩn “{feature}” cho mọi gia đình?',
  'hub.kill.onTitle': 'Bật lại “{feature}”?',
  'hub.kill.offNote':
    'Không gia đình nào dùng được nữa, kể cả gia đình có Premium và gia đình được bật riêng. Dữ liệu đã lưu không mất.',
  'hub.kill.onNote': 'Tính năng mở lại theo gói và phát hành hiện tại, không cần cập nhật app.',
  'hub.kill.confirmOff': 'Tắt khẩn',
  'hub.kill.confirmOn': 'Bật lại',

  'hub.count.premium': '{n, plural, other {# gia đình Premium}}',
  'hub.count.beta': '{n, plural, other {# gia đình trong beta}}',
  'hub.count.overrides': 'Bật riêng {on} · tắt riêng {off}',
  'hub.subFlags.count': '{n, plural, other {+ # công tắc thành phần}}',
  'hub.grace.until': 'Giữ quyền đến hết {date}',
  'hub.grace.note':
    'Chuyển từ {from} sang Premium: gia đình đã dùng trước đó giữ quyền đến hết {date}.',

  'hub.detail.open': 'Chi tiết “{feature}”',
  'hub.detail.defaultTier': 'mặc định: {tier}',
  'hub.detail.capabilities': 'Quyền liên quan',
  'hub.detail.switches': 'Công tắc & phát hành',
  'hub.detail.main': 'Chính',
  'hub.detail.systemParts': 'Cũng thuộc tính năng này, ở Công tắc hệ thống: {flags}.',
  'hub.detail.overridesNote': 'Bật hoặc tắt riêng cho một gia đình, thêm vào beta: ở tab Gia đình.',

  'hub.beta.list': '{n, plural, other {Danh sách beta · # gia đình}}',
  'hub.beta.empty': 'Chưa có gia đình nào trong beta.',
  'hub.beta.save': 'Lưu danh sách beta',
  'hub.beta.saved': 'Đã lưu danh sách beta',
  'hub.beta.add': 'Thêm vào beta',
  'hub.beta.remove': 'Bỏ khỏi beta',
  'hub.beta.listed': 'Trong beta',
  'hub.beta.added': 'Đã thêm {code} vào beta “{feature}”',
  'hub.beta.removed': 'Đã bỏ {code} khỏi beta “{feature}”',

  'hub.family.search': 'Mã gia đình (F-XXXX), email hoặc tên gọi của bé',
  'hub.family.go': 'Tìm',
  'hub.family.hint':
    'Tìm một gia đình để xem từng tính năng có hay không và vì sao, bật riêng, thêm vào beta hoặc bật toàn bộ Premium.',
  'hub.family.none': 'Không tìm thấy gia đình nào.',
  'hub.family.noneHelp': 'Email phải đầy đủ; tên gọi của bé phải đúng như trong app.',
  'hub.family.matches': '{n, plural, other {# gia đình khớp}}',
  'hub.family.matchedBy.code': 'Theo mã gia đình',
  'hub.family.matchedBy.email': 'Theo email: các gia đình tài khoản này đang tham gia',
  'hub.family.matchedBy.nickname': 'Theo tên gọi của bé: chọn đúng gia đình',
  'hub.family.babies': '{n, plural, other {# bé}}',
  'hub.family.open': 'Mở',
  'hub.family.internal': 'Gia đình nội bộ',
  'hub.family.regionNote':
    'Quốc gia của gia đình chưa mở Premium trả phí. Premium được cấp (Bật toàn bộ Premium) vẫn dùng được.',
  'hub.family.features': 'Tính năng của gia đình',
  'hub.family.featuresCount': '{n}/{total} đang dùng được',
  'hub.family.overrideHint':
    'Bật / Tắt: chỉ cho gia đình này, bất kể gói và phát hành (trừ khi công tắc khẩn tắt). Theo quy tắc: bỏ lựa chọn riêng.',
  'hub.family.grants': 'Quyền Premium đã cấp',
  'hub.family.grantsCount': '{n, plural, other {# quyền}}',
  'hub.family.noEnd': 'từ {from} · đến khi tắt',
  'hub.family.quota': 'Lượt dùng & thanh toán',

  'hub.full.title': 'Bật toàn bộ Premium',
  'hub.full.help':
    'Mở mọi tính năng Premium cho gia đình này; không xét quốc gia. Mặc định đến khi tắt.',
  'hub.full.onOpen': 'Đang bật · đến khi tắt',
  'hub.full.onUntil': 'Đang bật · đến hết {until}',
  'hub.full.onTitle': 'Bật toàn bộ Premium cho {code}?',
  'hub.full.onBody':
    'Gia đình dùng được mọi tính năng Premium và quỹ credit Premium ngay lần mở app tiếp theo.',
  'hub.full.until': 'Ngày kết thúc (không bắt buộc)',
  'hub.full.untilHelp': 'Để trống: đến khi tắt. Có ngày: dùng đến hết ngày đó.',
  'hub.full.confirmOn': 'Bật Premium',
  'hub.full.changeEnd': 'Đổi ngày kết thúc',
  'hub.full.endTitle': 'Ngày kết thúc Premium của {code}',
  'hub.full.confirmEnd': 'Lưu',
  'hub.full.offTitle': 'Tắt toàn bộ Premium của {code}?',
  'hub.full.offBody':
    'Tính năng Premium chỉ còn theo gói trả phí, beta hoặc lựa chọn bật riêng. Dữ liệu đã lưu không mất.',
  'hub.full.confirmOff': 'Tắt Premium',
  'hub.full.doneOn': 'Đã bật toàn bộ Premium cho {code}',
  'hub.full.doneOff': 'Đã tắt toàn bộ Premium của {code}',

  'hub.override.on': 'Bật',
  'hub.override.off': 'Tắt',
  'hub.override.rule': 'Theo quy tắc',
  'hub.override.label': 'Bật riêng “{feature}” cho {code}',
  'hub.override.done': 'Đã lưu “{feature}” cho {code}',
  'hub.override.by': 'Chọn riêng bởi {by}',
  'hub.override.byUntil': 'Chọn riêng bởi {by} · đến hết {until}',

  'hub.why.killed': 'Không · công tắc khẩn đang tắt',
  'hub.why.override_on': 'Có · được bật riêng',
  'hub.why.override_off': 'Không · bị tắt riêng',
  'hub.why.premium_paid': 'Có · Premium trả phí',
  'hub.why.premium_admin': 'Có · Premium được cấp',
  'hub.why.grace': 'Có · giữ quyền sau khi chuyển sang Premium',
  'hub.why.beta_campaign': 'Có · chiến dịch beta (cũ)',
  'hub.why.credits': 'Có · dùng bằng credit trợ lý',
  'hub.why.beta': 'Có · Beta',
  'hub.why.free': 'Có · Miễn phí',
  'hub.why.not_released': 'Không · chưa phát hành tới gia đình này',
  'hub.why.not_in_beta': 'Không · chưa ở trong beta',
  'hub.why.region': 'Không · quốc gia chưa mở Premium',
  'hub.why.premium_required': 'Không · cần Premium',
  'hub.why.until': 'đến hết {date}',
  'hub.why.visible': 'Vẫn thấy lối vào; app mời mở Premium',

  'hub.plan.sections': 'Mục Gói Premium',
  'hub.plan.config': 'Cấu hình',
  'hub.plan.ai': 'Chính sách AI',
  'hub.plan.campaigns': 'Chiến dịch beta (cũ)',
  'hub.plan.billing': 'Mua gói trong app',
  'hub.plan.campaignsNote':
    'Chỉ để xem. Beta giờ là gói của từng tính năng (tab Tính năng) với danh sách beta riêng; quyền từ các chiến dịch này vẫn tính đến khi chiến dịch kết thúc.',

  'hub.switches.billingElsewhere': 'Mua gói trong app ở',

  'hub.history.recent': 'Thay đổi gần đây',
  'hub.history.note': 'Máy chủ tự ghi ai, lúc nào, đổi gì (trước / sau).',
  'hub.history.audit': 'Nhật ký 30 ngày',

  'audit.hub.tier':
    'Đổi gói “{feature}” sang {tier, select, free {Miễn phí} premium {Premium} beta {Beta} other {gói khác}}',
  'audit.hub.beta': 'Sửa danh sách beta “{feature}”',
  'audit.hub.beta.add': 'Thêm {code} vào beta “{feature}”',
  'audit.hub.beta.remove': 'Bỏ {code} khỏi beta “{feature}”',
  'audit.hub.override': '{state, select, on {Bật} other {Tắt}} riêng “{feature}” cho {code}',
  'audit.hub.override.clear': '“{feature}” của {code} về theo quy tắc',
  'audit.premium.full.on': 'Bật toàn bộ Premium cho {code}',
  'audit.premium.full.off': 'Tắt toàn bộ Premium của {code}',

  'system.tab.storage': 'Lưu trữ',
  'system.tab.ai': 'AI gợi ý câu chuyện',
  'system.tab.usage': 'Trợ lý: mức dùng',
  'system.tab.tasks': 'Trợ lý: tra cứu tác vụ',

  'analytics.personalization.tab': 'Cá nhân hoá',
  'analytics.personalization.funnel': 'Hành trình gợi ý theo ngày',
  'analytics.personalization.content': 'Phản hồi theo nội dung',

  'features.group.other': 'Khác',
  'kit.notes': 'Ghi chú (không bắt buộc)',
  'kit.rejectedBy': '{name} trả lại bản này để sửa tiếp.',
  'jobs.rerunAskedByName': '{name} đề nghị chạy lại.',
};

export const hubEn: Record<string, string> = {
  'hub.title': 'Features & Premium',
  'hub.tabs': 'Features & Premium sections',
  'hub.tab.features': 'Features',
  'hub.tab.families': 'Families',
  'hub.tab.plan': 'Premium plan',
  'hub.tab.switches': 'System switches',
  'hub.tab.history': 'History',
  'hub.rules.title': 'Who gets a feature (in order)',
  'hub.rules.kill': 'Kill switch off: nobody.',
  'hub.rules.override': 'A family turned on or off on the Families tab: exactly that.',
  'hub.rules.premium':
    'Premium tier: every family with Premium (paid or granted) has it, whatever the rollout; others follow the rollout and see the Premium screen once billing is on.',
  'hub.rules.beta':
    'Beta tier: the families on the beta list and those inside the rollout; free, labelled Beta.',
  'hub.rules.free': 'Free tier: the families inside the rollout.',

  'hub.group.records': 'Logging',
  'hub.group.keepsakes': 'Keepsakes',
  'hub.group.personalization': 'Personalization',
  'hub.group.assistant': 'AI assistant',
  'hub.group.content': 'Content',

  'hub.feature.rhythm': 'Growing rhythm',
  'hub.feature.rhythm.help': 'The age-based reference calendar and daily check-ins for each baby.',
  'hub.feature.personalization': 'Personalized suggestions & advanced rhythm',
  'hub.feature.personalization.help':
    "Cross-module suggestions from the family's records and the advanced part of the growing rhythm (group A).",
  'hub.feature.ai_assist': 'AI summaries and explanations',
  'hub.feature.ai_assist.help':
    "Grounded summaries of the baby's records. Families without Premium use them within their assistant credits.",
  'hub.feature.assistant': 'Assistant (chat, photos, care guidance)',
  'hub.feature.assistant.help':
    'The chat assistant; photos, care guidance and the upgrade invitation are part switches. Premium has a bigger credit pool.',
  'hub.feature.templates_premium': 'Premium keepsake templates',
  'hub.feature.templates_premium.help':
    'The Premium keepsake templates (group B). Which templates are Premium is still set in Keepsake templates.',
  'hub.feature.milestone_cards': 'Milestone cards',
  'hub.feature.milestone_cards.help': 'A keepsake card when the baby reaches a milestone.',
  'hub.feature.memory_story': 'Memory videos',
  'hub.feature.memory_story.help':
    "Videos built from the baby's photos and clips, rendered on the server.",
  'hub.feature.auto_save': 'Auto-save keepsakes',
  'hub.feature.auto_save.help':
    "Suggests photos from the phone's library to save as keepsakes (iOS beta).",
  'hub.feature.ai_story_drafts': 'AI story drafts',
  'hub.feature.ai_story_drafts.help':
    'The AI drafts a story from photos and records; parents edit it before saving.',

  'hub.tier.free': 'Free',
  'hub.tier.premium': 'Premium',
  'hub.tier.beta': 'Beta',
  'hub.tier.label': 'Tier of “{feature}”',
  'hub.tier.credits': '+ try with credits',
  'hub.tier.title': 'Move “{feature}”: {from} → {to}?',
  'hub.tier.counting': 'Counting the families this touches…',
  'hub.tier.confirm': 'Move to {tier}',
  'hub.tier.done': 'Moved “{feature}” to {tier}',
  'hub.tierNote.free.premium':
    '{n, plural, one {# family} other {# families}} using it now keep it for 30 days, until the end of {date}. After that only families with Premium (paid or granted) have it; others see the Premium screen once billing is on.',
  'hub.tierNote.beta.premium':
    '{n, plural, one {# family} other {# families}} in the beta keep it for 30 days, until the end of {date}. After that only families with Premium (paid or granted) have it.',
  'hub.tierNote.premium.free':
    '{n, plural, one {# family has} other {# families have}} Premium now. After the change, the rollout alone decides who has it.',
  'hub.tierNote.premium.beta':
    '{n, plural, one {# family has} other {# families have}} Premium now. After the change, only families on the beta list or inside the rollout have it, free and labelled Beta.',
  'hub.tierNote.free.beta':
    '{n, plural, one {# family} other {# families}} using it keep it (labelled Beta). Add families to the beta list to open it for them.',
  'hub.tierNote.beta.free':
    '{n, plural, one {# family uses} other {# families use}} it. After the change, families only on the beta list and outside the rollout lose it.',

  'hub.kpi.premiumFamilies': 'Families with Premium',
  'hub.kpi.premiumFoot': '{paid} paid · {admin} granted',
  'hub.kpi.tier.free': 'Free features',
  'hub.kpi.tier.premium': 'Premium features',
  'hub.kpi.tier.beta': 'Beta features',

  'hub.col.feature': 'Feature',
  'hub.col.tier': 'Tier',
  'hub.col.rollout': 'Rollout',
  'hub.col.families': 'Families',
  'hub.col.kill': 'Kill switch',
  'hub.col.detail': 'Details',
  'hub.col.now': 'Now',
  'hub.col.override': 'Per family',
  'hub.col.beta': 'Beta',

  'hub.rollout.label': 'Rollout of “{feature}”',
  'hub.rollout.none': 'By tier, no switch',
  'hub.rollout.off': 'Not released',
  'hub.rollout.internal': 'Internal',
  'hub.rollout.internalSome':
    '{n, plural, one {Internal + # family} other {Internal + # families}}',
  'hub.rollout.p10': '10% of families',
  'hub.rollout.p25': '25% of families',
  'hub.rollout.p50': '50% of families',
  'hub.rollout.all': 'Every family',
  'hub.rollout.title': 'Release “{feature}”',
  'hub.rollout.families': 'Picked families (besides the internal group)',
  'hub.rollout.done': 'Changed the rollout of “{feature}”',
  'hub.rolloutNote.off':
    'Released to nobody. Families with Premium (for a Premium feature), on the beta list or turned on for them still have it.',
  'hub.rolloutNote.internal': 'Internal families and the families picked below.',
  'hub.rolloutNote.p10': '10% of families, picked at random and fixed per family.',
  'hub.rolloutNote.p25': '25% of families, picked at random and fixed per family.',
  'hub.rolloutNote.p50': '50% of families, picked at random and fixed per family.',
  'hub.rolloutNote.all': 'Every family.',
  'hub.rolloutNote.premium':
    'Premium tier: families with Premium always have it; the rollout only decides when others see the Premium screen.',
  'hub.rolloutNote.killed':
    'The kill switch is off: the new scope only applies once it is back on.',

  'hub.kill.label': 'Kill switch of “{feature}”',
  'hub.kill.off': 'Off',
  'hub.kill.offTitle': 'Turn “{feature}” off for every family?',
  'hub.kill.onTitle': 'Turn “{feature}” back on?',
  'hub.kill.offNote':
    'No family can use it, including families with Premium and those turned on for them. Saved data is kept.',
  'hub.kill.onNote': 'It opens again by its tier and current rollout, without an app update.',
  'hub.kill.confirmOff': 'Turn off',
  'hub.kill.confirmOn': 'Turn on',

  'hub.count.premium': '{n, plural, one {# Premium family} other {# Premium families}}',
  'hub.count.beta': '{n, plural, one {# family in the beta} other {# families in the beta}}',
  'hub.count.overrides': 'On for {on} · off for {off}',
  'hub.subFlags.count': '{n, plural, one {+ # part switch} other {+ # part switches}}',
  'hub.grace.until': 'Kept until the end of {date}',
  'hub.grace.note':
    'Moved from {from} to Premium: families that used it keep it until the end of {date}.',

  'hub.detail.open': 'Details of “{feature}”',
  'hub.detail.defaultTier': 'default: {tier}',
  'hub.detail.capabilities': 'Capabilities',
  'hub.detail.switches': 'Switches & rollout',
  'hub.detail.main': 'Main',
  'hub.detail.systemParts': 'Also part of this feature, under System switches: {flags}.',
  'hub.detail.overridesNote':
    'Turning it on or off for one family, or adding a family to the beta: on the Families tab.',

  'hub.beta.list': '{n, plural, one {Beta list · # family} other {Beta list · # families}}',
  'hub.beta.empty': 'No family in the beta yet.',
  'hub.beta.save': 'Save the beta list',
  'hub.beta.saved': 'Beta list saved',
  'hub.beta.add': 'Add to beta',
  'hub.beta.remove': 'Remove from beta',
  'hub.beta.listed': 'In the beta',
  'hub.beta.added': 'Added {code} to the “{feature}” beta',
  'hub.beta.removed': 'Removed {code} from the “{feature}” beta',

  'hub.family.search': "Family code (F-XXXX), email or the baby's nickname",
  'hub.family.go': 'Find',
  'hub.family.hint':
    'Find a family to see whether it has each feature and why, turn one on or off for it, add it to a beta or turn all of Premium on.',
  'hub.family.none': 'No family found.',
  'hub.family.noneHelp': "Use a full email; the baby's nickname must match the app exactly.",
  'hub.family.matches': '{n, plural, one {# matching family} other {# matching families}}',
  'hub.family.matchedBy.code': 'By family code',
  'hub.family.matchedBy.email': 'By email: the families this account belongs to',
  'hub.family.matchedBy.nickname': "By the baby's nickname: pick the right family",
  'hub.family.babies': '{n, plural, one {# baby} other {# babies}}',
  'hub.family.open': 'Open',
  'hub.family.internal': 'Internal family',
  'hub.family.regionNote':
    "The family's country does not sell paid Premium yet. A granted Premium (Turn on all of Premium) still works.",
  'hub.family.features': "The family's features",
  'hub.family.featuresCount': '{n}/{total} available',
  'hub.family.overrideHint':
    'On / Off: for this family only, whatever the tier and rollout (unless the kill switch is off). By rule: drop the family choice.',
  'hub.family.grants': 'Premium grants',
  'hub.family.grantsCount': '{n, plural, one {# grant} other {# grants}}',
  'hub.family.noEnd': 'from {from} · until turned off',
  'hub.family.quota': 'Usage & billing',

  'hub.full.title': 'Turn on all of Premium',
  'hub.full.help':
    'Opens every Premium feature for this family; the country is not checked. Until turned off by default.',
  'hub.full.onOpen': 'On · until turned off',
  'hub.full.onUntil': 'On · until the end of {until}',
  'hub.full.onTitle': 'Turn on all of Premium for {code}?',
  'hub.full.onBody':
    'The family gets every Premium feature and the Premium credit pool the next time the app opens.',
  'hub.full.until': 'End date (optional)',
  'hub.full.untilHelp': 'Empty: until turned off. A date: until the end of that day.',
  'hub.full.confirmOn': 'Turn on Premium',
  'hub.full.changeEnd': 'Change the end date',
  'hub.full.endTitle': 'End of Premium for {code}',
  'hub.full.confirmEnd': 'Save',
  'hub.full.offTitle': 'Turn off all of Premium for {code}?',
  'hub.full.offBody':
    'Premium features then follow only a paid plan, a beta or a per-family choice. Saved data is kept.',
  'hub.full.confirmOff': 'Turn off Premium',
  'hub.full.doneOn': 'All of Premium is on for {code}',
  'hub.full.doneOff': 'All of Premium is off for {code}',

  'hub.override.on': 'On',
  'hub.override.off': 'Off',
  'hub.override.rule': 'By rule',
  'hub.override.label': '“{feature}” for {code}',
  'hub.override.done': 'Saved “{feature}” for {code}',
  'hub.override.by': 'Set for this family by {by}',
  'hub.override.byUntil': 'Set for this family by {by} · until the end of {until}',

  'hub.why.killed': 'No · the kill switch is off',
  'hub.why.override_on': 'Yes · turned on for this family',
  'hub.why.override_off': 'No · turned off for this family',
  'hub.why.premium_paid': 'Yes · paid Premium',
  'hub.why.premium_admin': 'Yes · granted Premium',
  'hub.why.grace': 'Yes · kept after the move to Premium',
  'hub.why.beta_campaign': 'Yes · beta campaign (old)',
  'hub.why.credits': 'Yes · with assistant credits',
  'hub.why.beta': 'Yes · Beta',
  'hub.why.free': 'Yes · Free',
  'hub.why.not_released': 'No · not released to this family yet',
  'hub.why.not_in_beta': 'No · not in the beta',
  'hub.why.region': 'No · the country has no Premium yet',
  'hub.why.premium_required': 'No · needs Premium',
  'hub.why.until': 'until the end of {date}',
  'hub.why.visible': 'The entry still shows; the app offers Premium',

  'hub.plan.sections': 'Premium plan sections',
  'hub.plan.config': 'Configuration',
  'hub.plan.ai': 'AI policy',
  'hub.plan.campaigns': 'Beta campaigns (old)',
  'hub.plan.billing': 'In-app purchase',
  'hub.plan.campaignsNote':
    'Read-only. A beta is now the tier of each feature (Features tab) with its own beta list; grants from these campaigns still count until they end.',

  'hub.switches.billingElsewhere': 'In-app purchase is on',

  'hub.history.recent': 'Recent changes',
  'hub.history.note': 'The server records who changed what and when (before / after).',
  'hub.history.audit': 'Log, last 30 days',

  'audit.hub.tier':
    'Moved “{feature}” to {tier, select, free {Free} premium {Premium} beta {Beta} other {another tier}}',
  'audit.hub.beta': 'Edited the “{feature}” beta list',
  'audit.hub.beta.add': 'Added {code} to the “{feature}” beta',
  'audit.hub.beta.remove': 'Removed {code} from the “{feature}” beta',
  'audit.hub.override': 'Turned “{feature}” {state, select, on {on} other {off}} for {code}',
  'audit.hub.override.clear': '“{feature}” back to the rule for {code}',
  'audit.premium.full.on': 'Turned on all of Premium for {code}',
  'audit.premium.full.off': 'Turned off all of Premium for {code}',

  'system.tab.storage': 'Storage',
  'system.tab.ai': 'AI story drafts',
  'system.tab.usage': 'Assistant: usage',
  'system.tab.tasks': 'Assistant: task lookup',

  'analytics.personalization.tab': 'Personalization',
  'analytics.personalization.funnel': 'Suggestion journey by day',
  'analytics.personalization.content': 'Answers by content',

  'features.group.other': 'Other',
  'kit.notes': 'Notes (optional)',
  'kit.rejectedBy': '{name} sent it back for more editing.',
  'jobs.rerunAskedByName': '{name} asked to re-run it.',
};
