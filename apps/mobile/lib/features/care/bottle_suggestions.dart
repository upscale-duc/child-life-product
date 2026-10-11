/// 22 "Ghi bú bình · gợi ý nhanh" (v1.0 improvement 346:47151): four quick-pick amounts for the
/// baby's age. Figma draws only "bé 3 tuần → 60 · 90 · 120 · 150 ml"; the other rows are an
/// engineering draft from common bottle-feeding guidance, for owner review (P-126). They are
/// shortcuts, not advice: the field stays free and optional (R-012).
List<int> bottleSuggestions(int? ageDays) {
  if (ageDays == null) return const [60, 90, 120, 150];
  if (ageDays < 7) return const [30, 45, 60, 75];
  if (ageDays < 28) return const [60, 90, 120, 150];
  if (ageDays < 61) return const [90, 120, 150, 180];
  if (ageDays < 122) return const [120, 150, 180, 210];
  return const [150, 180, 210, 240];
}
