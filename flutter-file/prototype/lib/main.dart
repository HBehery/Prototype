import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Action Items Recommendation Tool',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChecklistScreen(),
    );
  }
}

class ChecklistScreen extends StatefulWidget {
  @override
  ChecklistScreenState createState() => ChecklistScreenState();
}

class ChecklistScreenState extends State<ChecklistScreen> {
  final TextEditingController textEditingController = TextEditingController();
  List<String> sentences = [];
  List<String> selectedSentences = [];
  List<String> apiResponse = [];
  String combinedParagraph = '';
  String summaryText = '';
  bool isLoadingAction = false;
  bool isLoadingSummary = false;
  bool hasGeneratedChecklist = false;

  void generateChecklist() {
    String inputText = textEditingController.text;
    List<String> tempSentences = inputText.split(RegExp(r"(?<=[?.!])\s+"));
    setState(() {
      sentences = tempSentences;
      hasGeneratedChecklist = true;
      apiResponse = [];
      isLoadingAction = true;
    });

    String apiUrlAction = 'http://127.0.0.1:8080/action_items/$inputText';
    http.get(Uri.parse(apiUrlAction)).then((response) {
      setState(() {
        final decodedBody = json.decode(response.body);
        final apiList = decodedBody['action_items'] as List<dynamic>;
        apiResponse = List<String>.from(apiList);
        isLoadingAction = false;
      });
      print('Action API Response: $apiResponse');
    }).catchError((error) {
      print('Error: $error');
      setState(() {
        isLoadingAction = false;
      });
    });
  }

  void combineSelectedSentences() {
    setState(() {
      selectedSentences = sentences
          .where((sentence) => selectedSentences.contains(sentence))
          .toList();
      combinedParagraph = selectedSentences.join(' ');
    });
  }

  void summarizeSelection() {
    String apiUrl_summary =
        'http://127.0.0.1:8080/summarize/$combinedParagraph';
    setState(() {
      isLoadingSummary = true;
    });
    http.get(Uri.parse(apiUrl_summary)).then((response) {
      setState(() {
        final decodedBody = json.decode(response.body);
        summaryText = decodedBody['summary_text'] ?? '';
        isLoadingSummary = false;
      });
      print('Summary Text: $summaryText');
    }).catchError((error) {
      print('Error: $error');
      setState(() {
        isLoadingSummary = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Items Recommendation Tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: textEditingController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter text...',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: generateChecklist,
              child: const Text('Generate Checklist'),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: sentences.length,
                itemBuilder: (context, index) {
                  final sentence = sentences[index];
                  final bool isChecked = selectedSentences.contains(sentence);
                  final bool isFoundInApiResponse =
                      apiResponse.contains(sentence);
                  final Color textColor =
                      isFoundInApiResponse ? Colors.green : Colors.red;

                  return ListTile(
                    leading: Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedSentences.add(sentence);
                          } else {
                            selectedSentences.remove(sentence);
                          }
                        });
                      },
                    ),
                    title: Text(
                      sentence,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: combineSelectedSentences,
              child: const Text('Combine Selected Sentences'),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Combined Paragraph:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(combinedParagraph),
            const SizedBox(height: 16.0),
            Visibility(
              visible: hasGeneratedChecklist,
              child: ElevatedButton(
                onPressed: summarizeSelection,
                child: const Text('Summarize Selection'),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Summary Text:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Visibility(
              visible: !isLoadingSummary && summaryText.isNotEmpty,
              child: Text(summaryText),
            ),
            const SizedBox(height: 16.0),
            Visibility(
              visible: isLoadingAction,
              child: const CircularProgressIndicator(),
            ),
            Visibility(
              visible: isLoadingSummary,
              child: const CircularProgressIndicator(),
            ),
            const SizedBox(height: 16.0),
            // Text(
            //   'API Response:',
            //   style: TextStyle(
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // Visibility(
            //   visible: !isLoading_action && apiResponse.isNotEmpty,
            //   child: Text(apiResponse.join('\n')),
            // ),
          ],
        ),
      ),
    );
  }
}
