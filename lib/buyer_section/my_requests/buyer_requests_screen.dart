import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/buyer_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/mock_data/responses.dart';

class BuyerRequestsScreen extends StatelessWidget {
  const BuyerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Mock list of requests
    final List<Map<String, dynamic>> mockRequests = [
      {
        'id': 'REQ-1001',
        'title': 'Premium Handwoven Silk Sarees',
        'status': 'Receiving Quotes',
        'date': 'Oct 24, 2026',
        'responses': 3,
      },
      {
        'id': 'REQ-1002',
        'title': 'Organic Turmeric Powder (500kg)',
        'status': 'Closed',
        'date': 'Oct 15, 2026',
        'responses': 5,
      },
    ];

    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        title: Text(
          l10n?.myRequirements ?? 'My Requirements', 
          style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: BuyerColors.of(context).surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: BuyerColors.of(context).textPrimary),
      ),
      body: SafeArea(
        child: mockRequests.isEmpty
          ? EmptyStateWidget(
              title: l10n?.noRequests ?? 'No requests yet',
              subtitle: l10n?.noRequestsSub ?? 'Post a custom requirement to start receiving quotes from verified producers.',
              icon: Icons.assignment_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mockRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = mockRequests[index];
                final bool isActive = req['status'] == 'Receiving Quotes';
                
                return GestureDetector(
                  onTap: isActive ? () {
                    Navigator.pushNamed(
                      context, 
                      AppRouter.comparisonRoute,
                      arguments: mockResponses,
                    );
                  } : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: BuyerColors.of(context).surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BuyerColors.of(context).borderLight),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req['id'], 
                              style: GoogleFonts.inter(
                                fontSize: 12, 
                                fontWeight: FontWeight.w700, 
                                color: BuyerColors.of(context).primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? BuyerColors.of(context).badgeGreen.withOpacity(0.1) : BuyerColors.of(context).borderLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                req['status'].toString().replaceAll('Receiving Quotes', l10n?.receivingQuotes ?? 'Receiving Quotes').replaceAll('Closed', l10n?.closed ?? 'Closed').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isActive ? BuyerColors.of(context).badgeGreen : BuyerColors.of(context).textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          req['title'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BuyerColors.of(context).textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: BuyerColors.of(context).borderLight, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: BuyerColors.of(context).textSecondary),
                                const SizedBox(width: 6),
                                Text(req['date'], style: GoogleFonts.inter(fontSize: 12, color: BuyerColors.of(context).textSecondary)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.forum_outlined, size: 14, color: BuyerColors.of(context).primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${req['responses']} Responses', 
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: BuyerColors.of(context).primary, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
