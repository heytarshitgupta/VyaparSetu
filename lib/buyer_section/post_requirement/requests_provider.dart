import 'package:flutter/material.dart';
import '../../../core/mock_data/requests.dart';

class RequestsProvider extends ChangeNotifier {
  final List<BuyerRequest> _requests = List.from(mockRequests);

  List<BuyerRequest> get requests => _requests;

  void addRequest(BuyerRequest request) {
    _requests.insert(0, request);
    notifyListeners();
  }
}
