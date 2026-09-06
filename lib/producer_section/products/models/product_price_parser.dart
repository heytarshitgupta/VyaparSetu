/// Centralized, exact monetary conversion helper for VyaparSetu.
///
/// Ensures exact integer paise handling across domain models, UI inputs,
/// and database NUMERIC(12, 2) strings. ZERO floating-point (double) math.
class ProductPriceParser {
  /// Maximum value allowed by Migration 009 NUMERIC(12, 2):
  /// ₹9,999,999,999.99 = 999,999,999,999 paise.
  static const int maxPaise = 999999999999;

  /// Parses UI-style rupee text strictly as a positive numeric price.
  ///
  /// Required examples:
  /// - "1250"    -> 125000 paise
  /// - "1250.5"  -> 125050 paise
  /// - "1250.50" -> 125050 paise
  /// - "10.05"   -> 1005 paise
  /// - "0.01"    -> 1 paise
  ///
  /// Rejects:
  /// - Empty or whitespace string
  /// - Zero ("0", "0.00")
  /// - Negative values
  /// - Values exceeding [maxPaise] (₹9,999,999,999.99)
  /// - More than 2 decimal places
  /// - Non-numeric / alphabetic input
  /// - Multiple decimal points
  ///
  /// Throws [FormatException] on invalid input.
  static int parseRupeesTextStrict(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Price cannot be empty');
    }

    final parts = trimmed.split('.');
    if (parts.length > 2) {
      throw FormatException('Malformed price with multiple decimal points: "$input"');
    }

    final wholeStr = parts[0].trim();
    if (wholeStr.startsWith('-') || wholeStr.startsWith('+')) {
      if (wholeStr.startsWith('-')) {
        throw FormatException('Price cannot be negative: "$input"');
      }
      throw FormatException('Price cannot include plus sign: "$input"');
    }

    // Check whole digits
    if (wholeStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(wholeStr)) {
      throw FormatException('Price contains invalid characters: "$input"');
    }

    final whole = wholeStr.isEmpty ? 0 : int.parse(wholeStr);

    int fraction = 0;
    if (parts.length == 2) {
      final fracStr = parts[1].trim();
      if (fracStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fracStr)) {
        throw FormatException('Price fraction contains invalid characters: "$input"');
      }

      if (fracStr.isEmpty) {
        fraction = 0;
      } else if (fracStr.length == 1) {
        fraction = int.parse(fracStr) * 10;
      } else if (fracStr.length == 2) {
        fraction = int.parse(fracStr);
      } else {
        throw FormatException('Price exceeds 2 decimal places: "$input"');
      }
    }

    final totalPaise = (whole * 100) + fraction;

    if (totalPaise <= 0) {
      throw FormatException('Price must be greater than zero: "$input"');
    }

    if (totalPaise > maxPaise) {
      throw FormatException(
        'Price exceeds maximum allowed value of ₹9,999,999,999.99 (paise: $totalPaise > $maxPaise)',
      );
    }

    return totalPaise;
  }

  /// Parses optional UI-style rupee text.
  ///
  /// Returns `null` if [input] is null or contains only whitespace.
  /// Otherwise parses strictly via [parseRupeesTextStrict].
  static int? parseRupeesTextOptional(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }
    return parseRupeesTextStrict(input);
  }

  /// Parses PostgreSQL NUMERIC(12, 2) database values (String or num) into integer paise.
  ///
  /// Used when deserializing records from Supabase / PostgREST.
  /// Returns `null` if [value] is null or empty string.
  /// Throws [FormatException] if malformed or exceeding [maxPaise].
  static int? parseDbValueToPaise(dynamic value) {
    if (value == null) return null;

    final String text;
    if (value is num) {
      if (value.isNaN || value.isInfinite) {
        throw FormatException('Invalid numeric price value: $value');
      }
      text = value.toStringAsFixed(2);
    } else if (value is String) {
      text = value.trim();
      if (text.isEmpty) return null;
    } else {
      throw FormatException('Cannot parse price from type: ${value.runtimeType}');
    }

    final parts = text.split('.');
    if (parts.length > 2) {
      throw FormatException('Malformed monetary string with multiple decimal points: "$text"');
    }

    final wholeStr = parts[0].trim();
    if (wholeStr.isEmpty && parts.length == 1) {
      throw FormatException('Empty whole price: "$text"');
    }

    bool isNegative = false;
    String cleanWhole = wholeStr;
    if (cleanWhole.startsWith('-')) {
      isNegative = true;
      cleanWhole = cleanWhole.substring(1);
    } else if (cleanWhole.startsWith('+')) {
      cleanWhole = cleanWhole.substring(1);
    }

    final whole = cleanWhole.isEmpty ? 0 : int.tryParse(cleanWhole);
    if (whole == null) {
      throw FormatException('Malformed whole portion in price: "$text"');
    }

    int fraction = 0;
    if (parts.length == 2) {
      final fracStr = parts[1].trim();
      if (fracStr.isEmpty) {
        fraction = 0;
      } else if (fracStr.length == 1) {
        final d = int.tryParse(fracStr);
        if (d == null) throw FormatException('Malformed fraction in price: "$text"');
        fraction = d * 10;
      } else if (fracStr.length == 2) {
        final d = int.tryParse(fracStr);
        if (d == null) throw FormatException('Malformed fraction in price: "$text"');
        fraction = d;
      } else {
        final d = int.tryParse(fracStr.substring(0, 2));
        final remainder = fracStr.substring(2);
        final remInt = int.tryParse(remainder);
        if (d == null || remInt == null || remInt != 0) {
          throw FormatException('Price exceeds 2-decimal precision (NUMERIC(12,2)): "$text"');
        }
        fraction = d;
      }
    }

    final totalPaise = (whole * 100) + fraction;
    if (totalPaise > maxPaise) {
      throw FormatException('Price exceeds maximum NUMERIC(12,2) value: "$text"');
    }

    return isNegative ? -totalPaise : totalPaise;
  }

  /// Converts integer paise back to an exact two-decimal string for PostgreSQL NUMERIC(12, 2).
  ///
  /// Examples:
  /// - null -> null
  /// - 1 -> "0.01"
  /// - 100 -> "1.00"
  /// - 1050 -> "10.50"
  /// - 125050 -> "1250.50"
  static String? paiseToDecimalString(int? paise) {
    if (paise == null) return null;
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final whole = absPaise ~/ 100;
    final fraction = absPaise % 100;
    final formatted = '$whole.${fraction.toString().padLeft(2, '0')}';
    return isNegative ? '-$formatted' : formatted;
  }
}
