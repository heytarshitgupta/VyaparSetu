class BuyerRequest {
  final String id;
  final String title;
  final String status; // 'Open', 'Responses Received', 'Closed'
  final String date;
  final String quantity;

  const BuyerRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    required this.quantity,
  });
}

final List<BuyerRequest> mockRequests = [
  const BuyerRequest(
    id: 'r1',
    title: 'Requirement for Bulk Organic Cotton',
    status: 'Responses Received',
    date: '2 Days Ago',
    quantity: '500 kg',
  ),
  const BuyerRequest(
    id: 'r2',
    title: 'Looking for Handmade Soap Suppliers',
    status: 'Open',
    date: 'Just Now',
    quantity: '1000 units',
  ),
  const BuyerRequest(
    id: 'r3',
    title: 'Jute Bags for Corporate Gifting',
    status: 'Closed',
    date: 'Last Week',
    quantity: '200 units',
  ),
];
