import 'package:flutter/material.dart';
import '../../../core/widgets/primary_button.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Screen: $title', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Go to Home',
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
