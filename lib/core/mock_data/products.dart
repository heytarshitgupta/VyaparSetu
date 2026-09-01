class Product {
  final String id;
  final String name;
  final String producerName;
  final String location;
  final double price;
  final String imageUrl;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.producerName,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

final List<Product> mockProducts = [
  const Product(
    id: 'p1',
    name: 'Handwoven Khadi Shirt',
    producerName: 'Artisan Co-op',
    location: 'Gujarat, India',
    price: 1250.0,
    imageUrl: 'https://picsum.photos/seed/p1/400/400',
    category: 'Textiles',
  ),
  const Product(
    id: 'p2',
    name: 'Organic Turmeric Powder',
    producerName: 'Green Earth Farms',
    location: 'Kerala, India',
    price: 350.0,
    imageUrl: 'https://picsum.photos/seed/p2/400/400',
    category: 'Spices',
  ),
  const Product(
    id: 'p3',
    name: 'Terracotta Vase',
    producerName: 'Mitti Craft',
    location: 'Rajasthan, India',
    price: 850.0,
    imageUrl: 'https://picsum.photos/seed/p3/400/400',
    category: 'Handicrafts',
  ),
  const Product(
    id: 'p4',
    name: 'Raw Wild Honey',
    producerName: 'Forest Gatherers',
    location: 'Uttarakhand, India',
    price: 600.0,
    imageUrl: 'https://picsum.photos/seed/p4/400/400',
    category: 'Food',
  ),
  const Product(
    id: 'p5',
    name: 'Bamboo Storage Basket',
    producerName: 'Cane Creations',
    location: 'Assam, India',
    price: 450.0,
    imageUrl: 'https://picsum.photos/seed/p5/400/400',
    category: 'Handicrafts',
  ),
  const Product(
    id: 'p6',
    name: 'Cold Pressed Coconut Oil',
    producerName: 'Coastal Mills',
    location: 'Tamil Nadu, India',
    price: 550.0,
    imageUrl: 'https://picsum.photos/seed/p6/400/400',
    category: 'Food',
  ),
];
