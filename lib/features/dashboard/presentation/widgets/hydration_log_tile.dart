import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/logging/data/hydration_log_model.dart';
import '../../../../providers/hydration_provider.dart';
import '../../../../core/widgets/app_button.dart';

class HydrationLogTile extends ConsumerWidget {
  final HydrationLog log;
  final bool isFirst;
  final bool isLast;
  final bool showActions;

  const HydrationLogTile({
    super.key,
    required this.log,
    this.isFirst = false,
    this.isLast = false,
    this.showActions = true,
  });

  static const Color kObsidian = Color(0xFF040415);

  String _getIconPath(int volume) {
    if (volume <= 350) {
      return 'assets/icons/250ml.svg';
    } else if (volume <= 600) {
      return 'assets/icons/500ml.svg';
    } else if (volume <= 850) {
      return 'assets/icons/750ml.svg';
    } else {
      return 'assets/icons/1000ml.svg';
    }
  }

  double _getVisualIconSize(int volume) {
    if (volume <= 350) {
      return 18.0;
    } else if (volume <= 600) {
      return 18.0;
    } else if (volume <= 850) {
      return 23.0; // 750ml has extra internal padding
    } else {
      return 19.0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeString =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          // Svg icon corresponding to volume size (centered in a fixed size container)
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: SvgPicture.asset(
                _getIconPath(log.volume),
                width: _getVisualIconSize(log.volume),
                height: _getVisualIconSize(log.volume),
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Time of logging
          Text(
            timeString,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: kObsidian,
            ),
          ),
          const Spacer(),
          // Volume logged
          Text(
            '+${log.volume} ml',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.black,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showActionsBottomSheet(context, ref),
            ),
          ] else ...[
            const SizedBox(width: 28),
          ],
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.90),
                      Colors.white.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hapus Catatan?',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Apakah Anda yakin ingin menghapus catatan minum air sebesar ${log.volume} ml ini?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF5F6368),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Batal',
                            isTransparent: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton.main(
                            label: 'Hapus',
                            color: const Color(0xFFEF4444),
                            onPressed: () {
                              Navigator.of(context).pop();
                              ref
                                  .read(hydrationProvider.notifier)
                                  .deleteLog(log.id, log.timestamp);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  padding: EdgeInsets.zero,
                                  content: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.65),
                                              Colors.white.withValues(alpha: 0.35),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Color(0xFFEF4444),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Catatan ${log.volume} ml berhasil dihapus',
                                                style: GoogleFonts.inter(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final volumeOptions = <int>[
      ...kHydrationVolumePresets,
      if (!kHydrationVolumePresets.contains(log.volume)) log.volume,
    ];
    var selectedVolume = log.volume;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.90),
                          Colors.white.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Catatan Minum',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A73E8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.8,
                          physics: const NeverScrollableScrollPhysics(),
                          children: volumeOptions
                              .map((volume) {
                                final isTemporaryOldValue =
                                    volume == log.volume &&
                                    !kHydrationVolumePresets.contains(volume);
                                return _EditVolumeCard(
                                  volume: volume,
                                  isSelected: selectedVolume == volume,
                                  helperText: isTemporaryOldValue
                                      ? 'Nilai lama'
                                      : null,
                                  iconPath: _getIconPath(volume),
                                  iconSize: _getVisualIconSize(volume),
                                  onTap: () {
                                    setDialogState(() {
                                      selectedVolume = volume;
                                    });
                                  },
                                );
                              })
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton.secondary(
                                label: 'Batal',
                                isTransparent: true,
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton.main(
                                label: 'Simpan',
                                onPressed: selectedVolume == log.volume
                                    ? null
                                    : () async {
                                        final newVolume = selectedVolume;
                                        Navigator.of(dialogContext).pop();
                                        await ref
                                            .read(hydrationProvider.notifier)
                                            .updateLog(
                                              log.id,
                                              newVolume,
                                              log.timestamp,
                                            );

                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.transparent,
                                            elevation: 0,
                                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            padding: EdgeInsets.zero,
                                            content: ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Colors.white.withValues(alpha: 0.65),
                                                        Colors.white.withValues(alpha: 0.35),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(
                                                      color: Colors.white.withValues(alpha: 0.6),
                                                      width: 1.2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.08),
                                                        blurRadius: 16,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle_outline_rounded,
                                                        color: Color(0xFF1A73E8),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Volume berhasil diubah menjadi $newVolume ml',
                                                          style: GoogleFonts.inter(
                                                            color: Colors.black87,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showActionsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.60),
                    Colors.white.withValues(alpha: 0.30),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Edit Catatan',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showEditDialog(context, ref);
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Hapus Catatan',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showDeleteDialog(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditVolumeCard extends StatelessWidget {
  final int volume;
  final bool isSelected;
  final String? helperText;
  final String iconPath;
  final double iconSize;
  final VoidCallback onTap;

  const _EditVolumeCard({
    required this.volume,
    required this.isSelected,
    required this.iconPath,
    required this.iconSize,
    required this.onTap,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF1A73E8)
        : Colors.white.withValues(alpha: 0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isSelected ? 0.62 : 0.40),
                  Colors.white.withValues(alpha: isSelected ? 0.26 : 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.8 : 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: SvgPicture.asset(
                        iconPath,
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1A73E8),
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$volume ml',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helperText!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
