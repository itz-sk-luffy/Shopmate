import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/custom_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Controllers
  final _storeNameController = TextEditingController(text: 'My General Store');
  String _selectedCurrency = '₹';
  String _selectedLanguage = 'en';

  // Step 2 Controllers
  String _selectedTaxType = 'exclusive';
  String _defaultTaxRate = '0';
  final _billPrefixController = TextEditingController(text: 'INV-');
  final _billStartNumController = TextEditingController(text: '1001');

  // Step 3 Controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(text: 'Main Market');
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _gstinController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _storeNameController.dispose();
    _billPrefixController.dispose();
    _billStartNumController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final settingsMap = {
      'store_name': _storeNameController.text.trim().isEmpty ? 'My General Store' : _storeNameController.text.trim(),
      'currency_symbol': _selectedCurrency,
      'language': _selectedLanguage,
      'tax_type': _selectedTaxType,
      'tax_rate_default': _defaultTaxRate,
      'bill_prefix': _billPrefixController.text.trim().isEmpty ? 'INV-' : _billPrefixController.text.trim(),
      'bill_next_number': _billStartNumController.text.trim().isEmpty ? '1001' : _billStartNumController.text.trim(),
      'store_phone': _phoneController.text.trim(),
      'store_address': _addressController.text.trim(),
      'store_state': _stateController.text.trim(),
      'store_gstin': _gstinController.text.trim(),
      'has_completed_onboarding': 'true',
    };

    await ref.read(settingsProvider.notifier).updateSettings(settingsMap);
    if (mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopmate Setup'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Store'),
                  _buildStepConnector(0),
                  _buildStepIndicator(1, 'Billing'),
                  _buildStepConnector(1),
                  _buildStepIndicator(2, 'Contact'),
                ],
              ),
            ),
            const Divider(),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  _buildStep1Store(isDark),
                  _buildStep2Tax(isDark),
                  _buildStep3Contact(isDark),
                ],
              ),
            ),

            // Bottom Continue Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                ),
              ),
              child: FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_currentStep == 2 ? 'Get Started (Ready to Bill)' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final theme = Theme.of(context);
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    Color bg;
    Color fg;
    if (isDone || isCurrent) {
      bg = theme.colorScheme.primary;
      fg = Colors.white;
    } else {
      bg = theme.colorScheme.outline.withValues(alpha: 0.3);
      fg = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTypography.captionBold.copyWith(
            fontSize: 10,
            color: isCurrent ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  // Step 1: Store profile basics
  Widget _buildStep1Store(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/icons/app_icon.png', width: 80, height: 80, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('Welcome to Shopmate!', style: AppTypography.title)),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Fast, offline-first billing built specifically for general stores.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store Name', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sharma Kirana Store',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 18),
              Text('Currency Symbol', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['₹', '\$', '€', '£', 'AED'].map((curr) {
                  final isSelected = _selectedCurrency == curr;
                  return ChoiceChip(
                    label: Text(curr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCurrency = curr);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('Language', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  {'code': 'en', 'name': 'English'},
                  {'code': 'hi', 'name': 'हिन्दी (Hindi)'},
                  {'code': 'mr', 'name': 'मराठी (Marathi)'},
                ].map((lang) {
                  final isSelected = _selectedLanguage == lang['code'];
                  return ChoiceChip(
                    label: Text(lang['name']!),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedLanguage = lang['code']!);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Tax & Bill numbering
  Widget _buildStep2Tax(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Tax & Bill Settings', style: AppTypography.title),
        const SizedBox(height: 6),
        Text(
          'Configure tax calculation and starting invoice numbering.',
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tax Calculation Type', style: AppTypography.section),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'exclusive', label: Text('Tax Exclusive (Add to price)')),
                  ButtonSegment(value: 'inclusive', label: Text('Tax Inclusive (In price)')),
                ],
                selected: {_selectedTaxType},
                onSelectionChanged: (set) => setState(() => _selectedTaxType = set.first),
              ),
              const SizedBox(height: 18),
              const Text('Default GST Rate', style: AppTypography.section),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['0', '5', '12', '18', '28'].map((rate) {
                  final isSelected = _defaultTaxRate == rate;
                  return ChoiceChip(
                    label: Text('$rate%'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _defaultTaxRate = rate);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bill Prefix', style: AppTypography.section),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _billPrefixController,
                          decoration: const InputDecoration(hintText: 'INV-'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Bill No.', style: AppTypography.section),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _billStartNumController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1001'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Contact & Store Details
  Widget _buildStep3Contact(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Contact & Receipts', style: AppTypography.title),
        const SizedBox(height: 6),
        Text(
          'These details will appear on printed 58 mm receipts and A4 invoices.',
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store Phone Number', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g. 9876543210',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('Store Address / Place', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Shop 4, Station Road',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('State', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _stateController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Maharashtra',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('GSTIN (Optional)', style: AppTypography.section.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _gstinController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. 27AAAAA0000A1Z5',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
