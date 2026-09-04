import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';

void main() {
  group('ProductStatus Enum', () {
    test('toDbValue returns exact lowercase database string', () {
      expect(ProductStatus.draft.toDbValue(), 'draft');
      expect(ProductStatus.active.toDbValue(), 'active');
      expect(ProductStatus.hidden.toDbValue(), 'hidden');
    });

    test('fromDbValue correctly parses valid database strings', () {
      expect(ProductStatus.fromDbValue('draft'), ProductStatus.draft);
      expect(ProductStatus.fromDbValue('active'), ProductStatus.active);
      expect(ProductStatus.fromDbValue('hidden'), ProductStatus.hidden);
      expect(ProductStatus.fromDbValue('  ACTIVE  '), ProductStatus.active);
    });

    test('fromDbValue throws FormatException on unknown or invalid status', () {
      expect(
        () => ProductStatus.fromDbValue('under_review'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductStatus.fromDbValue('deleted'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductStatus.fromDbValue('archived'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductStatus.fromDbValue(''),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ProducerProduct Price Precision & Conversions', () {
    test('DB -> DOMAIN parses exact monetary strings to integer paise', () {
      expect(ProducerProduct.parsePriceToPaise('1250.50'), 125050);
      expect(ProducerProduct.parsePriceToPaise('1250.5'), 125050);
      expect(ProducerProduct.parsePriceToPaise('1250'), 125000);
      expect(ProducerProduct.parsePriceToPaise('10.05'), 1005);
      expect(ProducerProduct.parsePriceToPaise('0.01'), 1);
      expect(ProducerProduct.parsePriceToPaise(null), isNull);
    });

    test('DB -> DOMAIN parses num values deterministically via 2-decimal conversion', () {
      expect(ProducerProduct.parsePriceToPaise(1250.5), 125050);
      expect(ProducerProduct.parsePriceToPaise(1250), 125000);
      expect(ProducerProduct.parsePriceToPaise(0.01), 1);
      expect(ProducerProduct.parsePriceToPaise(10.05), 1005);
    });

    test('DB -> DOMAIN handles maximum NUMERIC(12,2) boundary cleanly', () {
      // 12 digits with 2 decimal places = 9,999,999,999.99
      expect(
        ProducerProduct.parsePriceToPaise('9999999999.99'),
        999999999999,
      );
    });

    test('DB -> DOMAIN rejects malformed or invalid price strings explicitly', () {
      expect(
        () => ProducerProduct.parsePriceToPaise('invalid_price'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProducerProduct.parsePriceToPaise('10.50.25'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProducerProduct.parsePriceToPaise('12.345'), // exceeds 2 decimal places
        throwsA(isA<FormatException>()),
      );
    });

    test('DOMAIN -> DB converts integer paise back to exact 2-decimal string', () {
      expect(ProducerProduct.paiseToDecimalString(1), '0.01');
      expect(ProducerProduct.paiseToDecimalString(100), '1.00');
      expect(ProducerProduct.paiseToDecimalString(1050), '10.50');
      expect(ProducerProduct.paiseToDecimalString(125050), '1250.50');
      expect(ProducerProduct.paiseToDecimalString(999999999999), '9999999999.99');
      expect(ProducerProduct.paiseToDecimalString(null), isNull);
    });

    test('priceDecimalString helper returns neutral decimal string without currency symbols', () {
      final sampleTimestamp = DateTime.parse('2026-09-04T12:00:00.000Z');
      final product = ProducerProduct(
        id: 'p-test',
        producerId: 'u-test',
        name: 'Item',
        pricePaise: 125050,
        createdAt: sampleTimestamp,
        updatedAt: sampleTimestamp,
      );

      expect(product.priceDecimalString, '1250.50');
      expect(product.priceDecimalString, isNot(contains('₹')));
      expect(product.priceDecimalString, isNot(contains('Rs')));

      final draftProduct = product.copyWith(setPriceNull: true);
      expect(draftProduct.priceDecimalString, isNull);
    });
  });

  group('ProducerProduct Model', () {
    final sampleTimestamp = DateTime.parse('2026-09-04T12:00:00.000Z');

    test('parses valid draft with null price, empty description and category', () {
      final json = {
        'id': 'prod-001',
        'producer_id': 'user-123',
        'name': 'Terracotta Vase',
        'description': '',
        'category': '',
        'price': null,
        'unit': 'piece',
        'images': <String>[],
        'status': 'draft',
        'created_at': '2026-09-04T12:00:00.000Z',
        'updated_at': '2026-09-04T12:00:00.000Z',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.id, 'prod-001');
      expect(product.producerId, 'user-123');
      expect(product.name, 'Terracotta Vase');
      expect(product.description, '');
      expect(product.category, '');
      expect(product.pricePaise, isNull);
      expect(product.priceDecimalString, isNull);
      expect(product.unit, 'piece');
      expect(product.images, isEmpty);
      expect(product.status, ProductStatus.draft);
      expect(product.createdAt, sampleTimestamp);
      expect(product.updatedAt, sampleTimestamp);
    });

    test('parses active product with positive numeric price and image references', () {
      final json = {
        'id': 'prod-002',
        'producer_id': 'user-123',
        'name': 'Handmade Silk Shawl',
        'description': 'Pure Banarasi silk',
        'category': 'Textiles',
        'price': '1499.50',
        'unit': 'piece',
        'images': ['prod-002/photo1.jpg', 'prod-002/photo2.jpg'],
        'status': 'active',
        'created_at': '2026-09-04T12:00:00.000Z',
        'updated_at': '2026-09-04T12:30:00.000Z',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.id, 'prod-002');
      expect(product.name, 'Handmade Silk Shawl');
      expect(product.pricePaise, 149950);
      expect(product.priceDecimalString, '1499.50');
      expect(product.status, ProductStatus.active);
      expect(product.images.length, 2);
      expect(product.images[0], 'prod-002/photo1.jpg');
    });

    test('parses hidden product correctly', () {
      final json = {
        'id': 'prod-003',
        'producer_id': 'user-123',
        'name': 'Wood Inlay Box',
        'price': 850,
        'status': 'hidden',
        'created_at': '2026-09-04T12:00:00.000Z',
        'updated_at': '2026-09-04T12:00:00.000Z',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.status, ProductStatus.hidden);
      expect(product.pricePaise, 85000);
      expect(product.priceDecimalString, '850.00');
    });

    test('preserves Unicode text without modification (Hindi, Punjabi)', () {
      final json = {
        'id': 'prod-006',
        'producer_id': 'user-123',
        'name': 'हाथ से बना मिट्टी का घड़ा',
        'description': 'ਸ਼ੁੱਧ ਮਿੱਟੀ ਦਾ ਕੰਮ (Pure clay work)',
        'category': 'ਦਸਤਕਾਰੀ (Handicrafts)',
        'unit': 'ਨਗ',
        'status': 'draft',
      };

      final product = ProducerProduct.fromJson(json);

      expect(product.name, 'हाथ से बना मिट्टी का घड़ा');
      expect(product.description, 'ਸ਼ੁੱਧ ਮਿੱਟੀ ਦਾ ਕੰਮ (Pure clay work)');
      expect(product.category, 'ਦਸਤਕਾਰੀ (Handicrafts)');
      expect(product.unit, 'ਨਗ');
    });

    test('unknown status does NOT silently become draft and throws FormatException', () {
      final json = {
        'id': 'prod-007',
        'producer_id': 'user-123',
        'name': 'Corrupted Status Item',
        'status': 'under_moderation',
      };

      expect(
        () => ProducerProduct.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing required id, producer_id, or name throws FormatException', () {
      expect(
        () => ProducerProduct.fromJson({
          'producer_id': 'u1',
          'name': 'No ID',
          'status': 'draft',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ProducerProduct.fromJson({
          'id': 'id1',
          'name': 'No Producer ID',
          'status': 'draft',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => ProducerProduct.fromJson({
          'id': 'id1',
          'producer_id': 'u1',
          'status': 'draft',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('toJson produces expected map matching database columns with exact decimal string', () {
      final product = ProducerProduct(
        id: 'prod-010',
        producerId: 'user-456',
        name: 'Brass Diya',
        description: 'Traditional handcrafted brass lamp',
        category: 'Metalwork',
        pricePaise: 35000,
        unit: 'piece',
        images: const ['img1.jpg'],
        status: ProductStatus.active,
        createdAt: sampleTimestamp,
        updatedAt: sampleTimestamp,
      );

      final json = product.toJson();

      expect(json['id'], 'prod-010');
      expect(json['producer_id'], 'user-456');
      expect(json['name'], 'Brass Diya');
      expect(json['description'], 'Traditional handcrafted brass lamp');
      expect(json['category'], 'Metalwork');
      expect(json['price'], '350.00');
      expect(json['unit'], 'piece');
      expect(json['images'], ['img1.jpg']);
      expect(json['status'], 'active');
      expect(json['created_at'], sampleTimestamp.toIso8601String());
      expect(json['updated_at'], sampleTimestamp.toIso8601String());
    });

    test('copyWith properly updates fields and supports setPriceNull: true', () {
      final original = ProducerProduct(
        id: 'prod-011',
        producerId: 'user-456',
        name: 'Original Name',
        pricePaise: 50000,
        status: ProductStatus.draft,
        createdAt: sampleTimestamp,
        updatedAt: sampleTimestamp,
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        status: ProductStatus.active,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.status, ProductStatus.active);
      expect(updated.pricePaise, 50000);
      expect(updated.priceDecimalString, '500.00');
      expect(updated.id, original.id);

      final withNullPrice = updated.copyWith(setPriceNull: true);
      expect(withNullPrice.pricePaise, isNull);
      expect(withNullPrice.priceDecimalString, isNull);
    });

    test('equality and hashCode evaluate properly based on values including pricePaise', () {
      final p1 = ProducerProduct(
        id: 'p1',
        producerId: 'u1',
        name: 'Item',
        pricePaise: 10000,
        images: const ['a.jpg'],
        createdAt: sampleTimestamp,
        updatedAt: sampleTimestamp,
      );

      final p2 = ProducerProduct(
        id: 'p1',
        producerId: 'u1',
        name: 'Item',
        pricePaise: 10000,
        images: const ['a.jpg'],
        createdAt: sampleTimestamp,
        updatedAt: sampleTimestamp,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
