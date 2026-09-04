class ProducerResponse {
  final String id;
  final String producerName;
  final bool isVerified;
  final double price;
  final String quantity;
  final String leadTime;
  final String location;
  final bool isBestMatch;

  const ProducerResponse({
    required this.id,
    required this.producerName,
    required this.isVerified,
    required this.price,
    required this.quantity,
    required this.leadTime,
    required this.location,
    this.isBestMatch = false,
  });
}

final List<ProducerResponse> mockResponses = [
  const ProducerResponse(
    id: 'res1',
    producerName: 'Green Earth Farms',
    isVerified: true,
    price: 320.0,
    quantity: '500 kg',
    leadTime: '3 Days',
    location: 'Kerala, India',
    isBestMatch: true,
  ),
  const ProducerResponse(
    id: 'res2',
    producerName: 'Sunrise Organics',
    isVerified: false,
    price: 340.0,
    quantity: '400 kg',
    leadTime: '2 Days',
    location: 'Karnataka, India',
  ),
  const ProducerResponse(
    id: 'res3',
    producerName: 'Nature Co-op',
    isVerified: true,
    price: 310.0,
    quantity: '600 kg',
    leadTime: '7 Days',
    location: 'Tamil Nadu, India',
  ),
  const ProducerResponse(
    id: 'res4',
    producerName: 'Valley Producers',
    isVerified: false,
    price: 360.0,
    quantity: '500 kg',
    leadTime: '1 Day',
    location: 'Kerala, India',
  ),
];
