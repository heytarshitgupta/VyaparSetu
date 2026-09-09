import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../producer_onboarding_provider.dart';

class AboutYourBusinessStep extends StatefulWidget {
  final ProducerOnboardingProvider provider;

  const AboutYourBusinessStep({
    super.key,
    required this.provider,
  });

  @override
  State<AboutYourBusinessStep> createState() => _AboutYourBusinessStepState();
}

class _AboutYourBusinessStepState extends State<AboutYourBusinessStep> {
  late final TextEditingController _capacityQuantityController;

  @override
  void initState() {
    super.initState();
    _capacityQuantityController = TextEditingController(
      text: widget.provider.productionCapacityQuantity,
    );

    _capacityQuantityController.addListener(() {
      if (widget.provider.productionCapacityQuantity != _capacityQuantityController.text) {
        widget.provider.setProductionCapacityQuantity(_capacityQuantityController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AboutYourBusinessStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.productionCapacityQuantity != _capacityQuantityController.text) {
      _capacityQuantityController.text = widget.provider.productionCapacityQuantity;
    }
  }

  @override
  void dispose() {
    _capacityQuantityController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getTeamSizes(AppLocalizations? l10n) {
    return [
      {
        'key': 'solo',
        'label': l10n?.teamSizeSolo ?? 'Just me',
        'icon': Icons.person_outline,
      },
      {
        'key': '2_5',
        'label': l10n?.teamSize2_5 ?? '2–5 people',
        'icon': Icons.people_outline,
      },
      {
        'key': '6_10',
        'label': l10n?.teamSize6_10 ?? '6–10 people',
        'icon': Icons.groups_outlined,
      },
      {
        'key': '11_25',
        'label': l10n?.teamSize11_25 ?? '11–25 people',
        'icon': Icons.business_outlined,
      },
      {
        'key': '25_plus',
        'label': l10n?.teamSize25Plus ?? '25+ people',
        'icon': Icons.corporate_fare_outlined,
      },
    ];
  }

  List<Map<String, String>> _getMonthlySales(AppLocalizations? l10n) {
    return [
      {
        'key': 'below_10k',
        'label': l10n?.monthlySalesBelow10k ?? 'Less than ₹10,000',
      },
      {
        'key': '10k_50k',
        'label': l10n?.monthlySales10k50k ?? '₹10,000–₹50,000',
      },
      {
        'key': '50k_1l',
        'label': l10n?.monthlySales50k1l ?? '₹50,000–₹1 lakh',
      },
      {
        'key': '1l_5l',
        'label': l10n?.monthlySales1l5l ?? '₹1–₹5 lakh',
      },
      {
        'key': 'above_5l',
        'label': l10n?.monthlySalesAbove5l ?? 'Above ₹5 lakh',
      },
      {
        'key': 'prefer_not_to_say',
        'label': l10n?.monthlySalesPreferNotToSay ?? 'Prefer not to say',
      },
    ];
  }

  List<Map<String, String>> _getCapacityUnits(AppLocalizations? l10n) {
    return [
      {'key': 'pieces', 'label': l10n?.unitPieces ?? 'Pieces'},
      {'key': 'kg', 'label': l10n?.unitKg ?? 'Kg'},
      {'key': 'litres', 'label': l10n?.unitLitres ?? 'Litres'},
      {'key': 'packs', 'label': l10n?.unitPacks ?? 'Packs'},
      {'key': 'boxes', 'label': l10n?.unitBoxes ?? 'Boxes'},
      {'key': 'other', 'label': l10n?.unitOther ?? 'Other'},
    ];
  }

  List<Map<String, String>> _getCapacityPeriods(AppLocalizations? l10n) {
    return [
      {'key': 'week', 'label': l10n?.periodWeek ?? 'Per Week'},
      {'key': 'month', 'label': l10n?.periodMonth ?? 'Per Month'},
      {'key': 'year', 'label': l10n?.periodYear ?? 'Per Year'},
    ];
  }

  List<Map<String, dynamic>> _getSellingChannels(AppLocalizations? l10n) {
    return [
      {
        'key': 'local_customers',
        'label': l10n?.channelLocalCustomers ?? 'Local customers',
        'icon': Icons.storefront_outlined,
      },
      {
        'key': 'local_shops',
        'label': l10n?.channelLocalShops ?? 'Local shops',
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'key': 'whatsapp',
        'label': l10n?.channelWhatsapp ?? 'WhatsApp',
        'icon': Icons.chat_outlined,
      },
      {
        'key': 'social_media',
        'label': l10n?.channelSocialMedia ?? 'Instagram / Facebook',
        'icon': Icons.photo_camera_outlined,
      },
      {
        'key': 'online_marketplaces',
        'label': l10n?.channelOnlineMarketplaces ?? 'Online marketplaces',
        'icon': Icons.shopping_cart_outlined,
      },
      {
        'key': 'exhibitions_fairs',
        'label': l10n?.channelExhibitionsFairs ?? 'Exhibitions / Fairs',
        'icon': Icons.festival_outlined,
      },
      {
        'key': 'not_selling_yet',
        'label': l10n?.channelNotSellingYet ?? 'Haven’t started selling yet',
        'icon': Icons.hourglass_empty_outlined,
      },
    ];
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final teamSizes = _getTeamSizes(l10n);
    final monthlySales = _getMonthlySales(l10n);
    final capacityUnits = _getCapacityUnits(l10n);
    final capacityPeriods = _getCapacityPeriods(l10n);
    final sellingChannels = _getSellingChannels(l10n);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------------------
          // STEP HEADER (Compact)
          // --------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.aboutYourBusinessTitle ?? 'About Your Business',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  l10n?.optionalBadge ?? 'Optional',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.aboutYourBusinessSubtitle ??
                'Help us understand your business better. You can skip this step.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Error banner if any
          if (widget.provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.provider.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // --------------------------------------------------------------------
          // 1. TEAM / BUSINESS SIZE
          // --------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context: context,
                  title: l10n?.teamSizeTitle ?? 'Team / Business Size',
                  subtitle: 'How many people work in your business?',
                  icon: Icons.groups_outlined,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: teamSizes.map((item) {
                    final isSelected = widget.provider.teamSize == item['key'];
                    return ChoiceChip(
                      key: ValueKey('team_size_chip_${item['key']}'),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 14,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(item['label'] as String),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        widget.provider.setTeamSize(selected ? (item['key'] as String) : null);
                      },
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --------------------------------------------------------------------
          // 2. TYPICAL MONTHLY SALES
          // --------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context: context,
                  title: l10n?.monthlySalesTitle ?? 'Typical Monthly Sales',
                  subtitle: 'Approximate average sales per month',
                  icon: Icons.payments_outlined,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: monthlySales.map((item) {
                    final isSelected = widget.provider.typicalMonthlySales == item['key'];
                    return ChoiceChip(
                      key: ValueKey('monthly_sales_chip_${item['key']}'),
                      label: Text(item['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        widget.provider.setTypicalMonthlySales(selected ? item['key'] : null);
                      },
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --------------------------------------------------------------------
          // 3. PRODUCTION CAPACITY
          // --------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context: context,
                  title: l10n?.productionCapacityTitle ?? 'How much can you usually produce?',
                  subtitle: null,
                  icon: Icons.precision_manufacturing_outlined,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 450;
                    if (isNarrow) {
                      return Column(
                        children: [
                          TextFormField(
                            key: const Key('capacity_quantity_field'),
                            controller: _capacityQuantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n?.quantityLabel ?? 'Quantity',
                              hintText: l10n?.quantityHint ?? 'e.g. 50',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: const Key('capacity_unit_dropdown'),
                                  initialValue: widget.provider.productionCapacityUnit,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: l10n?.unitLabel ?? 'Unit',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: capacityUnits.map((u) {
                                    return DropdownMenuItem<String>(
                                      value: u['key'],
                                      child: Text(u['label']!, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    widget.provider.setProductionCapacityUnit(val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: const Key('capacity_period_dropdown'),
                                  initialValue: widget.provider.productionCapacityPeriod,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: l10n?.periodLabel ?? 'Period',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: capacityPeriods.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p['key'],
                                      child: Text(p['label']!, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    widget.provider.setProductionCapacityPeriod(val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            key: const Key('capacity_quantity_field'),
                            controller: _capacityQuantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n?.quantityLabel ?? 'Quantity',
                              hintText: l10n?.quantityHint ?? 'e.g. 50',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            key: const Key('capacity_unit_dropdown'),
                            initialValue: widget.provider.productionCapacityUnit,
                            isDense: true,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n?.unitLabel ?? 'Unit',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: capacityUnits.map((u) {
                              return DropdownMenuItem<String>(
                                value: u['key'],
                                child: Text(u['label']!, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              widget.provider.setProductionCapacityUnit(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            key: const Key('capacity_period_dropdown'),
                            initialValue: widget.provider.productionCapacityPeriod,
                            isDense: true,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n?.periodLabel ?? 'Period',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: capacityPeriods.map((p) {
                              return DropdownMenuItem<String>(
                                value: p['key'],
                                child: Text(p['label']!, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              widget.provider.setProductionCapacityPeriod(val);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --------------------------------------------------------------------
          // 4. WHERE DO YOU CURRENTLY SELL?
          // --------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context: context,
                  title: l10n?.sellingChannelsTitle ?? 'Where do you currently sell?',
                  subtitle: 'Select all that apply',
                  icon: Icons.store_outlined,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sellingChannels.map((item) {
                    final isSelected = widget.provider.sellingChannels.contains(item['key']);
                    return FilterChip(
                      key: ValueKey('selling_channel_chip_${item['key']}'),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 14,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(item['label'] as String),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        widget.provider.toggleSellingChannel(item['key'] as String);
                      },
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
