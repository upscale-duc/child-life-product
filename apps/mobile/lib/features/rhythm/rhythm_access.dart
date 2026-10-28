import '../baby/baby_models.dart';

/// `familyCan` (packages/contracts/src/family-actions.ts, D-072 #1–#2): what a member may do in
/// Nhịp lớn lên, by role. Paid plans never change it ("Premium không đổi vai trò", ST02). The
/// server and the Rules check again; the app only hides what would be refused.
enum FamilyAction {
  rhythmCheckin('rhythm.checkin'),
  rhythmMarkDay('rhythm.markDay'),
  rhythmFeedback('rhythm.feedback'),
  rhythmSuggestions('rhythm.suggestions'),
  rhythmSetup('rhythm.setup'),
  historyRead('history.read'),
  healthRead('health.read'),
  aiGenerate('ai.generate'),
  momentsCreate('moments.create'),
  preferencesOwn('preferences.own'),
  billingManage('billing.manage'),
  familySettings('family.settings');

  const FamilyAction(this.wire);
  final String wire;
}

/// Who may make a handover (mirrors `canGenerateSummary`): Cùng nuôi, and a helper who logs care
/// for the parents (D-135 Q3). Consent and quota are the server's.
bool canGenerateHandover(Membership m) =>
    familyCan(m, FamilyAction.aiGenerate) ||
    (m.role == MemberRole.caregiver &&
        familyCan(m, FamilyAction.rhythmFeedback));

bool familyCan(Membership m, FamilyAction action) {
  final role = m.role;
  return switch (action) {
    FamilyAction.healthRead || FamilyAction.preferencesOwn => true,
    FamilyAction.rhythmCheckin ||
    FamilyAction.rhythmMarkDay ||
    FamilyAction.rhythmFeedback ||
    FamilyAction.rhythmSuggestions =>
      role == MemberRole.coParent || role == MemberRole.caregiver,
    // A relative reads care only with "Chăm sóc hằng ngày" (D-018).
    FamilyAction.historyRead =>
      role == MemberRole.coParent ||
          role == MemberRole.caregiver ||
          (role == MemberRole.relative && m.extraRights.viewDailyCare),
    FamilyAction.rhythmSetup ||
    FamilyAction.aiGenerate ||
    FamilyAction.momentsCreate => role == MemberRole.coParent,
    FamilyAction.billingManage ||
    FamilyAction.familySettings => role == MemberRole.coParent && m.isOwner,
  };
}
