import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/localization/generated/app_localizations.dart';
import '../../theme/buyer_colors.dart';
import '../../../core/mock_data/products.dart';
import '../../../core/routes/app_router.dart';
import '../widgets/product_card.dart';

class BuyerHomeTab extends StatefulWidget {
  const BuyerHomeTab({super.key});

  @override
  State<BuyerHomeTab> createState() => _BuyerHomeTabState();
}

class _BuyerHomeTabState extends State<BuyerHomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  String _searchQuery = '';
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isAssistantLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech error: ${error.errorMsg}'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: BuyerColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n?.filters ?? 'Filters', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n?.filterByCategory ?? 'Filter by Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(context, l10n?.textiles ?? 'Textiles'),
                _buildFilterChip(context, l10n?.spices ?? 'Spices'),
                _buildFilterChip(context, l10n?.handicrafts ?? 'Handicrafts'),
                _buildFilterChip(context, l10n?.food ?? 'Food'),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: BuyerColors.of(context).primary, foregroundColor: Colors.white),
              child: Text(l10n?.close ?? 'Close'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    final isSelected = _searchQuery.toLowerCase() == label.toLowerCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _searchQuery = selected ? label : '';
        });
        Navigator.pop(context);
      },
      selectedColor: BuyerColors.of(context).primary.withOpacity(0.2),
      checkmarkColor: BuyerColors.of(context).primary,
    );
  }

  Future<void> _handleVoiceAssistantTap() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mic support is not available right now.')),
      );
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      if (mounted) setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _sendTranscript(result.recognizedWords.trim());
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start the microphone. Please try again.')),
        );
      }
    }
  }

  Future<void> _sendTranscript(String transcript) async {
    if (transcript.trim().isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isListening = false;
      _isAssistantLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:8000/api/voice-assistant'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'transcript': transcript}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Assistant server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid assistant response.');
      }

      final answer = decoded['answer'] as String? ?? 'I could not understand that yet.';
      if (mounted) {
        _showAssistantSheet(answer);
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saathi is taking longer than expected. Please retry.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saathi could not answer right now. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssistantLoading = false;
        });
      }
    }
  }

  void _showAssistantSheet(String answer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
          decoration: BoxDecoration(
            color: BuyerColors.of(context).surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: BuyerColors.of(context).primary),
                    const SizedBox(width: 8),
                    Text(
                      'VyaparSetu Saathi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BuyerColors.of(context).textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BuyerColors.of(context).background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BuyerColors.of(context).border),
                  ),
                  child: Text(
                    answer,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BuyerColors.of(context).textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text('Close', style: TextStyle(color: BuyerColors.of(context).primary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filteredProducts = _searchQuery.isEmpty 
        ? mockProducts 
        : mockProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Stack(
      children: [
        CustomScrollView(
      slivers: [
        // Top App Bar
        SliverAppBar(
          backgroundColor: BuyerColors.of(context).surface,
          floating: true,
          pinned: false,
          elevation: 2,
          shadowColor: Colors.black12,
          toolbarHeight: 60,
          title: Row(
            children: [
              // Vyapar Setu Logo Mock
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: 'Vyapar', style: TextStyle(color: BuyerColors.of(context).primary)),
                    TextSpan(text: 'Setu', style: TextStyle(color: BuyerColors.of(context).orangeAccent)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications, color: BuyerColors.of(context).primary, size: 22),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.notificationsRoute);
              },
            ),
            IconButton(
              icon: Icon(Icons.account_circle, color: BuyerColors.of(context).primary, size: 26),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Container(
            color: BuyerColors.of(context).surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: BuyerColors.of(context).background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BuyerColors.of(context).borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: l10n?.searchHint ?? 'Search for Products, Brands and More',
                  hintStyle: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: BuyerColors.of(context).textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.tune, color: BuyerColors.of(context).primary, size: 20),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Hero Banner Carousel (Mocked as single image for now)
        SliverToBoxAdapter(
          child: Container(
            color: BuyerColors.of(context).surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildBannerImage('assets/images/vyapar_setu_banner.jpg', ''),
                ],
              ),
            ),
          ),
        ),

        // Circular Categories
        SliverToBoxAdapter(
          child: Container(
            color: BuyerColors.of(context).surface,
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.only(bottom: 8), // Gap below section
            child: SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildCircularCategory(context, l10n?.allCategories ?? 'All Categories', l10n?.forYou ?? 'For You', 'https://images.unsplash.com/photo-1556740758-90de374c12ad?w=200', true),
                  _buildCircularCategory(context, l10n?.handlooms ?? 'Handlooms', l10n?.textiles ?? 'Textiles', 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=200'),
                  _buildCircularCategory(context, l10n?.spices ?? 'Spices', l10n?.spices ?? 'Spices', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200'),
                  _buildCircularCategory(context, l10n?.handicrafts ?? 'Handicrafts', l10n?.handicrafts ?? 'Handicrafts', 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=200'),
                  _buildCircularCategory(context, l10n?.food ?? 'Food', l10n?.food ?? 'Food', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200'),
                  _buildCircularCategory(context, l10n?.gifting ?? 'Gifting', l10n?.forYou ?? 'For You', 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=200'),
                ],
              ),
            ),
          ),
        ),

        // Deals Header
        SliverToBoxAdapter(
          child: Container(
            color: BuyerColors.of(context).surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.recommendedForYou ?? 'Recommended For You', 
                    style: GoogleFonts.inter(
                      fontSize: 16, 
                      fontWeight: FontWeight.w700, 
                      color: BuyerColors.of(context).textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/marketplace');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: BuyerColors.of(context).primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n?.viewAll ?? 'VIEW ALL',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Product Grid (Flipkart style: 2 columns, white cards on gray background)
        SliverPadding(
          padding: const EdgeInsets.all(8.0),
          sliver: filteredProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(l10n?.noProductsFound ?? 'No products found.')),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.65, // Adjusted for standard card
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ProductCard(
                        product: filteredProducts[index],
                        width: double.infinity,
                      );
                    },
                    childCount: filteredProducts.length,
                  ),
                ),
        ),

        // FAQ & Artisan Helper Section appended cleanly above the existing grid tail.
        SliverToBoxAdapter(
          child: Container(
            color: BuyerColors.of(context).surface,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VyaparSetu Saathi • Artisan FAQ',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BuyerColors.of(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: BuyerColors.of(context).cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BuyerColors.of(context).border),
                  ),
                  child: Column(
                    children: [
                      _buildFaqTile(
                        question: 'Do I need a GST number to sell on VyaparSetu?',
                        answer: 'No. Small artisans with annual turnover under ₹40 Lakhs selling intra-state are legally exempt under government e-commerce rules. You only need an Enrolment ID.',
                      ),
                      Divider(height: 1, color: BuyerColors.of(context).border),
                      _buildFaqTile(
                        question: 'What benefits can I get from the PM Vishwakarma Scheme?',
                        answer: 'Eligible traditional artisans receive a ₹15,000 modern toolkit grant, ₹500/day training stipend, and collateral-free credit support up to ₹3 Lakh at 5% interest.',
                      ),
                      Divider(height: 1, color: BuyerColors.of(context).border),
                      _buildFaqTile(
                        question: 'How does the AI suggested price work?',
                        answer: 'We track raw material inflation using Government WPI indices, factor in your labor time for a break-even safety floor, and use machine learning to suggest the most profitable market ceiling.',
                      ),
                      Divider(height: 1, color: BuyerColors.of(context).border),
                      _buildFaqTile(
                        question: 'Can I add products if I cannot write English?',
                        answer: 'Yes! Tap the mic button when adding a product and speak in Punjabi or Hindi. Our auto-cataloger writes the SEO title and description for you automatically.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    ),
    Positioned(
      right: 16,
      bottom: 80,
      child: FloatingActionButton.extended(
        onPressed: _handleVoiceAssistantTap,
        icon: _isAssistantLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_isListening ? Icons.mic_off : Icons.mic),
        label: Text(
          _isListening ? 'Listening...' : 'Ask Saathi / ਸਵਾਲ ਪੁੱਛੋ',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        backgroundColor: BuyerColors.of(context).primary,
        foregroundColor: Colors.white,
        heroTag: 'vyapar_saathi_fab',
      ),
    ),
  ],
);
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        question,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: BuyerColors.of(context).textPrimary,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: BuyerColors.of(context).textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerImage(String path, String title) {
    final bool isNetwork = path.startsWith('http');
    return Container(
      width: MediaQuery.of(context).size.width - 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: isNetwork ? CachedNetworkImageProvider(path) as ImageProvider : AssetImage(path),
          fit: BoxFit.cover,
        ),
      ),
      child: title.isNotEmpty ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ) : const SizedBox(),
    );
  }

  Widget _buildCircularCategory(BuildContext context, String title, String filterCategory, String imageUrl, [bool isFirst = false]) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/marketplace', arguments: filterCategory);
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BuyerColors.of(context).borderLight, width: 2),
                color: BuyerColors.of(context).background,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                color: BuyerColors.of(context).textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
