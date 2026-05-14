import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _handleSubmit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(_currentStep == 4 ? 'CONFIRM' : 'NEXT'),
                ),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('BACK'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Gender'),
            content: Row(
              children: [
                _choiceChip('Male', 'male', profileState.gender, notifier.updateGender),
                const SizedBox(width: 12),
                _choiceChip('Female', 'female', profileState.gender, notifier.updateGender),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Age'),
            content: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'years'),
                    onChanged: (value) => notifier.updateAge(int.tryParse(value) ?? 25),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Weight'),
            content: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'kg'),
                    onChanged: (value) => notifier.updateWeight(double.tryParse(value) ?? 70.0),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Activity Level'),
            content: Column(
              children: [
                _activityOption('Sedentary', 'sedentary', profileState.activityLevel, notifier.updateActivityLevel),
                _activityOption('Lightly Active', 'light', profileState.activityLevel, notifier.updateActivityLevel),
                _activityOption('Moderately Active', 'moderate', profileState.activityLevel, notifier.updateActivityLevel),
                _activityOption('Very Active', 'active', profileState.activityLevel, notifier.updateActivityLevel),
                _activityOption('Extra Active', 'very_active', profileState.activityLevel, notifier.updateActivityLevel),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Daily Target'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Based on your profile, we recommend:',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  '${profileState.calculatedTargetMl} ml',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '[Illustration Placeholder - Water Intake]',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _showManualEdit(context, profileState, notifier),
                  child: const Text('Ubah Manual'),
                ),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, String value, String current, Function(String) onSelected) {
    final selected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: Colors.blue.withOpacity(0.2),
      labelStyle: TextStyle(color: selected ? Colors.blue : Colors.black),
    );
  }

  Widget _activityOption(String label, String value, String current, Function(String) onSelected) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: current,
      onChanged: (v) => onSelected(v!),
    );
  }

  void _showManualEdit(BuildContext context, ProfileState state, ProfileNotifier notifier) {
    final controller = TextEditingController(text: (state.manualTargetMl ?? state.calculatedTargetMl).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'ml'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              notifier.updateManualTarget(int.tryParse(controller.text));
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    try {
      await ref.read(profileProvider.notifier).submitProfile();
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
