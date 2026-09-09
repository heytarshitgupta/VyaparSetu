import 'package:flutter/foundation.dart';
import '../../core/mock_data/products.dart';

class WishlistProvider extends ChangeNotifier {
  final Set<String> _wishlistIds = {};

  Set<String> get wishlistIds => _wishlistIds;

  List<Product> get wishlistProducts {
    return mockProducts.where((p) => _wishlistIds.contains(p.id)).toList();
  }

  bool isWishlisted(String productId) {
    return _wishlistIds.contains(productId);
  }

  void toggleWishlist(String productId) {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    notifyListeners();
  }
}
