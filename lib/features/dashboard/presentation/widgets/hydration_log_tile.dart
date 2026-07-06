import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/logging/data/hydration_log_model.dart';
import '../../../../providers/hydration_provider.dart';
import '../../../../providers/app_settings_provider.dart';
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
      return 28.0;
    } else if (volume <= 600) {
      return 30.0;
    } else if (volume <= 850) {
      return 36.0; // 750ml has extra internal padding
    } else {
      return 32.0;
    }
  }

  double _getPresetIconSize(int volume) {
    if (volume <= 350) {
      return 32.0;
    } else if (volume <= 600) {
      return 36.0;
    } else if (volume <= 850) {
      return 48.0;
    } else {
      return 40.0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );
    final timeString =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          // Svg icon corresponding to volume size (centered in a fixed size container)
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SvgPicture.asset(
                _getIconPath(log.volume),
                width: _getVisualIconSize(log.volume),
                height: _getVisualIconSize(log.volume),
                colorFilter: ColorFilter.mode(
                  lightweightMode ? const Color(0xFF1A73E8) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Time of logging
          Text(
            timeString,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: kObsidian,
            ),
          ),
          const Spacer(),
          // Volume logged
          Text(
            '+${log.volume} ml',
            style: GoogleFonts.manrope(
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
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        if (lightweightMode) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD7E5FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Hapus catatan minum',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5AA0FF),
                            width: 1.2,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Catatan yang dihapus tidak bisa dikembalikan.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _LightweightSheetWhiteButton(
                      label: 'HAPUS CATATAN',
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref
                            .read(hydrationProvider.notifier)
                            .deleteLog(log.id, log.timestamp);

                        final screenWidth = MediaQuery.of(context).size.width;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            margin: EdgeInsets.only(
                              left: (screenWidth - 240) / 2,
                              right: (screenWidth - 240) / 2,
                              bottom: 24.0,
                            ),
                            padding: EdgeInsets.zero,
                            content: Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
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
                                children: [
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Catatan ${log.volume}ml dihapus',
                                      style: GoogleFonts.manrope(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final dialogContent = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lightweightMode
                ? const Color(0xFFEAF5FF)
                : Colors.white.withValues(alpha: 0.92),
            gradient: lightweightMode
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.96),
                      Colors.white.withValues(alpha: 0.88),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: lightweightMode
                  ? const Color(0xFFD7EAFB)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: lightweightMode
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hapus catatan minum ini?',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Catatan yang dihapus tidak bisa dikembalikan.',
                style: GoogleFonts.manrope(
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

                        final screenWidth = MediaQuery.of(context).size.width;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            margin: lightweightMode
                                ? EdgeInsets.only(
                                    left: (screenWidth - 240) / 2,
                                    right: (screenWidth - 240) / 2,
                                    bottom: 24.0,
                                  )
                                : const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            padding: EdgeInsets.zero,
                            content: lightweightMode
                                ? Container(
                                    height: 60,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.2,
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
                                      children: [
                                        const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Catatan ${log.volume}ml dihapus',
                                            style: GoogleFonts.manrope(
                                              color: Colors.black87,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 16,
                                        sigmaY: 16,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.82,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
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
                                                style: GoogleFonts.manrope(
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
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: lightweightMode
                ? dialogContent
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: dialogContent,
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

    final lightweightMode = ref.read(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (lightweightMode) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E5FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Edit catatan minum',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF5AA0FF),
                                width: 1.2,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF0F172A),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
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
                                iconSize: _getPresetIconSize(volume),
                                lightweightMode: lightweightMode,
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _LightweightSheetWhiteButton(
                          label: 'SIMPAN',
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      margin: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              color: Color(0xFF1A73E8),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Volume berhasil diubah menjadi $newVolume ml',
                                                style: GoogleFonts.manrope(
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
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dialogContent = Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightweightMode
                    ? const Color(0xFFEAF5FF)
                    : Colors.white.withValues(alpha: 0.92),
                gradient: lightweightMode
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.96),
                          Colors.white.withValues(alpha: 0.88),
                        ],
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: lightweightMode
                      ? const Color(0xFFD7EAFB)
                      : Colors.white.withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: lightweightMode
                    ? const []
                    : [
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
                    style: GoogleFonts.manrope(
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
                    childAspectRatio: 1.3,
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
                            iconSize: _getPresetIconSize(volume),
                            lightweightMode: lightweightMode,
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      margin: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      content: lightweightMode
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .check_circle_outline_rounded,
                                                    color: Color(0xFF1A73E8),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Volume berhasil diubah menjadi $newVolume ml',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            color:
                                                                Colors.black87,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 16,
                                                  sigmaY: 16,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 14,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Colors.white.withValues(
                                                          alpha: 0.9,
                                                        ),
                                                        Colors.white.withValues(
                                                          alpha: 0.82,
                                                        ),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                      width: 1.2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        blurRadius: 16,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .check_circle_outline_rounded,
                                                        color: Color(
                                                          0xFF1A73E8,
                                                        ),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Volume berhasil diubah menjadi $newVolume ml',
                                                          style:
                                                              GoogleFonts.manrope(
                                                                color: Colors
                                                                    .black87,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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
            );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: lightweightMode
                    ? dialogContent
                    : BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: dialogContent,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _showActionsBottomSheet(BuildContext context, WidgetRef ref) {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
        final sheetContent = lightweightMode
            ? Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E5FF),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _LightweightSheetWhiteButton(
                        label: 'EDIT CATATAN',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showEditDialog(context, ref);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _LightweightSheetWhiteButton(
                        label: 'HAPUS CATATAN',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showDeleteDialog(context, ref);
                        },
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + bottomInset),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.94),
                      Colors.white.withValues(alpha: 0.86),
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
                        'Edit catatan',
                        style: GoogleFonts.manrope(
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
                        'Hapus catatan',
                        style: GoogleFonts.manrope(
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
              );

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: lightweightMode
                ? sheetContent
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: sheetContent,
                  ),
          ),
        );
      },
    );
  }
}

class _LightweightSheetWhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _LightweightSheetWhiteButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
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
  final bool lightweightMode;

  const _EditVolumeCard({
    required this.volume,
    required this.isSelected,
    required this.iconPath,
    required this.iconSize,
    required this.onTap,
    required this.lightweightMode,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF1A73E8)
        : (lightweightMode
              ? const Color(0xFFE2E8F0)
              : Colors.white.withValues(alpha: 0.65));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: lightweightMode
                  ? (isSelected ? const Color(0xFFEAF5FF) : Colors.white)
                  : null,
              gradient: lightweightMode
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: isSelected ? 0.9 : 0.82),
                        Colors.white.withValues(
                          alpha: isSelected ? 0.78 : 0.68,
                        ),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.8 : (lightweightMode ? 1.0 : 1.2),
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
                        colorFilter: ColorFilter.mode(
                          lightweightMode
                              ? const Color(0xFF1A73E8)
                              : (isSelected
                                  ? const Color(0xFF1A73E8)
                                  : Colors.black),
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
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: lightweightMode
                        ? const Color(0xFF1A73E8)
                        : (isSelected ? const Color(0xFF1A73E8) : Colors.black),
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helperText!,
                    style: GoogleFonts.manrope(
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
