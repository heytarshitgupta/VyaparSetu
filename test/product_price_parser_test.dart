import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/models/product_price_parser.dart';

void main() {
  group('ProductPriceParser - Strict UI Rupee Text Parsing', () {
    test('parses exact required examples to integer paise without floating point error', () {
      expect(ProductPriceParser.parseRupeesTextStrict('1250'), 125000);
      expect(ProductPriceParser.parseRupeesTextStrict('1250.5'), 125050);
      expect(ProductPriceParser.parseRupeesTextStrict('1250.50'), 125050);
      expect(ProductPriceParser.parseRupeesTextStrict('10.05'), 1005);
      expect(ProductPriceParser.parseRupeesTextStrict('0.01'), 1);
    });

    test('rejects empty or whitespace input', () {
      expect(
        () => ProductPriceParser.parseRupeesTextStrict(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects zero and 0.00', () {
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('0'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('0.00'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('0.0'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects negative numbers and plus signs', () {
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('-10'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('-0.01'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('+10'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects more than 2 decimal places', () {
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('12.345'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('10.001'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-numeric alphabetic characters and multiple decimals', () {
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('abc'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('12a.50'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('10.50.25'),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles boundary of NUMERIC(12,2) exactly: ₹9,999,999,999.99 = 999999999999 paise', () {
      expect(
        ProductPriceParser.parseRupeesTextStrict('9999999999.99'),
        999999999999,
      );
    });

    test('rejects values exceeding NUMERIC(12,2) maximum boundary', () {
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('10000000000.00'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextStrict('9999999999999'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ProductPriceParser - Optional UI Rupee Text Parsing', () {
    test('returns null for null, empty, or whitespace strings', () {
      expect(ProductPriceParser.parseRupeesTextOptional(null), isNull);
      expect(ProductPriceParser.parseRupeesTextOptional(''), isNull);
      expect(ProductPriceParser.parseRupeesTextOptional('   \t  '), isNull);
    });

    test('parses valid numeric strings identically to strict parser', () {
      expect(ProductPriceParser.parseRupeesTextOptional('1250.50'), 125050);
      expect(ProductPriceParser.parseRupeesTextOptional('100'), 10000);
    });

    test('throws FormatException on malformed optional strings when present', () {
      expect(
        () => ProductPriceParser.parseRupeesTextOptional('invalid'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ProductPriceParser.parseRupeesTextOptional('-50'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ProductPriceParser - DB Value & Decimal String Serialization', () {
    test('converts integer paise to exact 2-decimal string', () {
      expect(ProductPriceParser.paiseToDecimalString(null), isNull);
      expect(ProductPriceParser.paiseToDecimalString(1), '0.01');
      expect(ProductPriceParser.paiseToDecimalString(10), '0.10');
      expect(ProductPriceParser.paiseToDecimalString(100), '1.00');
      expect(ProductPriceParser.paiseToDecimalString(1050), '10.50');
      expect(ProductPriceParser.paiseToDecimalString(125050), '1250.50');
      expect(ProductPriceParser.paiseToDecimalString(999999999999), '9999999999.99');
    });

    test('parses database string and num values accurately', () {
      expect(ProductPriceParser.parseDbValueToPaise('1250.50'), 125050);
      expect(ProductPriceParser.parseDbValueToPaise(1250.50), 125050);
      expect(ProductPriceParser.parseDbValueToPaise('0.01'), 1);
      expect(ProductPriceParser.parseDbValueToPaise(null), isNull);
    });
  });
}
