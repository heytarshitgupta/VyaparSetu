import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/models/producer_product.dart';
import 'package:buyer_section/producer_section/products/models/producer_product_draft.dart';

void main() {
  group('ProducerProductDraft Domain Model', () {
    test('instantiates with exact Migration 009 schema defaults', () {
      const draft = ProducerProductDraft();

      expect(draft.name, '');
      expect(draft.category, '');
      expect(draft.description, '');
      expect(draft.pricePaise, isNull);
      expect(draft.unit, 'piece');
      expect(draft.images, isEmpty);
      expect(draft.hasValidDraftName, isFalse);
      expect(draft.canMarkActive, isFalse);
    });

    test('preserves Unicode text without modification across all fields', () {
      const draft = ProducerProductDraft(
        name: 'हाथ से बुनी पशमीना शॉल',
        category: 'हस्तशिल्प वस्त्र',
        description: 'ਪੰਜਾਬੀ ਫੁਲਕਾਰੀ ਕਢਾਈ - ਹੱਥ ਨਾਲ ਬਣੀ',
        pricePaise: 450000,
        unit: 'ਨਗ',
      );

      expect(draft.name, 'हाथ से बुनी पशमीना शॉल');
      expect(draft.category, 'हस्तशिल्प वस्त्र');
      expect(draft.description, 'ਪੰਜਾਬੀ ਫੁਲਕਾਰੀ ਕਢਾਈ - ਹੱਥ ਨਾਲ ਬਣੀ');
      expect(draft.unit, 'ਨਗ');
      expect(draft.pricePaise, 450000);
      expect(draft.hasValidDraftName, isTrue);
      expect(draft.canMarkActive, isTrue);
    });

    test('validates hasValidDraftName accurately', () {
      expect(const ProducerProductDraft(name: '').hasValidDraftName, isFalse);
      expect(const ProducerProductDraft(name: '   ').hasValidDraftName, isFalse);
      expect(const ProducerProductDraft(name: 'A').hasValidDraftName, isTrue);
      expect(const ProducerProductDraft(name: 'Clay Pot').hasValidDraftName, isTrue);
    });

    test('validates canMarkActive according to Migration 009 constraints', () {
      // Missing name length (<2)
      expect(
        const ProducerProductDraft(
          name: 'A',
          category: 'Pottery',
          pricePaise: 50000,
        ).canMarkActive,
        isFalse,
      );

      // Missing category length (<2)
      expect(
        const ProducerProductDraft(
          name: 'Clay Pot',
          category: 'P',
          pricePaise: 50000,
        ).canMarkActive,
        isFalse,
      );

      // Null price
      expect(
        const ProducerProductDraft(
          name: 'Clay Pot',
          category: 'Pottery',
          pricePaise: null,
        ).canMarkActive,
        isFalse,
      );

      // Zero or negative price
      expect(
        const ProducerProductDraft(
          name: 'Clay Pot',
          category: 'Pottery',
          pricePaise: 0,
        ).canMarkActive,
        isFalse,
      );

      // Valid active criteria met (Photo is NOT required for active status)
      expect(
        const ProducerProductDraft(
          name: 'Clay Pot',
          category: 'Pottery',
          pricePaise: 50000,
          images: [],
        ).canMarkActive,
        isTrue,
      );
    });

    test('fromProduct initializes draft from an existing ProducerProduct', () {
      final now = DateTime.now();
      final product = ProducerProduct(
        id: 'prod-123',
        producerId: 'user-456',
        name: 'Brass Lamp',
        category: 'Metalcraft',
        description: 'Traditional Diya',
        pricePaise: 75000,
        unit: 'set',
        images: const ['user-456/prod-123/lamp.jpg'],
        status: ProductStatus.draft,
        createdAt: now,
        updatedAt: now,
      );

      final draft = ProducerProductDraft.fromProduct(product);

      expect(draft.name, 'Brass Lamp');
      expect(draft.category, 'Metalcraft');
      expect(draft.description, 'Traditional Diya');
      expect(draft.pricePaise, 75000);
      expect(draft.unit, 'set');
      expect(draft.images, ['user-456/prod-123/lamp.jpg']);
    });

    test('copyWith updates fields correctly and allows clearing price with setPriceNull', () {
      const draft = ProducerProductDraft(
        name: 'Vase',
        pricePaise: 25000,
      );

      final updated = draft.copyWith(name: 'Ceramic Vase');
      expect(updated.name, 'Ceramic Vase');
      expect(updated.pricePaise, 25000);

      final clearedPrice = updated.copyWith(setPriceNull: true);
      expect(clearedPrice.pricePaise, isNull);
    });

    test('equality and hashCode evaluate properly based on fields', () {
      const draft1 = ProducerProductDraft(name: 'Item', pricePaise: 1000);
      const draft2 = ProducerProductDraft(name: 'Item', pricePaise: 1000);
      const draft3 = ProducerProductDraft(name: 'Item 2', pricePaise: 1000);

      expect(draft1, equals(draft2));
      expect(draft1.hashCode, equals(draft2.hashCode));
      expect(draft1, isNot(equals(draft3)));
    });
  });
}
