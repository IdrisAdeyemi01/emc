import 'package:emc_core/emc_core.dart';

import '../env.dart';
import 'apps_script_timetable_repository.dart';

/// The repository for this build, or null when `EMC_API_URL` / `EMC_API_KEY`
/// weren't provided (or the URL isn't an https URL). The UI shows a setup
/// error in that case (M4).
TimetableRepository? createTimetableRepository() {
  if (!Env.isConfigured) return null;
  final url = Uri.tryParse(Env.apiUrl);
  if (url == null || url.scheme != 'https' || url.host.isEmpty) return null;
  return AppsScriptTimetableRepository(baseUrl: url, apiKey: Env.apiKey);
}
