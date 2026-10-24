import '../models/api_models.dart';

bool profileMutationReflected({
  required List<CompanyProfile> profiles,
  String? profileId,
  String? username,
  String? displayName,
  String? expectedStatus,
}) {
  CompanyProfile? match;
  for (final profile in profiles) {
    final sameProfile = profileId == null
        ? profile.username == username
        : profile.id == profileId;
    if (sameProfile) {
      match = profile;
      break;
    }
  }
  if (match == null) return false;
  if (displayName != null && match.displayName != displayName) return false;
  if (expectedStatus != null && match.status != expectedStatus) return false;
  return true;
}
