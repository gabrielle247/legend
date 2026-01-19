// ==========================================
// FILE: ./app_libs.dart
// ==========================================

// -----------------------------------------------------------------------------
// 1. DART CORE
// -----------------------------------------------------------------------------
export 'dart:convert';
export 'dart:math';

// -----------------------------------------------------------------------------
// 2. FLUTTER
// -----------------------------------------------------------------------------
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';

// NOTE: Do NOT export Cupertino here (RefreshCallback clash).
// If a file needs Cupertino, import it locally in that file.
// export 'package:flutter/cupertino.dart'; // intentionally not exported

// -----------------------------------------------------------------------------
// 3. 3RD PARTY PACKAGES
// -----------------------------------------------------------------------------
export 'package:go_router/go_router.dart';
export 'package:google_nav_bar/google_nav_bar.dart';
export 'package:provider/provider.dart';
export 'package:supabase_flutter/supabase_flutter.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:google_fonts/google_fonts.dart';
export 'package:intl/intl.dart' hide TextDirection;
export 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// 4. APP CORE
// -----------------------------------------------------------------------------
export 'package:legend/app.dart';
export 'package:legend/app_init.dart';
export 'package:legend/app_router.dart';

// -----------------------------------------------------------------------------
// 5. CONSTANTS
// -----------------------------------------------------------------------------
export 'package:legend/data/constants/app_constants.dart';
export 'package:legend/data/constants/app_strings.dart';
export 'package:legend/data/constants/subjects.dart';

// -----------------------------------------------------------------------------
// 6. MODELS
// -----------------------------------------------------------------------------
export 'package:legend/data/models/all_models.dart';

// -----------------------------------------------------------------------------
// 7. REPOSITORIES
// -----------------------------------------------------------------------------
export 'package:legend/data/repo/auth/auth.dart';
export 'package:legend/data/repo/auth/school_repo.dart';
export 'package:legend/data/repo/dashboard_repo.dart';
export 'package:legend/data/repo/financial_repo.dart';
export 'package:legend/data/repo/student_repo.dart';

// -----------------------------------------------------------------------------
// 8. SERVICES
// -----------------------------------------------------------------------------
export 'package:legend/data/services/database_serv.dart';
export 'package:legend/data/services/auth/auth.dart';
export 'package:legend/data/services/auth/no_auth_screen.dart';
export 'package:legend/data/services/powersync/supa_connector.dart';
export 'package:legend/data/services/powersync/powersync_factory.dart';

// -----------------------------------------------------------------------------
// 9. VIEW MODELS
// -----------------------------------------------------------------------------
export 'package:legend/data/vmodels/add_student_view_model.dart';
export 'package:legend/data/vmodels/dashboard_vmodel.dart';
export 'package:legend/data/vmodels/finance_vmodel.dart';
export 'package:legend/data/vmodels/settings_vmodel.dart';
export 'package:legend/data/vmodels/stats_view_model.dart';
export 'package:legend/data/vmodels/student_logs_view_model.dart';
export 'package:legend/data/vmodels/students_vmodel.dart';

// -----------------------------------------------------------------------------
// 10. UI
// -----------------------------------------------------------------------------
export 'package:legend/screens/all_screens_export.dart';
export 'package:legend/screens/dashboard/notifications/noti_viewer.dart';
export 'package:legend/screens/utils/subject_selector_field.dart';

export 'package:legend/data/constants/app_routes.dart';
export 'package:legend/screens/finance/logging_payments.dart';
export 'package:legend/screens/settings/splash_screen.dart';
