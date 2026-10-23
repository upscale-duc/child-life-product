/** D-012: canonical metric semantics, same ids in both Portal languages. Billing remains backlog. */
export const productAnalyticsVi: Record<string, string> = {
  'flag.product_analytics': 'Đo lường sản phẩm',
  'flag.product_analytics.desc':
    'Ghi nhận metadata hoạt động và kết quả đã xác nhận; Portal chỉ nhận số tổng hợp',
  'flag.product_analytics.offEffect':
    'Dừng thu thập mới; Care, kỷ niệm và báo cáo cũ vẫn hoạt động.',
  'pa.title': 'Phân tích sản phẩm',
  'pa.subtitle':
    'Người dùng, gia đình và những việc đã hoàn tất — dữ liệu thực, không phải lượt bấm.',
  'pa.sections': 'Mục phân tích',
  'pa.section.overview': 'Tổng quan',
  'pa.section.acquisition': 'Thu hút & quay lại',
  'pa.section.memories': 'Kỷ niệm',
  'pa.section.engagement': 'Nhắc thông minh',
  'pa.section.features': 'Sử dụng tính năng',
  'pa.section.cost': 'Chi phí vận hành',
  'pa.custom': 'Tùy chọn',
  'pa.from': 'Từ ngày',
  'pa.to': 'Đến ngày',
  'pa.apply': 'Áp dụng',
  'pa.compare': 'So với kỳ trước',
  'pa.refresh': 'Tải lại',
  'pa.locale': 'Ngôn ngữ app',
  'pa.locale.all': 'Mọi ngôn ngữ',
  'pa.locale.vi': 'Tiếng Việt',
  'pa.locale.en': 'Tiếng Anh',
  'pa.ageBand': 'Tuổi bé khi bắt đầu',
  'pa.age.all': 'Mọi nhóm tuổi',
  'pa.age.under_1m': 'Dưới 1 tháng',
  'pa.age.1_to_3m': '1 đến dưới 3 tháng',
  'pa.age.3_to_6m': '3 đến dưới 6 tháng',
  'pa.age.6_to_9m': '6 đến dưới 9 tháng',
  'pa.age.9_to_12m': '9 đến dưới 12 tháng',
  'pa.age.12m_plus': 'Từ 12 tháng',
  'pa.age.unknown': 'Chưa xác định',
  'pa.filtersNote':
    'Ngày báo cáo theo giờ Việt Nam. Bộ lọc nền tảng/ngôn ngữ có thể chưa áp dụng cho kết quả backend chưa có nguồn liên kết; chỉ số đó sẽ ghi chưa đo được. Không cộng iOS và Android thành tổng người dùng.',
  'pa.invalidDates': 'Chọn khoảng ngày hợp lệ, tối đa 366 ngày đã kết thúc.',
  'pa.costPermission': 'Bạn cần quyền xem phân tích và quyền xem Premium để xem chi phí vận hành.',
  'pa.metadata': '{from} – {to} · {zone} · Tính lúc {at}',
  'pa.recordingOff':
    'Thu thập mới đang tắt. Số liệu đã ghi nhận vẫn được đọc theo quyền; không tự bật cấu hình production.',
  'pa.preparing': 'Đang tổng hợp dữ liệu đã ghi nhận. Trang sẽ cập nhật khi bản tổng hợp sẵn sàng.',
  'pa.unavailable': 'Chưa lấy được bản tổng hợp. Kiểm tra nguồn dữ liệu hoặc thử lại.',
  'pa.noData':
    'Chưa có dữ liệu cho khoảng đã chọn. Dữ liệu thử nghiệm không được thay vào báo cáo này.',
  'pa.unsupported':
    'Bộ lọc này chưa có đủ nguồn để áp dụng; các chỉ số bị ảnh hưởng không hiển thị số liệu.',
  'pa.insufficient':
    'Chưa đủ dữ liệu để hiển thị. Nhóm phân tích cần tối thiểu {n} người dùng hoặc gia đình phù hợp.',
  'pa.definition':
    'Mã {id}. Cửa sổ {days} ngày. Tỷ lệ dùng nhóm đủ điều kiện; bản nháp, hàng đợi tải và lịch thông báo không phải kết quả hoàn tất.',
  'pa.help': 'Xem định nghĩa',
  'pa.activityTrend': 'Người dùng hoạt động theo ngày',
  'pa.metricDetails': 'Chi tiết chỉ số',
  'pa.metricCount': '{n, plural, other {# chỉ số}}',
  'pa.reasons': 'Lý do không gửi nhắc',
  'pa.col.reason': 'Lý do',
  'pa.col.metric': 'Chỉ số',
  'pa.col.value': 'Giá trị',
  'pa.col.denominator': 'Tử số / mẫu số',
  'pa.col.previous': 'Kỳ trước',
  'pa.col.status': 'Trạng thái',
  'pa.col.users': 'Người đăng ký',
  'pa.col.group': 'Nhóm',
  'pa.col.count': 'Số lượng',
  'pa.status.ready': 'Đã đối soát theo nguồn hiện có',
  'pa.status.provisional': 'Tạm tính · chờ dữ liệu muộn',
  'pa.status.no_data': 'Chưa có dữ liệu',
  'pa.status.unavailable': 'Chưa đo được',
  'pa.status.insufficient': 'Chưa đủ dữ liệu',
  'pa.status.immature': 'Chưa hết cửa sổ quan sát',
  'pa.reason.none':
    'Số tổng hợp không chứa định danh cá nhân. Kết quả theo ngày thao tác thật, không theo ngày chụp ảnh cũ.',
  'pa.reason.not_instrumented':
    'Chưa đủ instrumentation hoặc liên kết nguồn để tính đúng chỉ số này.',
  'pa.reason.small_cohort': 'Ẩn số liệu nhóm nhỏ để bảo vệ riêng tư.',
  'pa.reason.window_open': 'Cohort chưa có đủ thời gian quan sát, không tính là 0%.',
  'pa.reason.no_source': 'Chưa có nguồn chi phí đủ tin cậy; không coi là chi phí bằng 0.',
  'pa.reason.unsupported_filter': 'Nguồn hiện có chưa hỗ trợ bộ lọc đã chọn cho chỉ số này.',
  'pa.reason.history_unavailable': 'Khoảng này nằm ngoài lịch sử có bằng chứng đo lường.',
  'pa.engagement': 'Luồng nhắc theo loại',
  'pa.kind': 'Loại nhắc',
  'pa.stage.eligible': 'Đủ điều kiện',
  'pa.stage.scheduled': 'Đặt lịch',
  'pa.stage.attempted': 'Thử gửi',
  'pa.stage.accepted': 'Provider nhận',
  'pa.stage.opened': 'Đã mở',
  'pa.stage.completed': 'Hoàn tất',
  'pa.stage.dismissed': 'Bỏ qua',
  'pa.stage.snoozed': 'Để sau',
  'pa.stage.suppressed': 'Không nhắc',
  'pa.stage.cancelled': 'Đã hủy',
  'pa.stage.expired': 'Hết hạn',
  'pa.stage.unknown': 'Chưa xác minh',
  'pa.stage.failed': 'Gửi thất bại',
  'pa.deliveryNote':
    'Provider chấp nhận hoặc đã đặt lịch không chứng minh điện thoại hiển thị. Khi engine chưa ghi cohort/attribution thì không tính conversion từ bộ đếm cũ.',
  'pa.noExperiment':
    'Chưa có phân nhóm thử nghiệm được phê duyệt. Không kết luận mức tăng do reminder từ so sánh trước/sau.',
  'pa.retention': 'Quay lại đúng ngày D1 / D7 / D30',
  'pa.cohort': 'Ngày đăng ký',
  'pa.breakdown': 'Phân nhóm tổng hợp',
  'pa.breakdownNote':
    'Các nhóm nhỏ hoặc thiếu bằng chứng được ẩn. Tính năng dùng số gia đình; nền tảng, ngôn ngữ và nhóm tuổi dùng số người hoạt động.',
  'pa.dimension.module': 'Tính năng',
  'pa.dimension.platform': 'Nền tảng',
  'pa.dimension.locale': 'Ngôn ngữ',
  'pa.dimension.ageBand': 'Tuổi khi bắt đầu',
  'pa.dimension.template': 'Mẫu đã hoàn tất',
  'pa.module.care': 'Care',
  'pa.module.grow': 'Grow',
  'pa.module.remember': 'Remember',
  'pa.module.family': 'Gia đình',
  'pa.module.lumi': 'Lumi',
  'pa.module.personalization': 'Cá nhân hóa',
  'pa.module.engagement': 'Nhắc thông minh',
  'pa.quality': 'Độ phủ và giới hạn dữ liệu',
  'pa.coverageNote':
    'Chỉ hiển thị dữ liệu có nguồn. Thiếu actor, bước funnel hoặc nguồn lịch sử vẫn là chưa biết; không suy ngược từ tổng lượt. Cửa sổ mới chờ thêm 72 giờ để nhận dữ liệu muộn. Không có tuyên bố ý nghĩa thống kê khi mẫu nhỏ.',
  'pa.sourceStart':
    'Bắt đầu có bằng chứng thu thập: {at}. Bản tổng hợp được lưu đệm tối đa 5 phút.',
  'pa.costNote':
    'Token có usage từ provider khác với chi phí thực trên hóa đơn. Ước tính chỉ gồm call có đơn giá, không cộng với ước tính VND cũ. Credits không phải tiền. Render, storage và hóa đơn chưa có nguồn vẫn chưa đo được. Billing/IAP nằm backlog.',
  'pa.memoriesNote':
    'Yêu cầu upload, cloud-ready, render xong và video đã lưu là các bước riêng. Chưa có liên kết discovery → review → approve thì không suy conversion. Ảnh lịch sử chỉ tính hoạt động lúc nhập/lưu thực tế.',
  'pa.metric.A01': 'Người đăng ký mới',
  'pa.metric.A02': 'Người hoạt động trong kỳ',
  'pa.metric.A03': 'Gia đình hoạt động trong kỳ',
  'pa.metric.A02_1': 'DAU · người dùng',
  'pa.metric.A02_7': 'WAU · người dùng',
  'pa.metric.A02_30': 'MAU · người dùng',
  'pa.metric.A08': 'Activation trong 7 ngày',
  'pa.metric.A10': 'Kỷ niệm đầu trong 7 ngày',
  'pa.metric.A11': 'Gia đình có kết quả · tuần đã kết thúc',
  'pa.metric.A05_1': 'Retention D1',
  'pa.metric.A05_7': 'Retention D7',
  'pa.metric.A05_30': 'Retention D30',
  'pa.metric.M_ready': 'Media cloud-ready',
  'pa.metric.M_story': 'Story văn bản đã lưu',
  'pa.metric.M_card': 'Thiệp đã lưu',
  'pa.metric.M_video': 'Video đã lưu',
  'pa.metric.M_rendered': 'Video render xong',
  'pa.metric.M_render_failed': 'Job từng thất bại',
  'pa.metric.M_upload': 'Yêu cầu upload media',
  'pa.metric.M_review': 'Lượt mở review hợp lệ',
  'pa.metric.M_video_requested': 'Yêu cầu tạo video',
  'pa.metric.M_share': 'Lượt mở bảng chia sẻ',
  'pa.metric.M_discovered': 'Discovery cohort',
  'pa.metric.M_approved': 'Approval cohort',
  'pa.metric.M_cloud_conversion': 'Discovery → cloud-ready',
  'pa.metric.C_calls': 'Provider calls ghi nhận',
  'pa.metric.C_input': 'Input tokens ghi nhận',
  'pa.metric.C_output': 'Output tokens ghi nhận',
  'pa.metric.C_cached': 'Cached input tokens',
  'pa.metric.C_unknown': 'Call chưa biết usage',
  'pa.metric.C_rated': 'Call đủ đơn giá',
  'pa.metric.C_estimate': 'Ước tính AI từ token · USD',
  'pa.metric.C_actual': 'Chi phí AI đã đối soát hóa đơn',
  'pa.metric.C_render': 'Chi phí render',
  'pa.metric.C_storage': 'Chi phí storage',
  'pa.metric.C_credits': 'Credits đã committed',
};

export const productAnalyticsEn: Record<string, string> = {
  'flag.product_analytics': 'Product measurement',
  'flag.product_analytics.desc':
    'Collects operational metadata and confirmed outcomes; Portal receives aggregates only',
  'flag.product_analytics.offEffect':
    'Stops new collection; Care, memories and legacy reports continue.',
  'pa.title': 'Product analytics',
  'pa.subtitle': 'People, families and completed actions — measured from real sources.',
  'pa.sections': 'Analytics sections',
  'pa.section.overview': 'Overview',
  'pa.section.acquisition': 'Acquisition & retention',
  'pa.section.memories': 'Memories',
  'pa.section.engagement': 'Smart Engagement',
  'pa.section.features': 'Feature adoption',
  'pa.section.cost': 'Operational cost',
  'pa.custom': 'Custom',
  'pa.from': 'From',
  'pa.to': 'To',
  'pa.apply': 'Apply',
  'pa.compare': 'Compare previous period',
  'pa.refresh': 'Refresh',
  'pa.locale': 'App language',
  'pa.locale.all': 'All languages',
  'pa.locale.vi': 'Vietnamese',
  'pa.locale.en': 'English',
  'pa.ageBand': 'Child age at entry',
  'pa.age.all': 'All age groups',
  'pa.age.under_1m': 'Under 1 month',
  'pa.age.1_to_3m': '1 to under 3 months',
  'pa.age.3_to_6m': '3 to under 6 months',
  'pa.age.6_to_9m': '6 to under 9 months',
  'pa.age.9_to_12m': '9 to under 12 months',
  'pa.age.12m_plus': '12 months and older',
  'pa.age.unknown': 'Unknown',
  'pa.filtersNote':
    'Reporting days use Vietnam time. Platform/language filters may be unavailable for backend outcomes without source attribution. iOS and Android users overlap; do not add them together.',
  'pa.invalidDates': 'Choose a valid range of up to 366 completed days.',
  'pa.costPermission':
    'Analytics view and Premium view permissions are required for operational cost.',
  'pa.metadata': '{from} – {to} · {zone} · Computed {at}',
  'pa.recordingOff':
    'New collection is off. Authorized historical reporting remains available; production configuration is not enabled automatically.',
  'pa.preparing':
    'Aggregating recorded observations. This page will update when the snapshot is ready.',
  'pa.unavailable': 'The aggregate snapshot is unavailable. Check the data source or retry.',
  'pa.noData': 'No data for this range. Test fixtures are never substituted into this report.',
  'pa.unsupported':
    'This filter is not supported by the available source. Affected metrics are withheld.',
  'pa.insufficient':
    'Insufficient data to display. A breakdown needs at least {n} eligible users or families.',
  'pa.definition':
    'Metric {id}. Window: {days} days. Rates use eligible cohorts; drafts, upload queues and notification schedules are not completions.',
  'pa.help': 'Definition',
  'pa.activityTrend': 'Daily active users',
  'pa.metricDetails': 'Metric details',
  'pa.metricCount': '{n, plural, one {# metric} other {# metrics}}',
  'pa.reasons': 'Why no reminder was sent',
  'pa.col.reason': 'Reason',
  'pa.col.metric': 'Metric',
  'pa.col.value': 'Value',
  'pa.col.denominator': 'Numerator / denominator',
  'pa.col.previous': 'Previous period',
  'pa.col.status': 'Status',
  'pa.col.users': 'Registrations',
  'pa.col.group': 'Group',
  'pa.col.count': 'Count',
  'pa.status.ready': 'Computed from available sources',
  'pa.status.provisional': 'Provisional · awaiting late events',
  'pa.status.no_data': 'No data yet',
  'pa.status.unavailable': 'Not measured',
  'pa.status.insufficient': 'Insufficient data',
  'pa.status.immature': 'Observation window open',
  'pa.reason.none':
    'Aggregates contain no personal identifiers. Actions use their actual completion date, not historical photo dates.',
  'pa.reason.not_instrumented':
    'Instrumentation or source associations are not yet sufficient for this metric.',
  'pa.reason.small_cohort': 'Small groups are withheld to protect privacy.',
  'pa.reason.window_open':
    'This cohort has not completed its observation window; it is not 0% retention.',
  'pa.reason.no_source': 'No reliable cost source is connected. This does not mean zero cost.',
  'pa.reason.unsupported_filter':
    'The available source does not support this filter for this metric.',
  'pa.reason.history_unavailable': 'This range precedes recorded measurement evidence.',
  'pa.engagement': 'Reminder lifecycle by kind',
  'pa.kind': 'Reminder kind',
  'pa.stage.eligible': 'Eligible',
  'pa.stage.scheduled': 'Scheduled',
  'pa.stage.attempted': 'Attempted',
  'pa.stage.accepted': 'Provider accepted',
  'pa.stage.opened': 'Opened',
  'pa.stage.completed': 'Completed',
  'pa.stage.dismissed': 'Dismissed',
  'pa.stage.snoozed': 'Snoozed',
  'pa.stage.suppressed': 'Suppressed',
  'pa.stage.cancelled': 'Cancelled',
  'pa.stage.expired': 'Expired',
  'pa.stage.unknown': 'Unknown',
  'pa.stage.failed': 'Dispatch failed',
  'pa.deliveryNote':
    'Provider acceptance and scheduling do not prove device display. Legacy counts cannot produce a conversion rate without eligibility and outcome associations.',
  'pa.noExperiment':
    'No approved experimental assignment is connected. Before/after comparisons do not establish incremental reminder lift.',
  'pa.retention': 'Exact-day D1 / D7 / D30 retention',
  'pa.cohort': 'Registration day',
  'pa.breakdown': 'Aggregate breakdown',
  'pa.breakdownNote':
    'Small or unverified groups are withheld. Modules count families; platform, language and entry-age groups count active users.',
  'pa.dimension.module': 'Feature',
  'pa.dimension.platform': 'Platform',
  'pa.dimension.locale': 'Language',
  'pa.dimension.ageBand': 'Age at entry',
  'pa.dimension.template': 'Completed template',
  'pa.module.care': 'Care',
  'pa.module.grow': 'Grow',
  'pa.module.remember': 'Remember',
  'pa.module.family': 'Family',
  'pa.module.lumi': 'Lumi',
  'pa.module.personalization': 'Personalization',
  'pa.module.engagement': 'Smart Engagement',
  'pa.quality': 'Data coverage and limitations',
  'pa.coverageNote':
    'Only source-backed data is shown. Missing actors, funnel stages or historical evidence remain unknown. Recent windows allow 72 hours for late observations. Small samples do not support statistical-significance claims.',
  'pa.sourceStart':
    'Collection evidence begins: {at}. Aggregate snapshots are cached for up to 5 minutes.',
  'pa.costNote':
    'Provider-observed tokens differ from invoiced expense. Estimates include rated calls only and are not added to legacy VND estimates. Credits are not money. Render, storage and invoice costs remain unavailable without sources. IAP/billing is backlogged.',
  'pa.memoriesNote':
    'Upload requested, cloud-ready, rendered and filed are separate stages. Missing discovery/review/approval joins do not become conversion estimates. Historical photos count activity when actually imported or saved.',
  'pa.metric.A01': 'New registrations',
  'pa.metric.A02': 'Active users in range',
  'pa.metric.A03': 'Active families in range',
  'pa.metric.A02_1': 'DAU · users',
  'pa.metric.A02_7': 'WAU · users',
  'pa.metric.A02_30': 'MAU · users',
  'pa.metric.A08': 'Activation within 7 days',
  'pa.metric.A10': 'First Memory within 7 days',
  'pa.metric.A11': 'Meaningful families · closed week',
  'pa.metric.A05_1': 'D1 retention',
  'pa.metric.A05_7': 'D7 retention',
  'pa.metric.A05_30': 'D30 retention',
  'pa.metric.M_ready': 'Cloud-ready media',
  'pa.metric.M_story': 'Saved text Stories',
  'pa.metric.M_card': 'Filed cards',
  'pa.metric.M_video': 'Filed videos',
  'pa.metric.M_rendered': 'Rendered videos',
  'pa.metric.M_render_failed': 'Jobs with a failure',
  'pa.metric.M_upload': 'Media upload requests',
  'pa.metric.M_review': 'Authorized review opens',
  'pa.metric.M_video_requested': 'Video requests',
  'pa.metric.M_share': 'Share sheet opens',
  'pa.metric.M_discovered': 'Discovery cohort',
  'pa.metric.M_approved': 'Approval cohort',
  'pa.metric.M_cloud_conversion': 'Discovery → cloud-ready',
  'pa.metric.C_calls': 'Observed provider calls',
  'pa.metric.C_input': 'Observed input tokens',
  'pa.metric.C_output': 'Observed output tokens',
  'pa.metric.C_cached': 'Cached input tokens',
  'pa.metric.C_unknown': 'Calls with unknown usage',
  'pa.metric.C_rated': 'Rated calls',
  'pa.metric.C_estimate': 'Token-based AI estimate · USD',
  'pa.metric.C_actual': 'Invoice-reconciled AI cost',
  'pa.metric.C_render': 'Render cost',
  'pa.metric.C_storage': 'Storage cost',
  'pa.metric.C_credits': 'Committed credits',
};

const labels: Array<[string, string, string]> = [
  ['pa.chapter', 'Chapter', 'Chapter'],
  ['pa.chapter.all', 'Mọi Chapter', 'All Chapters'],
  [
    'pa.chapter.chapter01',
    'Chapter 01 · cần mapping nguồn',
    'Chapter 01 · source mapping required',
  ],
  ['pa.chapter.unknown', 'Chưa được gán Chapter', 'Unassigned Chapter'],
  ['pa.context', 'Ngữ cảnh', 'Context'],
  ['pa.context.all', 'Mọi ngữ cảnh', 'All contexts'],
  ['pa.context.current', 'Hiện tại / sắp tới', 'Current / upcoming'],
  ['pa.context.retrospective', 'Kỷ niệm hồi cứu', 'Retrospective memories'],
  ['pa.context.unknown', 'Chưa xác định', 'Unknown'],
  ['pa.familyTrend', 'Gia đình hoạt động theo ngày', 'Daily active families'],
  [
    'pa.unknownActors',
    'Kết quả chưa nối được người thực hiện: {n}',
    'Completions without actor attribution: {n}',
  ],
  [
    'pa.lateObservations',
    'Quan sát đến muộn hơn 72 giờ: {n}',
    'Observations arriving more than 72 hours late: {n}',
  ],
  ['pa.metric.F02', 'Gia đình dùng từ hai module', 'Families using at least two modules'],
  [
    'pa.metric.F04',
    'Gia đình có từ hai người tương tác thực',
    'Families with at least two active contributors/viewers',
  ],
  [
    'pa.metric.E_ENG-01',
    'Ảnh chờ review · hoàn tất / đủ điều kiện',
    'Pending photos · completed / eligible',
  ],
  [
    'pa.metric.E_ENG-02',
    'Mốc kỷ niệm · hoàn tất / đủ điều kiện',
    'Milestones · completed / eligible',
  ],
  [
    'pa.metric.E_ENG-03',
    'Digest tuần · hoàn tất / đủ điều kiện',
    'Weekly digest · completed / eligible',
  ],
  ['pa.metric.E_ENG-04', 'Care · hoàn tất / đủ điều kiện', 'Care · completed / eligible'],
  ['pa.metric.E_ENG-05', 'Gia đình · hoàn tất / đủ điều kiện', 'Family · completed / eligible'],
  ['pa.metric.E_ENG-06', 'Lumi · hoàn tất / đủ điều kiện', 'Lumi · completed / eligible'],
];
for (const [id, vi, en] of labels) {
  productAnalyticsVi[id] = vi;
  productAnalyticsEn[id] = en;
}

const definitions: Array<[string, string, string]> = [
  [
    'A01',
    'Tài khoản có sự kiện đăng ký từ Auth được xác minh trong khoảng báo cáo; loại staff. Metadata khôi phục hoặc tài khoản khách liên kết chưa có bằng chứng không được đoán là đăng ký mới.',
    'Verified Auth registration events in the reporting range, excluding staff. Metadata recovery or linked guests without registration evidence are not guessed as new registrations.',
  ],
  [
    'A02',
    'Số người đăng nhập đã mở app, đếm một lần trong khoảng chọn. Nhiều thiết bị hoặc mở nhiều ngày không làm tăng số người.',
    'Distinct authenticated people with observed app foreground activity in the selected range. Devices and repeated daily opens do not multiply users.',
  ],
  [
    'A03',
    'Số gia đình được mở đúng ngữ cảnh hoặc có kết quả hợp lệ trong khoảng chọn. Không tự tính mọi gia đình mà một người là thành viên.',
    'Distinct families with an authorized context view or qualified outcome in range. A user’s other unopened memberships are not automatically active.',
  ],
  [
    'A02_1',
    'Số người hoạt động trong một ngày báo cáo đã kết thúc.',
    'Distinct active users on the last completed reporting day.',
  ],
  [
    'A02_7',
    'Hợp của những người hoạt động trong bảy ngày kết thúc ở ngày cuối đã chọn; không cộng DAU.',
    'Exact union of active users in the seven days ending on the selected final day, not the sum of DAUs.',
  ],
  [
    'A02_30',
    'Hợp của những người hoạt động trong 30 ngày kết thúc ở ngày cuối đã chọn; không cộng WAU.',
    'Exact union of active users in the 30 days ending on the selected final day, not summed WAUs.',
  ],
  [
    'A08',
    'Người có kết quả Care/Grow, media sẵn sàng, Story hoặc keepsake đã lưu, hoặc chủ động xem nội dung người khác chia sẻ, trong 7×24 giờ từ đăng ký. Mẫu số là cohort đăng ký đã hết cửa sổ và chờ thêm 72 giờ.',
    'Registered users with a qualified Care/Grow, ready media, saved Story/keepsake or intentional authorized shared-content view within 7×24 hours. Denominator: registration cohorts whose window and 72-hour settlement have ended.',
  ],
  [
    'A10',
    'Người ở vai trò tạo nội dung có media đầu tiên cloud-ready trong bảy ngày đăng ký, trên cohort cùng vai trò đã đủ thời gian. Approved hoặc queued chưa phải ready.',
    'Creator-role users with their first cloud-ready media within seven days of registration, over mature eligible creator cohorts. Approval and queueing are not readiness.',
  ],
  [
    'A11',
    'Gia đình có ít nhất một kết quả Care/Grow, media sẵn sàng, Story hoặc keepsake đã lưu trong tuần ISO vừa kết thúc. Một gia đình nhiều người/nhiều bé vẫn chỉ tính một lần.',
    'Distinct families with a confirmed Care/Grow, ready media, saved Story or filed keepsake in the last closed ISO week. Multiple caregivers and babies still count once.',
  ],
  [
    'A05_1',
    'Cohort đăng ký quay lại đúng ngày lịch D1 theo giờ Việt Nam, chia cho cohort đã đủ thời gian quan sát; không phải mở bất kỳ ngày nào sau đăng ký.',
    'Registration cohort users active on exact Vietnam calendar day D1, divided by mature cohort users; not activity on any later day.',
  ],
  [
    'A05_7',
    'Cohort đăng ký hoạt động đúng ngày D7. Ô chưa hết ngày D7 và thêm 72 giờ chờ dữ liệu được giữ chưa hoàn tất.',
    'Registration cohort activity on exact day D7. Cells remain immature until that day and 72 hours of late-data settlement have ended.',
  ],
  [
    'A05_30',
    'Cohort đăng ký hoạt động đúng ngày D30; khác chỉ số D30 theo cửa sổ 28–32 ngày của báo cáo cũ.',
    'Registration cohort activity on exact day D30, distinct from the legacy day-28–32 windowed metric.',
  ],
  [
    'M_ready',
    'Media được server xác nhận status=ready. Ngày hoàn tất là readyAt, không phải ngày chụp hoặc ngày mốc lịch sử.',
    'Media confirmed status=ready by the server, counted at readiness rather than historical capture or occasion dates.',
  ],
  [
    'M_story',
    'Story văn bản chuyển sang saved một lần theo nguồn; bản nháp AI chưa tính hoàn tất.',
    'Text Stories transitioning to saved once per logical source. AI-generated drafts are not completions.',
  ],
  [
    'M_card',
    'Thiệp tạo có chủ đích đã thành media ready; giữ riêng với video và bản xem thử.',
    'Explicitly created cards whose media is ready, separate from videos and previews.',
  ],
  [
    'M_video',
    'Job completed đã có memoryId được backend lưu vào Memories. Render xong nhưng chưa filed không tính.',
    'Completed jobs filed into Memories with a server memoryId. Render success without filing does not count.',
  ],
  [
    'M_rendered',
    'Job đạt trạng thái render completed, trước khi xác nhận đã lưu thành phẩm.',
    'Logical jobs reaching render-completed status, separate from successful filing.',
  ],
  [
    'M_render_failed',
    'Job từng có trạng thái failed trong kỳ; có thể đã retry thành công sau đó. Không lấy số này suy ra tỷ lệ lỗi cuối cùng.',
    'Jobs with a failed state observed in range; retries may later succeed. This count is not a final-failure rate.',
  ],
  [
    'M_upload',
    'Media có yêu cầu upload hợp lệ; có thể đang chờ quota hoặc đang tải. Chưa phải số ảnh được duyệt hay lưu xong.',
    'Media with validated upload requests, including waiting-quota/uploading states. Not photo approvals or completed saves.',
  ],
  [
    'M_review',
    'Lượt mở màn review được gắn đúng người và nguồn có quyền; không suy số ảnh đã xem từ số lượt này.',
    'Authorized review opens associated with the actor/source. Open counts do not prove how many photos were reviewed.',
  ],
  [
    'M_video_requested',
    'Yêu cầu tạo video tạo được logical job mới; retry và file thành phẩm là các bước khác.',
    'Accepted requests creating logical video jobs. Retry attempts and filed results are separate stages.',
  ],
  [
    'M_share',
    'Share sheet đã mở cho video có quyền xem. Không chứng minh chia sẻ thành công hoặc người nhận đã xem.',
    'Share sheet opens for authorized filed videos, not proof of completed sharing or recipient views.',
  ],
  [
    'M_discovered',
    'Cần episode và thời điểm phát hiện ổn định theo nguồn local. Chưa có liên kết này thì để chưa đo được, không lấy số ảnh gợi ý làm cohort.',
    'Requires stable local episodes and discovery timestamps. Without this association, suggestion totals are not a discovery cohort.',
  ],
  [
    'M_approved',
    'Cần liên kết lựa chọn duyệt với từng discovery cohort; tổng approved cũ không đủ tính conversion.',
    'Requires approval associations to discovery cohorts; legacy approved totals cannot provide cohort conversion.',
  ],
  [
    'M_cloud_conversion',
    'Ảnh trong cùng discovery cohort được review, duyệt và server ready trong cửa sổ. Thiếu bước hoặc batch join vẫn là unknown.',
    'Same-cohort photos reviewed, approved and server-ready within the conversion window. Missing stages or batch joins remain unknown.',
  ],
  [
    'F02',
    'Gia đình có hành động hợp lệ trong ít nhất hai module khác nhau. Một record tăng trưởng không được tính thêm lần nữa vào Care.',
    'Families with qualified usage in at least two distinct modules. One growth record is not also counted as a Care action.',
  ],
  [
    'F04',
    'Gia đình có ít nhất hai tài khoản thực hiện hành động hoặc xem nội dung được người khác chia sẻ. Chỉ có thành viên được mời chưa đủ chứng minh phối hợp.',
    'Families with at least two distinct people performing qualified actions or viewing content shared by someone else. Membership presence alone is not collaboration.',
  ],
  [
    'C_calls',
    'Call thực sự được observer provider ghi nhận, bao gồm các call lỗi. Không lấy quota credits làm số call.',
    'Provider calls recorded by the usage observer, including failures. Commercial credits are not provider call counts.',
  ],
  [
    'C_input',
    'Input tokens do provider trả về cho các call có usage; call thiếu usage giữ riêng, không quy về 0.',
    'Provider-reported input tokens. Missing usage remains unknown rather than zero.',
  ],
  [
    'C_output',
    'Output tokens do provider trả về; không suy bằng độ dài câu trả lời hoặc credits.',
    'Provider-reported output tokens, not estimates from answer length or credits.',
  ],
  [
    'C_cached',
    'Cached input tokens provider ghi rõ. Chỉ hiển thị khi mọi call trong kỳ có breakdown cache; dữ liệu cũ thiếu bằng chứng giữ chưa đo được.',
    'Explicit provider cached input tokens. Shown only when every call has cache coverage; legacy unknown breakdowns remain unavailable.',
  ],
  [
    'C_unknown',
    'Số call ghi nhận chưa có đủ token usage từ provider.',
    'Observed calls lacking sufficient provider token usage.',
  ],
  [
    'C_rated',
    'Call có usage và đơn giá/model/version hợp lệ để tính ước tính, chưa phải đã đối soát hóa đơn.',
    'Calls with valid usage/model/rate-version data for estimation, not invoice reconciliation.',
  ],
  [
    'C_estimate',
    'Ước tính USD từ token có đơn giá theo version cấu hình. Không bao gồm call chưa đủ usage/rate; không phải chi phí invoice thực tế.',
    'USD estimate from rated observed tokens using configured rate versions. Excludes unrated calls and is not an actual invoice amount.',
  ],
  [
    'C_actual',
    'Chỉ có khi đối soát được nguồn hóa đơn provider đã duyệt; chưa có nguồn không đồng nghĩa không tốn phí.',
    'Available only from approved reconciled provider statements. Missing source does not mean no expense.',
  ],
  [
    'C_render',
    'Cần metering compute hoặc chi phí đã phân bổ đáng tin cậy; thời lượng video xuất ra không phải billable compute time.',
    'Requires measured compute or reliable cost allocation. Output video duration is not billable compute time.',
  ],
  [
    'C_storage',
    'Cần byte-hours, egress/requests hoặc chi phí đã đối soát; quota dung lượng gia đình không phải hóa đơn lưu trữ.',
    'Requires byte-hours, egress/requests or reconciled cost. Household storage quota is not a storage invoice.',
  ],
  [
    'C_credits',
    'Units trong quota ledger có state committed, giữ riêng với reserved/released. Không phải token hay tiền.',
    'Committed quota-ledger units, separate from reserved/released units. Credits are neither tokens nor currency.',
  ],
];
for (const [id, vi, en] of definitions) {
  productAnalyticsVi[`pa.definition.${id}`] = vi;
  productAnalyticsEn[`pa.definition.${id}`] = en;
}
for (const kind of ['ENG-01', 'ENG-02', 'ENG-03', 'ENG-04', 'ENG-05', 'ENG-06']) {
  productAnalyticsVi[`pa.definition.E_${kind}`] =
    'Cơ hội đủ điều kiện có kết quả đúng loại trong cửa sổ do nguồn xác nhận, chia cho cohort đã hết cửa sổ và 72 giờ chờ dữ liệu. Không cần mở push để được tính hoàn tất; không chứng minh tác động nhân quả.';
  productAnalyticsEn[`pa.definition.E_${kind}`] =
    'Qualified opportunities completed with the correct outcome within their source-defined window, divided by mature eligible cohorts after 72-hour settlement. Direct completion counts without a push open; this is not causal lift.';
}
const reasons: Array<[string, string, string]> = [
  ['none', 'Không có lý do bổ sung', 'No additional reason'],
  ['duplicate', 'Cơ hội trùng', 'Duplicate opportunity'],
  ['source_resolved', 'Nguồn đã được xử lý', 'Source resolved'],
  ['not_authorized', 'Không còn quyền', 'No longer authorized'],
  ['user_choice', 'Theo lựa chọn người dùng', 'User choice'],
  ['disabled', 'Kênh/tính năng đã tắt', 'Channel/feature disabled'],
  ['window_closed', 'Hết cửa sổ hữu ích', 'Validity window closed'],
  ['awaiting_verification', 'Chờ xác minh nguồn', 'Awaiting verification'],
  ['fatigue_paused', 'Tạm dừng do mệt mỏi thông báo', 'Paused for notification fatigue'],
  ['post_completion_quiet', 'Giãn nhắc sau hoàn tất', 'Quiet period after completion'],
  ['channel_unavailable', 'Kênh chưa sẵn sàng', 'Channel unavailable'],
  ['holdout', 'Nhóm đối chứng đã được phân', 'Assigned control group'],
  ['not_due', 'Chưa tới thời điểm', 'Not due'],
  ['snoozed', 'Người dùng để sau', 'Snoozed'],
  ['quiet_hours', 'Giờ yên tĩnh', 'Quiet hours'],
  ['budget', 'Đã chạm hạn mức nhắc', 'Frequency cap reached'],
  ['higher_priority', 'Nhường cơ hội ưu tiên hơn', 'Higher-priority opportunity'],
  ['digest_member', 'Đã gom vào digest', 'Grouped into digest'],
  ['reserved', 'Đã giữ slot hợp lệ', 'Valid slot reserved'],
];
for (const [id, vi, en] of reasons) {
  productAnalyticsVi[`pa.suppression.${id}`] = vi;
  productAnalyticsEn[`pa.suppression.${id}`] = en;
}

const engFlags = [
  ['engagementEnabled', 'Gợi ý thông minh', 'Smart Engagement'],
  ['engagementPushEnabled', 'Push gợi ý chủ động', 'Proactive suggestion push'],
  ['engagementPendingEnabled', 'Ảnh chờ chọn lưu', 'Pending photos'],
  ['engagementMilestoneEnabled', 'Video theo mốc kỷ niệm', 'Memory milestone campaigns'],
  ['engagementSixMonthEnabled', 'Mốc sáu tháng', 'Six-month campaign'],
  ['engagementWeeklyEnabled', 'Kỷ niệm tuần', 'Weekly memories'],
  ['engagementFamilyEnabled', 'Gợi ý hoạt động gia đình', 'Family recap'],
  ['engagementLumiEnabled', 'Gợi ý Lumi', 'Lumi insight'],
  ['engagementFatigueEnabled', 'Giảm tần suất gợi ý', 'Suggestion fatigue policy'],
  ['engagementDigestGroupingEnabled', 'Gom gợi ý', 'Suggestion grouping'],
  ['engagementExperimentEnabled', 'Thử nghiệm engagement', 'Engagement experiments'],
];
for (const [key, vi, en] of engFlags) {
  productAnalyticsVi[`flag.${key}`] = vi!;
  productAnalyticsEn[`flag.${key}`] = en!;
  productAnalyticsVi[`flag.${key}.desc`] =
    'Theo policy được duyệt; cần quyền và đồng ý riêng. Tắt mặc định.';
  productAnalyticsEn[`flag.${key}.desc`] =
    'Requires approved policy, authorization and explicit consent. Off by default.';
  productAnalyticsVi[`flag.${key}.offEffect`] =
    'Dừng lời mời mới thuộc nhóm này; lịch Care và giao dịch vẫn hoạt động.';
  productAnalyticsEn[`flag.${key}.offEffect`] =
    'Stops new proactive invitations in this group; Care schedules and transactions continue.';
}
