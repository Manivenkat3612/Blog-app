// This file is now deprecated. All routing has been consolidated into `app_routes.dart`.
// Keeping the constants temporarily to avoid widespread rename churn if something still imports them.
// They simply re-export the new AppRoutes. Remove after confirming no external references.

import 'app_routes.dart';

// ignore: camel_case_types
class ModernAppRoutes extends AppRoutes {}

// ignore: camel_case_types
class ModernAppPages extends AppPages {}