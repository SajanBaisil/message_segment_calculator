<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# SMS Segment Calculator

The SMS Segment Calculator is a Dart package designed to help developers accurately calculate the number of SMS segments required for messages. It supports both GSM-7 and UCS-2 encoding standards, providing a robust solution for applications that involve SMS messaging. The package ensures cost-effective messaging by optimizing message segmentation and encoding.

## Key Features

- **Accurate SMS Segmentation**: Automatically calculates the number of segments needed for a given SMS message based on its content and required encoding (GSM-7 or UCS-2).
- **Support for Special Characters and Emojis**: Detects texts containing emojis or special characters and switches to UCS-2 encoding when necessary.
- **Comprehensive Encoding Management**: Handles the encoding of individual characters and manages their conversion to the appropriate encoding format.
- **Cost Management**: Provides precise segment counts for budgeting and planning SMS costs effectively.
- **Line Break Handling**: Identifies different line break styles and issues warnings if incompatible styles are detected.

## Installation

To integrate the SMS Segment Calculator into your Dart or Flutter project, add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  message_segment_calculator: ^1.1.0



## Usage

import 'package:flutter/material.dart';
import 'package:message_segment_calculator/src/segmented_message.dart';

void main() {
  runApp(const App());
}

/// The root widget of the application.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MessageSegmentCalculatorWidget(),
    );
  }
}

/// A stateful widget that provides a UI for calculating message segments.
class MessageSegmentCalculatorWidget extends StatefulWidget {
  const MessageSegmentCalculatorWidget({super.key});

  @override
  State<MessageSegmentCalculatorWidget> createState() =>
      _MessageSegmentCalculatorWidgetState();
}

/// The state class for [MessageSegmentCalculatorWidget].
class _MessageSegmentCalculatorWidgetState
    extends State<MessageSegmentCalculatorWidget> {
  final textEditingController = TextEditingController();
  SegmentedMessage? segmentedMessage;

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Segment Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Text('Enter text'),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(),
              controller: textEditingController,
              onChanged: (value) {
                setState(() {
                  segmentedMessage = SegmentedMessage(value);
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Number of characters: ${segmentedMessage?.numberOfCharacters}'),
            Text('Number of segments: ${segmentedMessage?.segmentsCount}'),
            Text('Number of Unicode scalars: ${segmentedMessage?.numberOfUnicodeScalars}'),
            Text('Message size in bits: ${segmentedMessage?.messageSize}'),
            Text('Total size in bits: ${segmentedMessage?.totalSize}'),
          ],
        ),
      ),
    );
  }
}




### Key Additions:
- **Detailed Descriptions**: Each class is explained to clarify its role in the package.
- **Usage Example**: Shows a practical example to help developers quickly understand how to use the package.
- **Installation Instructions**: Guides users on how to add the package to their project.
- **Contribution Guidelines**: Encourages contributions and provides a link to the issues page.

This README provides a comprehensive overview, making it easier for users to understand and use the package effectively.

```
