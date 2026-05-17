import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    
    # Common theme substitutions
    # bool isDark = Theme.of(context).brightness == Brightness.dark; is often used.
    
    content = re.sub(r'isDark \? const Color\(0xFF[0-9A-Fa-f]+\) : const Color\(0xFF[0-9A-Fa-f]+\)', 'Theme.of(context).colorScheme.primary', content)
    content = re.sub(r'isDark \? const Color\(0xFF1E293B\) : Colors\.white', 'Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface', content)
    content = re.sub(r'isDark \? const Color\(0xFF24334A\) : Colors\.grey\.shade200', 'Theme.of(context).colorScheme.outlineVariant', content)
    content = re.sub(r'isDark \? const Color\(0xFF24334A\) : Colors\.grey\.shade300', 'Theme.of(context).colorScheme.outlineVariant', content)
    content = re.sub(r'isDark \? const Color\(0xFF0B111E\) : const Color\(0xFFF5F8FF\)', 'Theme.of(context).colorScheme.surface', content)
    content = re.sub(r'isDark \? Colors\.white70 : Colors\.black54', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'isDark \? Colors\.white : Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'isDark \? Colors\.white70 : Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'isDark \? Colors\.white54 : Colors\.black45', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)', content)
    content = re.sub(r'isDark \? Colors\.white54 : Colors\.black54', 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)', content)
    content = re.sub(r'isDark \? Colors\.white54 : Colors\.grey', 'Theme.of(context).colorScheme.onSurfaceVariant', content)
    content = re.sub(r'isDark \? Colors\.grey\[400\] : Colors\.black87', 'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'isDark \? const Color\(0xFF1E293B\) : const Color\(0xFFF8FAFC\)', 'Theme.of(context).colorScheme.surfaceContainerHighest', content)
    content = re.sub(r'isDark \? const Color\(0xFF1E293B\) : Colors\.red\.shade50', 'Theme.of(context).colorScheme.errorContainer', content)

    # Some direct hardcoded colors
    content = re.sub(r'const Color\(0xFF7DD3FC\)', 'Theme.of(context).colorScheme.secondaryContainer', content)
    content = re.sub(r'const Color\(0xFF0369A1\)', 'Theme.of(context).colorScheme.onSecondaryContainer', content)
    content = re.sub(r'const Color\(0xFF1E293B\)', 'Theme.of(context).colorScheme.surfaceContainerHighest', content)
    content = re.sub(r'const Color\(0xFF24334A\)', 'Theme.of(context).colorScheme.outlineVariant', content)
    
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

