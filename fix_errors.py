import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    
    # Fix undefined_getter shadeXXX
    content = re.sub(r'Theme\.of\(context\)\.colorScheme\.onSurfaceVariant\.shade(\d+)', r'Theme.of(context).colorScheme.outlineVariant', content)
    content = re.sub(r'Theme\.of\(context\)\.colorScheme\.outline\.shade(\d+)', r'Theme.of(context).colorScheme.outlineVariant', content)

    # Fix undefined_getter onPrimaryXX
    content = re.sub(r'Theme\.of\(context\)\.colorScheme\.onPrimary(\d+)', r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.\1)', content)

    # Fix duplicate_named_argument scaffoldBackgroundColor
    if 'app_theme.dart' in filepath:
        content = re.sub(r'scaffoldBackgroundColor: AppColors\.background,\n\s*scaffoldBackgroundColor: AppColors\.background,', 'scaffoldBackgroundColor: AppColors.background,', content)
        content = re.sub(r'scaffoldBackgroundColor: AppColors\.backgroundDarkTheme,\n\s*scaffoldBackgroundColor: AppColors\.backgroundDarkTheme,', 'scaffoldBackgroundColor: AppColors.backgroundDarkTheme,', content)
    
    # Fix "AppThemeExtension isn't a type" by importing it if we use it
    if 'extension<AppThemeExtension>' in content and 'app_theme_extension.dart' not in content:
        # Find the last import and append it
        if 'import ' in content:
            last_import = content.rfind('import ')
            end_of_line = content.find('\n', last_import)
            
            # Need to figure out the relative path to lib/app/theme/app_theme_extension.dart
            # But the easiest hack is to just add it
            # filepath is like /Users/.../lib/features/dashboard/presentation/dashboard_screen.dart
            parts = filepath.split('/lib/')
            if len(parts) == 2:
                depth = len(parts[1].split('/')) - 1
                prefix = '../' * depth
                import_stmt = f"\nimport '{prefix}app/theme/app_theme_extension.dart';"
                content = content[:end_of_line] + import_stmt + content[end_of_line:]

    # Fix const Theme.of(context)
    content = re.sub(r'const Theme\.of\(context\)', 'Theme.of(context)', content)
    
    # Fix const [...] containing Theme.of(context)
    # This requires more complex regex or manual fixing. Let's do simple ones:
    content = re.sub(r'const \[([^\]]*Theme\.of\(context\)[^\]]*)\]', r'[\1]', content)
    
    # Fix const EdgeInsets... or const BorderRadius... if it contains Theme.of context
    # Usually it's `const Padding(padding: ..., child: Theme...)` 
    # Let's remove `const ` before widgets that contain Theme.of
    content = re.sub(r'const ([A-Z][a-zA-Z0-9_]*\([^;]*Theme\.of\(context\))', r'\1', content)
    content = re.sub(r'const ([A-Z][a-zA-Z0-9_]*\([^;]*Theme\.of\(context\))', r'\1', content)
    content = re.sub(r'const ([A-Z][a-zA-Z0-9_]*\([^;]*Theme\.of\(context\))', r'\1', content)
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('/Users/difmaas/Desktop/repos/water_tracker_smanli_v2/lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

