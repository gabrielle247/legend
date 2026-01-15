// -----------------------------------------------------------------------------
// 1. FLUTTER & 3RD PARTY PACKAGES
// -----------------------------------------------------------------------------
export 'package:flutter/material.dart';
export 'package:go_router/go_router.dart';
export 'package:google_nav_bar/google_nav_bar.dart';
export 'package:provider/provider.dart';
export 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// 2. APP CORE & CONSTANTS
// -----------------------------------------------------------------------------
export 'package:legend/app.dart';
export 'package:legend/app_init.dart';
export 'package:legend/app_router.dart';
export 'package:legend/data/constants/app_constants.dart';
export 'package:legend/data/constants/app_strings.dart';

// -----------------------------------------------------------------------------
// 3. REPOSITORIES (DATA LAYER)
// -----------------------------------------------------------------------------
export 'package:legend/data/repo/auth/auth.dart';
export 'package:legend/data/repo/auth/school_repo.dart';
export 'package:legend/data/repo/dashboard_repo.dart';
export 'package:legend/data/repo/financial_repo.dart'; // The fixed Finance Repo
export 'package:legend/data/repo/student_repo.dart';   // The separated Student Repo

// -----------------------------------------------------------------------------
// 4. SERVICES
// -----------------------------------------------------------------------------
export 'package:legend/data/services/auth/auth.dart';

// -----------------------------------------------------------------------------
// 5. VIEW MODELS (STATE LAYER)
// -----------------------------------------------------------------------------
export 'package:legend/data/vmodels/dashboard_vmodel.dart';
export 'package:legend/data/vmodels/finance_vmodel.dart';
export 'package:legend/data/vmodels/settings_vmodel.dart';
export 'package:legend/data/vmodels/students_vmodel.dart';

// -----------------------------------------------------------------------------
// 6. UI SCREENS
// -----------------------------------------------------------------------------
export 'package:legend/screens/all_screens_export.dart';
export 'package:legend/data/services/database_serv.dart';
export 'package:legend/data/services/powersync/supa_connector.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:legend/data/services/powersync/powersync_factory.dart';

export 'package:legend/data/services/auth/no_auth_screen.dart';
export 'package:legend/data/vmodels/stats_view_model.dart';


export 'package:legend/screens/dashboard/notifications/noti_viewer.dart';
export 'package:legend/data/vmodels/add_student_view_model.dart';
export 'package:legend/screens/utils/subject_selector_field.dart';