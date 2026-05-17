import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    
    # Common theme substitutions
    content = re.sub(r'const Color\(0xFF161F30\)', 'Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface', content)
    content = re.sub(r'const Color\(0xFF1565C0\)', 'Theme.of(context).colorScheme.primary', content)
    content = re.sub(r'const Color\(0xFF101B2E\)', 'Theme.of(context).colorScheme.surface', content)
    content = re.sub(r'const Color\(0xFF1A1A2E\)', 'Theme.of(context).colorScheme.surface', content)
    content = re.sub(r'const Color\(0xFF94A3B8\)', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'const Color\(0xFF34D399\)', 'Theme.of(context).extension<AppThemeExtension>()?.success ?? Colors.green', content)
    content = re.sub(r'const Color\(0xFFE2E8F0\)', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'const Color\(0xFF1E3A8A\)', 'Theme.of(context).colorScheme.primary', content)
    content = re.sub(r'const Color\(0xFFCBD5E1\)', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'const Color\(0xFF42A5F5\)', 'Theme.of(context).colorScheme.secondary', content)
    content = re.sub(r'const Color\(0xFF64748B\)', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'const Color\(0xFF334155\)', 'Theme.of(context).colorScheme.outline', content)
    content = re.sub(r'const Color\(0xFFBDDDFD\)', 'Theme.of(context).extension<AppThemeExtension>()?.waterLight ?? Colors.blue.shade100', content)
    content = re.sub(r'const Color\(0xFFC4E8C2\)', 'Theme.of(context).extension<AppThemeExtension>()?.success ?? Colors.green.shade100', content)
    content = re.sub(r'const Color\(0xFFFFE194\)', 'Theme.of(context).extension<AppThemeExtension>()?.warning ?? Colors.orange.shade100', content)
    content = re.sub(r'Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'Colors\.black54', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'Colors\.grey\.shade600', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'Colors\.grey\.shade400', 'Theme.of(context).colorScheme.outline', content)
    content = re.sub(r'Colors\.grey', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'Colors\.white', 'Theme.of(context).colorScheme.onPrimary', content)
    content = re.sub(r'Colors\.green', 'Theme.of(context).extension<AppThemeExtension>()?.success ?? Colors.green', content)

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('/Users/difmaas/Desktop/repos/water_tracker_smanli_v2/lib'):
    if 'theme' in root: # Skip theme folder
        continue
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

