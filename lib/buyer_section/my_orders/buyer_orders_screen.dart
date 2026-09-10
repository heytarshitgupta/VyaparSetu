import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/buyer_colors.dart';

// Mock order model for demonstration
class MockOrder {
  final String id;
  final String productName;
  final String producerName;
  final String date;
  final String status;
  final double amount;

  MockOrder({
    required this.id,
    required this.productName,
    required this.producerName,
    required this.date,
    required this.status,
    required this.amount,
  });
}

final List<MockOrder> mockOrders = [
  MockOrder(
    id: 'ORD-2026-001',
    productName: 'Handwoven Bamboo Basket',
    producerName: 'Ravi Kumar',
    date: '10 Aug 2026',
    status: 'Delivered',
    amount: 450,
  ),
  MockOrder(
    id: 'ORD-2026-002',
    productName: 'Organic Honey (500g)',
    producerName: 'Sita Devi',
    date: '02 Sep 2026',
    status: 'In Progress',
    amount: 320,
  ),
  MockOrder(
    id: 'ORD-2026-003',
    productName: 'Terracotta Pots Set',
    producerName: 'Ravi Kumar',
    date: '05 Sep 2026',
    status: 'Pending',
    amount: 850,
  ),
];

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Delivered': return BuyerColors.of(context).badgeGreen;
      case 'In Progress': return BuyerColors.of(context).orangeAccent;
      case 'Pending': return BuyerColors.of(context).primaryLight;
      case 'Cancelled': return BuyerColors.of(context).badgePinkText;
      default: return BuyerColors.of(context).textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        backgroundColor: BuyerColors.of(context).surface,
        elevation: 1,
        shadowColor: Colors.black12,
        title: Text(
          'My Orders', 
          style: GoogleFonts.inter(
            color: BuyerColors.of(context).textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: BuyerColors.of(context).textPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = mockOrders[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/order_details', arguments: order);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BuyerColors.of(context).surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BuyerColors.of(context).borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.id, 
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BuyerColors.of(context).primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(context, order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: _getStatusColor(context, order.status),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.productName, 
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BuyerColors.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seller: ${order.producerName}', 
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: BuyerColors.of(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: BuyerColors.of(context).borderLight, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.date, 
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: BuyerColors.of(context).textSecondary,
                        ),
                      ),
                      Text(
                        '₹${order.amount.toStringAsFixed(0)}', 
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: BuyerColors.of(context).textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
