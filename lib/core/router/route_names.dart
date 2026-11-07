class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String languageSelect = '/language-select';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';
  static const String roleSelect = '/role-select';
  static const String onboarding = '/onboarding';

  // Farmer Shell & Pages
  static const String farmerDashboard = '/farmer';
  static const String addProduct = '/farmer/add-product';
  static const String farmerOrders = '/farmer/orders';
  static const String farmerEarnings = '/farmer/earnings';
  static const String myProducts = '/farmer/my-products';

  // Consumer Shell & Pages
  static const String consumerHome = '/consumer';
  static const String productDetail = '/consumer/product/:id';
  static const String cart = '/consumer/cart';
  static const String checkout = '/consumer/checkout';
  static const String consumerOrders = '/consumer/orders';
  static const String orderDetail = '/consumer/order/:id';

  // Advisory & AI Features
  static const String cropAdvisor = '/advisor';
  static const String diseaseDetection = '/disease-scan';
  static const String krishiSahayak = '/krishi-sahayak';

  // Machinery & Store
  static const String machinery = '/machinery';
  static const String store = '/store';

  // Admin
  static const String admin = '/admin';
}

