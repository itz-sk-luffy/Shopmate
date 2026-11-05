/// Canonical route constants and path builders for Shopmate.
/// Keep all route definitions in this file to avoid hard-coded strings.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String dashboard = '/dashboard';
  static const String orders = '/orders';
  static const String billing = '/billing';
  static const String billEdit = '/billing/edit';
  static const String products = '/products';
  static const String more = '/more';

  static const String onboarding = '/onboarding';
  static const String lock = '/lock';
  static const String lockSettings = '/lock-settings';
  static const String settings = '/settings';
  static const String categories = '/settings/categories';
  static const String customers = '/customers';
  static const String customerDetail = '/customers/:id';
  static const String expenses = '/expenses';
  static const String dayClosing = '/day-closing';
  static const String reports = '/reports';
  static const String printer = '/printer';
  static const String backup = '/backup';
  static const String backupLog = '/backup/log';
  static const String recycleBin = '/recycle-bin';
  static const String productAdd = '/products/add';
  static const String productEdit = '/products/edit/:id';
  static const String orderDetail = '/orders/:id';

  // Helper path generators for parameterized routes
  static String customerDetailPath(int id) => '/customers/$id';
  static String productEditPath(int id) => '/products/edit/$id';
  static String orderDetailPath(int id) => '/orders/$id';

  /// All registered routes for validation and unit testing
  static const List<String> allRoutes = [
    root,
    dashboard,
    orders,
    billing,
    billEdit,
    products,
    more,
    onboarding,
    lock,
    lockSettings,
    settings,
    categories,
    customers,
    customerDetail,
    expenses,
    dayClosing,
    reports,
    printer,
    backup,
    backupLog,
    recycleBin,
    productAdd,
    productEdit,
    orderDetail,
  ];
}
