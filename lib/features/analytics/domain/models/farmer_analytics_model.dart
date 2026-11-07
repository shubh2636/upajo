class BuyerStat {
  final String buyerName;
  final String location;
  final int ordersCount;
  final double totalSpent;

  const BuyerStat({
    required this.buyerName,
    required this.location,
    required this.ordersCount,
    required this.totalSpent,
  });
}

class FarmerAnalyticsModel {
  final double totalEarnings;
  final int totalOrders;
  final double totalQuintals;
  final double averageRatePerQuintal;
  final Map<String, double> earningsByCrop; // 'शरबती गेहूं': 65.0 (percent)
  final Map<String, double> monthlyTrends; // 'जून': 45000.0, 'जुलाई': 62000.0
  final List<BuyerStat> topBuyers;

  const FarmerAnalyticsModel({
    required this.totalEarnings,
    required this.totalOrders,
    required this.totalQuintals,
    required this.averageRatePerQuintal,
    required this.earningsByCrop,
    required this.monthlyTrends,
    required this.topBuyers,
  });
}
