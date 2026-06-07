import 'package:flutter/material.dart';

class TestRadio extends StatelessWidget {
  const TestRadio({super.key});

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: 'a',
      onChanged: (v) {},
      child: Column(
        children: [
          RadioListTile<String>(value: 'a', title: const Text('A')),
          RadioListTile<String>(value: 'b', title: const Text('B')),
        ],
      ),
    );
  }
}
