import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/hydration_provider.dart';
import 'target_achieved_sheet.dart';

class QuickAddButtons extends ConsumerWidget {
  const QuickAddButtons({super.key});

  static const Color kPrimaryBlue = Color(0xFF1A73E8);
  static const Color kSoftBlue = Color(0xFFE8F4FF);
  static const Color kDarkText = Color(0xFF1F2937);

  /// Logs water and shows an undo Snackbar or success BottomSheet.
  Future<void> _addWater(
    BuildContext context,
    WidgetRef ref,
    int volumeMl,
  ) async {
    final oldState = ref.read(hydrationProvider);
    final wasReachedBefore = oldState.isTargetReached;

    final log = await ref.read(hydrationProvider.notifier).addLog(volumeMl);

    if (log == null || !context.mounted) return;

    final newState = ref.read(hydrationProvider);
    final isReachedAfter = newState.isTargetReached;

    if (!wasReachedBefore && isReachedAfter) {
      // Show Target Achieved Success Alert (Bottom Sheet)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return TargetAchievedSheet(state: newState);
        },
      );
    } else {
      // Show normal snackbar
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();

      final snackBarController = scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Berhasil ditambah +${volumeMl}ml',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kDarkText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          action: SnackBarAction(
            label: 'BATAL',
            textColor: const Color(0xFFF9AB00), // Warning orange
            onPressed: () {
              ref.read(hydrationProvider.notifier).undoLog(log.id);
            },
          ),
        ),
      );

      // Force close after 5 seconds to bypass Android accessibility overrides
      Future.delayed(const Duration(seconds: 5), () {
        try {
          snackBarController.close();
        } catch (_) {}
      });
    }
  }

  Widget _buildPresetItem(
    BuildContext context,
    BuildContext sheetContext,
    WidgetRef ref,
    int volume,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        _addWater(context, ref, volume);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FF), // Soft blue accent
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_drink_rounded,
              color: kPrimaryBlue,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              '$volume ml',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLainnyaBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Volume Air',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kDarkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Grid of presets: 700ml, 800ml, 1000ml, 1500ml
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPresetItem(context, sheetContext, ref, 700),
                  _buildPresetItem(context, sheetContext, ref, 800),
                  _buildPresetItem(context, sheetContext, ref, 1000),
                  _buildPresetItem(context, sheetContext, ref, 1500),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Primary: Solid Blue
        _QuickAddButton(
          label: '+250',
          subLabel: 'ml',
          icon: Icons.water_drop,
          backgroundColor: kPrimaryBlue,
          textColor: Colors.white,
          iconBgColor: Colors.white.withValues(alpha: 0.2),
          onTap: () => _addWater(context, ref, 250),
        ),
        const SizedBox(width: 12),
        // Secondary: Soft Blue Accent
        _QuickAddButton(
          label: '+500',
          subLabel: 'ml',
          icon: Icons.local_drink_rounded,
          backgroundColor: kSoftBlue,
          textColor: kPrimaryBlue,
          iconBgColor: kPrimaryBlue.withValues(alpha: 0.1),
          onTap: () => _addWater(context, ref, 500),
        ),
        const SizedBox(width: 12),
        // Tertiary: White Outline
        _QuickAddButton(
          label: 'Custom',
          subLabel: '',
          icon: Icons.more_horiz_rounded,
          backgroundColor: Colors.white,
          textColor: kDarkText,
          iconBgColor: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          onTap: () => _showLainnyaBottomSheet(context, ref),
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatefulWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color iconBgColor;
  final BoxBorder? border;

  const _QuickAddButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.iconBgColor,
    this.border,
  });

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border:
                  widget.border ??
                  Border.all(
                    color: Colors.black.withValues(alpha: 0.01),
                    width: 1,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.textColor, size: 20),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.subLabel.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      Text(
                        widget.subLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
