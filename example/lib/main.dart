import 'package:flutter/material.dart';
import 'package:message_segment_calculator/src/segmented_message.dart';

/// The main entry point of the application.
void main() {
  runApp(const App());
}

/// The root widget of the application.
class App extends StatelessWidget {
  /// Constructs an [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    /// Builds the [MaterialApp] that contains the [MessageSegmentCalculatorWidget].
    return const MaterialApp(
      home: MessageSegmentCalculatorWidget(),
    );
  }
}

/// A stateful widget that provides a UI for calculating message segments.
///
/// This widget uses the [SegmentedMessage] class to calculate the number of characters,
/// segments, Unicode scalars, message size in bits, and total size in bits
/// based on the user input in the text field.
class MessageSegmentCalculatorWidget extends StatefulWidget {
  /// Constructs a [MessageSegmentCalculatorWidget].
  const MessageSegmentCalculatorWidget({super.key});

  @override
  State<MessageSegmentCalculatorWidget> createState() =>
      _MessageSegmentCalculatorWidgetState();
}

/// The state class for [MessageSegmentCalculatorWidget].
class _MessageSegmentCalculatorWidgetState
    extends State<MessageSegmentCalculatorWidget> {
  /// Controller for the text field where the user inputs the message text.
  final textEditingController = TextEditingController();

  /// Holds the segmented message data to display the results.
  SegmentedMessage? segmentedMessage;

  @override
  void dispose() {
    /// Disposes of the [textEditingController] when the widget is disposed.
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Builds the UI for the message segment calculator.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Segment Calculator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const Text('Enter text'),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(),
                maxLines: 15,
                controller: textEditingController,
                onChanged: (value) {
                  setState(() {
                    /// Updates the [segmentedMessage] whenever the text input changes.
                    segmentedMessage = SegmentedMessage(value);
                  });
                },
              ),
              const SizedBox(height: 10),

              /// Displays the results of the message segmentation calculations.
              Text('number of characters : ${segmentedMessage?.numberOfCharacters}'),
              Text('number of segments : ${segmentedMessage?.segmentsCount}'),
              Text('number of unicode scalars : ${segmentedMessage?.numberOfUnicodeScalars}'),
              Text('message size in bits : ${segmentedMessage?.messageSize}'),
              Text('total size in bits : ${segmentedMessage?.totalSize}'),
              const SizedBox(height: 10),
              Text('segments:\n${segmentedMessage?.segments.map((segment) => '- $segment').join('\n')}', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
