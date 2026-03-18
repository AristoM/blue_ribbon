import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'data/services/api_service.dart';
import 'advanced_voice_chat_page.dart';

class JobChatPage extends StatefulWidget {
  final String jobId;
  const JobChatPage({super.key, required this.jobId});

  @override
  State<JobChatPage> createState() => _JobChatPageState();
}

class _JobChatPageState extends State<JobChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    await _loadHistory();
    if (_messages.isEmpty) {
      _addInitialMessage();
    }
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            "Welcome! How can I help you find the perfect Samsung installation support? Feel free to describe what you're looking for.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? history = prefs.getString('job_chat_history_${widget.jobId}');
    if (history != null) {
      final List<dynamic> decoded = jsonDecode(history);
      setState(() {
        _messages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
        _showSuggestions = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString('job_chat_history_${widget.jobId}', encoded);
  }

  void _sendMessage({String? text}) {
    final String userText = text ?? _controller.text.trim();
    if (userText.isEmpty) return;

    final userMessage = ChatMessage(
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _showSuggestions = false;
    });
    _saveHistory();
    _scrollToBottom();
    _controller.clear();

    // Bot Response Logic (Mock)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _handleBotResponse(userText);
      }
    });
  }

  void _handleBotResponse(String userText) async {
    ChatMessage? currentBotMessage;
    ChatMessage? statusMessage;

    // Improved status handling
    void setStatus(String text) {
      setState(() {
        // Remove old status message if it exists
        _messages.remove(statusMessage);
        
        statusMessage = ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          type: ChatMessageType.text,
        );
        _messages.add(statusMessage!);
      });
      _scrollToBottom();
    }

    void removeStatus() {
      if (statusMessage != null) {
        setState(() {
          _messages.remove(statusMessage);
          statusMessage = null;
        });
      }
    }

    try {
      final stream = ApiService().streamJobChat(widget.jobId, userText);
      
      await for (final chunk in stream) {
        if (!mounted) break;

        final type = chunk['type'];
        final payload = chunk['payload'] ?? {};

        if (type == 'status') {
          setStatus(payload['message'] ?? "Processing...");
        } else if (type == 'md_content') {
          removeStatus();
          final content = payload['content'] ?? "";
          
          setState(() {
            if (currentBotMessage == null) {
              currentBotMessage = ChatMessage(
                text: content,
                isUser: false,
                timestamp: DateTime.now(),
                type: ChatMessageType.markdown,
              );
              _messages.add(currentBotMessage!);
            } else {
              // Append to existing message
              int index = _messages.indexOf(currentBotMessage!);
              currentBotMessage = ChatMessage(
                text: currentBotMessage!.text + content,
                isUser: false,
                timestamp: currentBotMessage!.timestamp,
                type: ChatMessageType.markdown,
              );
              if (index != -1) {
                _messages[index] = currentBotMessage!;
              }
            }
          });
          _scrollToBottom();
        } else if (type == 'widget') {
          removeStatus();
          final elements = payload['elements'] ?? {};
          final optionsData = elements['options'] as List? ?? [];
          final options = optionsData.map((opt) => opt['label'] as String).toList();
          
          setState(() {
            _messages.add(ChatMessage(
              text: elements['question'] ?? payload['title'] ?? "Please select:",
              isUser: false,
              timestamp: DateTime.now(),
              type: ChatMessageType.radio,
              options: options,
            ));
          });
          _scrollToBottom();
        } else if (type == '[done]') {
          removeStatus();
          // Handle sources if available in payload
          final List<dynamic> sources = payload['sources'] ?? [];
          if (sources.isNotEmpty) {
            String sourcesText = "\n\n**Sources:**\n" + sources.map((s) => "- ${s['label']}").join("\n");
             setState(() {
               if (currentBotMessage != null) {
                 int index = _messages.indexOf(currentBotMessage!);
                 currentBotMessage = ChatMessage(
                   text: currentBotMessage!.text + sourcesText,
                   isUser: false,
                   timestamp: currentBotMessage!.timestamp,
                   type: ChatMessageType.markdown,
                 );
                 if (index != -1) {
                   _messages[index] = currentBotMessage!;
                 }
               } else {
                  _messages.add(ChatMessage(
                    text: sourcesText,
                    isUser: false,
                    timestamp: DateTime.now(),
                    type: ChatMessageType.markdown,
                  ));
               }
             });
          }
        } else if (type == 'error') {
          removeStatus();
          _addErrorMessage(payload['message'] ?? "An error occurred");
        }
      }
    } catch (e) {
      removeStatus();
      _addErrorMessage("An error occurred: $e");
    }

    _saveHistory();
    _scrollToBottom();
  }

  void _addErrorMessage(String error) {
    setState(() {
      _messages.add(ChatMessage(
        text: error,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Samsung Installation Assistant",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Job ID: ${widget.jobId}",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_showSuggestions ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildSuggestions();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      "What tools do I need?",
      "What parts are missing?",
      "Installation requirements"
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: () => _sendMessage(text: suggestion),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: Colors.grey[200]!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child:
              Text(message.text, style: const TextStyle(color: Colors.white)),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 16,
              child: Text("AI",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: message.type == ChatMessageType.markdown
                        ? MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  height: 1.4),
                            ),
                          )
                        : Text(message.text,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                height: 1.4)),
                  ),
                  if (message.type != ChatMessageType.text &&
                      message.type != ChatMessageType.markdown)
                    _buildWidget(message),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWidget(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.radio:
        return _buildRadioWidget(message);
      case ChatMessageType.checkbox:
        return _buildCheckboxWidget(message);
      case ChatMessageType.dropdown:
        return _buildDropdownWidget(message);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRadioWidget(ChatMessage message) {
    if (message.selectedValue != null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.options!.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                setState(() => message.selectedValue = opt);
                _sendMessage(text: opt);
              },
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: Colors.grey[200]!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                opt,
                style: const TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckboxWidget(ChatMessage message) {
    if (message.isSubmitted) return const SizedBox.shrink();
    message.selectedValues ??= [];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          ...message.options!.map((opt) {
            return CheckboxListTile(
              title: Text(opt),
              value: message.selectedValues!.contains(opt),
              onChanged: (val) {
                setState(() {
                  if (val!) {
                    message.selectedValues!.add(opt);
                  } else {
                    message.selectedValues!.remove(opt);
                  }
                });
              },
            );
          }),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() => message.isSubmitted = true);
                _sendMessage(
                    text: "Submitted: ${message.selectedValues!.join(', ')}");
              },
              child: const Text("Submit Selection"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDropdownWidget(ChatMessage message) {
    if (message.isSubmitted) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Select an option"),
          value: message.selectedValue,
          items: message.options!.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              message.selectedValue = val;
              message.isSubmitted = true;
            });
            _sendMessage(text: "I selected: $val");
          },
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.mic, color: Colors.white, size: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AdvancedVoiceChatPage(jobId: widget.jobId)),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ask about tools, parts, or insta...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text("Send",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ChatMessageType { text, radio, checkbox, dropdown, markdown }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final List<String>? options;
  String? selectedValue;
  List<String>? selectedValues;
  bool isSubmitted;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.options,
    this.selectedValue,
    this.selectedValues,
    this.isSubmitted = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
        'options': options,
        'selectedValue': selectedValue,
        'selectedValues': selectedValues,
        'isSubmitted': isSubmitted,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        type: ChatMessageType.values[json['type'] ?? 0],
        options:
            json['options'] != null ? List<String>.from(json['options']) : null,
        selectedValue: json['selectedValue'],
        selectedValues: json['selectedValues'] != null
            ? List<String>.from(json['selectedValues'])
            : null,
        isSubmitted: json['isSubmitted'] ?? false,
      );
}
