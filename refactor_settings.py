import re

path = '/Users/difmaas/Desktop/repos/water_tracker_smanli_v2/lib/features/settings/presentation/settings_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# Replace variables defined based on isDark
content = re.sub(r'final primaryBlue = isDark \? const Color\(0xFF38BDF8\) : const Color\(0xFF1565C0\);', 'final primaryBlue = Theme.of(context).colorScheme.primary;', content)
content = re.sub(r'final scaffoldBg = isDark \? const Color\(0xFF0B111E\) : const Color\(0xFFF5F8FF\);', 'final scaffoldBg = Theme.of(context).colorScheme.surface;', content)
content = re.sub(r'final cardColor = isDark \? const Color\(0xFF1E293B\) : Colors\.white;', 'final cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;', content)
content = re.sub(r'final borderSideColor = isDark \? const Color\(0xFF24334A\) : Colors\.grey\.shade200;', 'final borderSideColor = Theme.of(context).colorScheme.outlineVariant;', content)

content = re.sub(r'final activeBgColor = isDark \? const Color\(0xFF334155\) : const Color\(0xFFE3F2FD\);', 'final activeBgColor = Theme.of(context).colorScheme.primaryContainer;', content)
content = re.sub(r'final activeTextColor = isDark \? const Color\(0xFF38BDF8\) : const Color\(0xFF1565C0\);', 'final activeTextColor = Theme.of(context).colorScheme.primary;', content)
content = re.sub(r'final activeIconColor = isDark \? const Color\(0xFF38BDF8\) : const Color\(0xFF1565C0\);', 'final activeIconColor = Theme.of(context).colorScheme.primary;', content)

content = re.sub(r'isDark \? const Color\(0xFF24334A\) : Colors\.grey\.shade300', 'Theme.of(context).colorScheme.outlineVariant', content)
content = re.sub(r'isDark \? const Color\(0xFF24334A\) : Colors\.grey\.shade200', 'Theme.of(context).colorScheme.outlineVariant', content)

content = re.sub(r'isDark \? Colors\.white70 : Colors\.black54', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
content = re.sub(r'isDark \? Colors\.white : Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)
content = re.sub(r'isDark \? Colors\.white70 : Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)
content = re.sub(r'isDark \? Colors\.white54 : Colors\.black45', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)', content)
content = re.sub(r'isDark \? Colors\.white54 : Colors\.black54', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)', content)
content = re.sub(r'isDark \? Colors\.white54 : Colors\.grey', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
content = re.sub(r'isDark \? Colors\.grey\[400\] : Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)

content = re.sub(r'isDark \? const Color\(0xFF1E293B\) : const Color\(0xFFF8FAFC\)', 'Theme.of(context).colorScheme.surfaceContainerHighest', content)
content = re.sub(r'isDark \? const Color\(0xFF1E293B\) : Colors\.red\.shade50', 'Theme.of(context).colorScheme.errorContainer', content)

content = re.sub(r'isDark \? const Color\(0xFF38BDF8\) : const Color\(0xFF1565C0\)', 'Theme.of(context).colorScheme.primary', content)
content = re.sub(r'isDark \? const Color\(0xFF0B111E\) : const Color\(0xFFF5F8FF\)', 'Theme.of(context).colorScheme.surface', content)

with open(path, 'w') as f:
    f.write(content)

