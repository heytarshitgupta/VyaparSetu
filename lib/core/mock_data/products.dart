class Product {
  final String id;
  final String name;
  final String producerName;
  final String location;
  final double price;
  final String imageUrl;
  final String category;
  final String capacity;
  
  final List<String> images;
  final bool isProducerVerified;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.producerName,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.capacity,
    this.images = const [],
    this.isProducerVerified = false,
    this.description = '',
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
    capacity: '100 pcs available',
    images: [
      'https://picsum.photos/seed/p1/800/800',
      'https://picsum.photos/seed/p1_2/800/800',
      'https://picsum.photos/seed/p1_3/800/800',
    ],
    isProducerVerified: true,
    description: 'Authentic handwoven khadi shirt made by a collective of rural artisans in Gujarat. Sourced ethically with 100% organic cotton, perfect for bulk retail orders.',
  ),
  const Product(
    id: 'p2',
    name: 'Organic Turmeric Powder',
    producerName: 'Green Earth Farms',
    location: 'Kerala, India',
    price: 350.0,
    imageUrl: 'https://picsum.photos/seed/p2/400/400',
    category: 'Spices',
    capacity: '50kg available',
    images: [
      'https://picsum.photos/seed/p2/800/800',
      'https://picsum.photos/seed/p2_2/800/800',
    ],
    isProducerVerified: true,
    description: 'High curcumin content organic turmeric powder. Farmed using sustainable practices without any chemical pesticides.',
  ),
  const Product(
    id: 'p3',
    name: 'Terracotta Vase',
    producerName: 'Mitti Craft',
    location: 'Rajasthan, India',
    price: 850.0,
    imageUrl: 'https://picsum.photos/seed/p3/400/400',
    category: 'Handicrafts',
    capacity: '20 pcs available',
    images: [
      'https://picsum.photos/seed/p3/800/800',
      'https://picsum.photos/seed/p3_2/800/800',
    ],
    isProducerVerified: false,
    description: 'Handcrafted terracotta vase featuring traditional Rajasthani motifs. Ideal for home decor retailers.',
  ),
  const Product(
    id: 'p4',
    name: 'Raw Wild Honey',
    producerName: 'Forest Gatherers',
    location: 'Uttarakhand, India',
    price: 600.0,
    imageUrl: 'https://picsum.photos/seed/p4/400/400',
    category: 'Food',
    capacity: '150 bottles available',
    images: [
      'https://picsum.photos/seed/p4/800/800',
    ],
    isProducerVerified: true,
    description: 'Pure, unpasteurized wild honey gathered sustainably from the deep forests of Uttarakhand.',
  ),
  const Product(
    id: 'p5',
    name: 'Bamboo Storage Basket',
    producerName: 'Cane Creations',
    location: 'Assam, India',
    price: 450.0,
    imageUrl: 'https://picsum.photos/seed/p5/400/400',
    category: 'Handicrafts',
    capacity: '30 pcs available',
    images: [
      'https://picsum.photos/seed/p5/800/800',
      'https://picsum.photos/seed/p5_2/800/800',
    ],
    isProducerVerified: false,
    description: 'Eco-friendly, durable bamboo storage baskets woven by local Assamese artisans.',
  ),
  const Product(
    id: 'p6',
    name: 'Cold Pressed Coconut Oil',
    producerName: 'Coastal Mills',
    location: 'Tamil Nadu, India',
    price: 550.0,
    imageUrl: 'https://picsum.photos/seed/p6/400/400',
    category: 'Food',
    capacity: '200 Liters available',
    images: [
      'https://picsum.photos/seed/p6/800/800',
    ],
    isProducerVerified: true,
    description: '100% pure cold pressed coconut oil, extracted from fresh premium coconuts. Ideal for culinary and cosmetic use.',
  ),
];
