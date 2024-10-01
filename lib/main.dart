import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.orange,
    ),
    home: ChatBot(),
  ));
}

class ChatBot extends StatefulWidget {
  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();

  // NASA API endpoint to fetch current astronauts
  final String astronautsUrl = 'http://api.open-notify.org/astros.json';
  // Placeholder for health-related information API
  final String healthApiUrl = 'https://api.nasa.gov/health_data_endpoint?api_key=g0xw3DkTIPtUdfzhjKoaLs0Kf79AEWg5kIGhHf6g';

  // Function to fetch current astronauts in space
  Future<String> _fetchCurrentAstronauts() async {
    final response = await http.get(Uri.parse(astronautsUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> astronauts = data['people'];

      List<String> astronautNames = astronauts
          .map((dynamic astro) => (astro as Map<String, dynamic>)['name'] as String)
          .toList();

      return 'Current astronauts in space: ${astronautNames.join(", ")}';
    } else {
      return 'Failed to load astronaut data';
    }
  }

  // Example function to fetch astronaut health data
  Future<String> _fetchAstronautHealth() async {
    final response = await http.get(Uri.parse(healthApiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return 'Astronaut health data: ${data.toString()}'; // Customize this response
    } else {
      return 'Failed to load health data';
    }
  }

  // Function to call ChatGPT API
  Future<String> _getChatGPTResponse(String userInput) async {
    const String apiKey = 'YOUR_API_KEY'; // Replace with your OpenAI API key
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo", // or whichever model you want to use
        "messages": [
          {"role": "user", "content": userInput}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return 'Error: ${response.statusCode} ${response.reasonPhrase}';
    }
  }

  // Function to get bot response based on user input
  Future<String> _getBotResponse(String userInput) async {
    if (userInput.toLowerCase().contains("astronaut")) {
      return await _fetchCurrentAstronauts();
    } else if (userInput.toLowerCase().contains("health")) {
      return await _fetchAstronautHealth();
    } else {
      // Call ChatGPT for other responses
      return await _getChatGPTResponse(userInput);
    }
  }

  // Function to send user input and get the bot response
  void _sendMessage(String text) async {
    if (text.isEmpty) return;
    setState(() {
      messages.add({"user": text});
    });

    String botResponse = await _getBotResponse(text);
    setState(() {
      messages.add({"bot": botResponse});
    });
    _controller.clear();  // Clear the text field after sending
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatBot"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUserMessage = message.containsKey("user");

                return Align(
                  alignment:
                  isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.orange[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUserMessage ? message["user"]! : message["bot"]!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
