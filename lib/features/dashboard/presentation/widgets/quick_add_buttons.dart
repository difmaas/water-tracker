import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/hydration_provider.dart';
import 'target_achieved_sheet.dart';

class QuickAddButtons extends ConsumerWidget {
  final bool lightweightMode;

  const QuickAddButtons({super.key, this.lightweightMode = false});

  static const Color kPrimaryBlue = Color(0xFF1A73E8);
  static const Color kSoftBlue = Color(0xFFE8F4FF);
  static const Color kDarkText = Color(0xFF1F2937);

  /// Logs water and shows an undo Snackbar or success BottomSheet.
  Future<void> _addWater(
    BuildContext context,
    WidgetRef ref,
    int volumeMl,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final oldState = ref.read(hydrationProvider);
    final wasReachedBefore = oldState.isTargetReached;

    final log = await ref.read(hydrationProvider.notifier).addLog(volumeMl);

    if (log == null) return;

    if (!context.mounted) return;

    final newState = ref.read(hydrationProvider);
    final isReachedAfter = newState.isTargetReached;

    if (!wasReachedBefore && isReachedAfter) {
      // Show Target Achieved Success Alert (Bottom Sheet)
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        builder: (sheetContext) {
          return TargetAchievedSheet(
            state: newState,
            lightweightMode: lightweightMode,
          );
        },
      );
    } else {
      // Show normal snackbar
      scaffoldMessenger.clearSnackBars();

      final snackBarController = scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: lightweightMode
              ? EdgeInsets.only(
                  left: (screenWidth - 240) / 2,
                  right: (screenWidth - 240) / 2,
                  bottom: 24.0,
                )
              : const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: lightweightMode
              ? Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF1A73E8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${volumeMl}ml',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(hydrationProvider.notifier).undoLog(log.id);
                          scaffoldMessenger.hideCurrentSnackBar();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.82),
                            Colors.white.withValues(alpha: 0.68),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _UndoSnackBarContent(
                        volumeMl: volumeMl,
                        scaffoldMessenger: scaffoldMessenger,
                        logId: log.id,
                      ),
                    ),
                  ),
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

  static double _getIconSize(int volume) {
    switch (volume) {
      case 250:
        return 36.0;
      case 500:
        return 40.0;
      case 750:
        return 52.0;
      case 1000:
        return 44.0;
      default:
        return 40.0;
    }
  }

  Widget _buildPresetItem(
    BuildContext context,
    BuildContext sheetContext,
    WidgetRef ref,
    int volume,
  ) {
    final isDrinkDisabled = ref.read(hydrationProvider).isDrinkDisabled;
    final effectiveTextColor = lightweightMode
        ? const Color(0xFF1A73E8)
        : Colors.black;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDrinkDisabled
              ? null
              : () {
                  Navigator.pop(sheetContext);
                  _addWater(context, ref, volume);
                },
          child: Opacity(
            opacity: isDrinkDisabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: lightweightMode
                    ? const Color(0xFFEAF5FF)
                    : Colors.white.withValues(alpha: 0.82),
                gradient: lightweightMode
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.88),
                          Colors.white.withValues(alpha: 0.76),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: lightweightMode
                      ? const Color(0xFFD7EAFB)
                      : Colors.white.withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/${volume}ml.svg',
                    width: _getIconSize(volume),
                    height: _getIconSize(volume),
                    colorFilter: ColorFilter.mode(
                      effectiveTextColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$volume ml',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: effectiveTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLainnyaBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (sheetContext) {
        final sheet = Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            color: lightweightMode
                ? const Color(0xFFEAF5FF)
                : Colors.white.withValues(alpha: 0.9),
            gradient: lightweightMode
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.94),
                      Colors.white.withValues(alpha: 0.86),
                    ],
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: lightweightMode
                  ? const Color(0xFFD7EAFB)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Volume Air',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Larger presets share the same source as the edit-log flow.
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: kHydrationVolumePresets
                    .skip(2)
                    .map(
                      (volume) =>
                          _buildPresetItem(context, sheetContext, ref, volume),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        );

        if (lightweightMode) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: sheet,
          );
        }

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: sheet,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDrinkDisabled = ref.watch(
      hydrationProvider.select((state) => state.isDrinkDisabled),
    );

    return Row(
      children: [
        // Primary: Glassmorphic Black/Accent
        _QuickAddButton(
          label: '+250',
          subLabel: 'ml',
          svgPath: 'assets/icons/250ml.svg',
          iconSize: _getIconSize(kHydrationVolumePresets[0]),
          backgroundColor: Colors.transparent,
          textColor: Colors.black,
          iconBgColor: Colors.black.withValues(alpha: 0.05),
          lightweightMode: lightweightMode,
          onTap: isDrinkDisabled ? null : () => _addWater(context, ref, kHydrationVolumePresets[0]),
        ),
        const SizedBox(width: 12),
        // Secondary: Glassmorphic Black/Accent
        _QuickAddButton(
          label: '+500',
          subLabel: 'ml',
          svgPath: 'assets/icons/500ml.svg',
          iconSize: _getIconSize(kHydrationVolumePresets[1]),
          backgroundColor: Colors.transparent,
          textColor: Colors.black,
          iconBgColor: Colors.black.withValues(alpha: 0.05),
          lightweightMode: lightweightMode,
          onTap: isDrinkDisabled ? null : () => _addWater(context, ref, kHydrationVolumePresets[1]),
        ),
        const SizedBox(width: 12),
        // Tertiary: Glassmorphic Other Option
        _QuickAddButton(
          label: 'Lainnya',
          subLabel: '',
          icon: Icons.more_horiz_rounded,
          backgroundColor: Colors.transparent,
          textColor: Colors.black,
          iconBgColor: Colors.black.withValues(alpha: 0.05),
          lightweightMode: lightweightMode,
          onTap: isDrinkDisabled ? null : () => _showLainnyaBottomSheet(context, ref),
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatefulWidget {
  final String label;
  final String subLabel;
  final IconData? icon;
  final String? svgPath;
  final double? iconSize;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color iconBgColor;
  final bool lightweightMode;

  const _QuickAddButton({
    required this.label,
    required this.subLabel,
    this.icon,
    this.svgPath,
    this.iconSize,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.iconBgColor,
    required this.lightweightMode,
  });

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;
    final double buttonHeight = isNarrow ? 92.0 : 104.0;

    return Expanded(
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.lightweightMode ? 1.0 : (_isPressed ? 0.95 : 1.0),
          duration: widget.lightweightMode
              ? Duration.zero
              : const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Opacity(
            opacity: widget.onTap == null ? 0.5 : 1.0,
            child: widget.lightweightMode
                ? Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD7EAFB),
                        width: 1.2,
                      ),
                    ),
                    child: _QuickAddButtonContent(widget: widget),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.82),
                              Colors.white.withValues(alpha: 0.58),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.72),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(6, 10),
                            ),
                          ],
                        ),
                        child: _QuickAddButtonContent(widget: widget),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddButtonContent extends StatelessWidget {
  final _QuickAddButton widget;

  const _QuickAddButtonContent({required this.widget});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    final double computedIconSize = widget.svgPath != null
        ? (isNarrow ? (widget.iconSize ?? 24) * 0.85 : (widget.iconSize ?? 24))
        : 20.0;
    final double labelFontSize = isNarrow ? 15.0 : 18.0;
    final double subLabelFontSize = isNarrow ? 10.0 : 12.0;
    final double spacing = isNarrow ? 6.0 : 10.0;

    final Color effectiveTextColor = widget.lightweightMode
        ? const Color(0xFF1A73E8)
        : widget.textColor;

    final Color effectiveIconBgColor = widget.lightweightMode
        ? const Color(0xFF1A73E8).withValues(alpha: 0.08)
        : widget.iconBgColor;

    final Widget iconWidget = widget.svgPath != null
        ? SvgPicture.asset(
            widget.svgPath!,
            width: computedIconSize,
            height: computedIconSize,
            colorFilter: ColorFilter.mode(effectiveTextColor, BlendMode.srcIn),
          )
        : Icon(
            widget.icon,
            color: effectiveTextColor,
            size: isNarrow ? 16 : 20,
          );

    final Widget iconContainer = widget.lightweightMode
        ? Container(
            padding: EdgeInsets.all(isNarrow ? 6 : 8),
            decoration: BoxDecoration(
              color: effectiveIconBgColor,
              shape: BoxShape.circle,
            ),
            child: iconWidget,
          )
        : (widget.svgPath != null
              ? iconWidget
              : Container(
                  padding: EdgeInsets.all(isNarrow ? 6 : 8),
                  decoration: BoxDecoration(
                    color: effectiveIconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: iconWidget,
                ));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconContainer,
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.manrope(
                fontSize: labelFontSize,
                fontWeight: FontWeight.normal,
                color: effectiveTextColor,
                letterSpacing: -0.5,
              ),
            ),
            if (widget.subLabel.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                widget.subLabel,
                style: GoogleFonts.manrope(
                  fontSize: subLabelFontSize,
                  fontWeight: FontWeight.normal,
                  color: effectiveTextColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _UndoSnackBarContent extends ConsumerWidget {
  final int volumeMl;
  final ScaffoldMessengerState scaffoldMessenger;
  final int logId;

  const _UndoSnackBarContent({
    required this.volumeMl,
    required this.scaffoldMessenger,
    required this.logId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF1A73E8),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Berhasil ditambah +${volumeMl}ml',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.normal,
              fontSize: 13,
              color: QuickAddButtons.kDarkText,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            ref.read(hydrationProvider.notifier).undoLog(logId);
            scaffoldMessenger.hideCurrentSnackBar();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Batal',
            style: GoogleFonts.manrope(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
