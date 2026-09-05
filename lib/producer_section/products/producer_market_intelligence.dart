class ProducerMarketSignal {
  const ProducerMarketSignal({
    required this.productId,
    required this.productName,
    required this.category,
    required this.district,
    required this.marketDemandScore,
    required this.monthlyUnits,
    required this.avgOrderValue,
    required this.topState,
    required this.topCity,
  });

  final String productId;
  final String productName;
  final String category;
  final String district;
  final double marketDemandScore;
  final int monthlyUnits;
  final double avgOrderValue;
  final String topState;
  final String topCity;
}

class ProducerMarketIntelligenceService {
  const ProducerMarketIntelligenceService._();

  static const List<ProducerMarketSignal> csvSeedSignals = [
    ProducerMarketSignal(
      productId: 'PROD000001',
      productName: 'Basmati (Rice)',
      category: 'Agriculture',
      district: 'Tarn Taran',
      marketDemandScore: 96.4,
      monthlyUnits: 2840,
      avgOrderValue: 1280.0,
      topState: 'Punjab',
      topCity: 'Amritsar',
    ),
    ProducerMarketSignal(
      productId: 'PROD000009',
      productName: 'Fresh Kinnow',
      category: 'Agriculture',
      district: 'Rupnagar',
      marketDemandScore: 92.1,
      monthlyUnits: 2465,
      avgOrderValue: 1195.0,
      topState: 'Punjab',
      topCity: 'Ludhiana',
    ),
    ProducerMarketSignal(
      productId: 'PROD000004',
      productName: 'Cotton Yarn',
      category: 'Textile',
      district: 'Bathinda',
      marketDemandScore: 89.8,
      monthlyUnits: 2140,
      avgOrderValue: 2450.0,
      topState: 'Punjab',
      topCity: 'Bathinda',
    ),
    ProducerMarketSignal(
      productId: 'PROD000010',
      productName: 'Desi Jaggery',
      category: 'Food processing',
      district: 'Nawanshahar',
      marketDemandScore: 88.6,
      monthlyUnits: 1870,
      avgOrderValue: 760.0,
      topState: 'Punjab',
      topCity: 'Mohali',
    ),
    ProducerMarketSignal(
      productId: 'PROD000019',
      productName: 'Hand Tools',
      category: 'Manufacturing',
      district: 'Jalandhar',
      marketDemandScore: 86.3,
      monthlyUnits: 1695,
      avgOrderValue: 1985.0,
      topState: 'Punjab',
      topCity: 'Jalandhar',
    ),
    ProducerMarketSignal(
      productId: 'PROD000013',
      productName: 'Handcrafted Sculptures',
      category: 'Handicraft',
      district: 'Mohali',
      marketDemandScore: 83.9,
      monthlyUnits: 1125,
      avgOrderValue: 3150.0,
      topState: 'Punjab',
      topCity: 'Chandigarh',
    ),
  ];

  static List<ProducerMarketSignal> getTopSignals({int limit = 4}) {
    return csvSeedSignals.take(limit).toList();
  }

  static List<ProducerMarketSignal> getSignalsForCategory(String category) {
    if (category.isEmpty) {
      return csvSeedSignals;
    }

    return csvSeedSignals
        .where((signal) => signal.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}
