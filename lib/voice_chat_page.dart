import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _transcript = "Tap the mic to start speaking...";
  String _aiResponse = "";
  bool _isAILoading = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initSpeech();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future _speak(String text) async {
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future _stopTts() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  /// This has to happen only once per app
  Future _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('STT Error: $error');
          if (!mounted) return;
          setState(() {
            _transcript = "Error: $error";
            _isListening = false;
            _controller.stop();
          });
        },
        onStatus: (status) {
          print('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (!mounted) return;
            if (_isListening) {
              _stopListening();
            }
          }
        },
      );
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('STT Init Exception: $e');
    }
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    // Stop TTS if speaking
    await _stopTts();

    var status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    if (status.isDenied) {
      setState(() => _transcript = "Microphone permission denied");
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        setState(() => _transcript = "Speech recognition not available");
        return;
      }
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
      );
      if (mounted) {
        setState(() {
          _isListening = true;
          _aiResponse = "";
          _transcript = "Listening...";
          _controller.repeat();
        });
      }
    } catch (e) {
      print('Listen Exception: $e');
    }
  }

  /// Manually stop the speech recognition session
  void _stopListening() async {
    if (!_isListening) return; // Prevent double trigger

    await _speechToText.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
        _controller.stop();
      });
    }

    // Valid transcript?
    String cleanedTranscript = _transcript.trim();
    if (cleanedTranscript.isNotEmpty &&
        cleanedTranscript != "Tap the mic to start speaking..." &&
        cleanedTranscript != "Listening..." &&
        !cleanedTranscript.startsWith("Error")) {
      _sendToAI(cleanedTranscript);
    }
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _transcript = result.recognizedWords;
    });
    if (result.finalResult && _isListening) {
      _stopListening();
    }
  }

  Future<void> _sendToAI(String message) async {
    if (_isAILoading) return;

    setState(() {
      _isAILoading = true;
      _aiResponse = "Thinking...";
    });

    try {
      final response =
          await ApiService().sendChatMessage(message, "CONV-JOB-001");

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success']) {
        String aiText = response.data['data']['response'];
        setState(() {
          _aiResponse = aiText;
          _isAILoading = false;
        });
        _speak(aiText);
      } else {
        setState(() {
          _aiResponse = "Failed to get a response from the assistant.";
          _isAILoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiResponse = "An error occurred: $e";
        _isAILoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Voice Chat", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const Spacer(),
          // Animated Pulse
          Center(
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _isListening
                              ? Colors.red.withOpacity(0.8)
                              : Colors.blue.withOpacity(0.8),
                          _isListening
                              ? Colors.orange.withOpacity(0.4)
                              : Colors.purple.withOpacity(0.4),
                          Colors.transparent,
                        ],
                        stops: [
                          0.1 + (_controller.value * 0.2),
                          0.5 + (_controller.value * 0.4),
                          1.0
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isListening
                            ? Icons.stop
                            : _isSpeaking
                                ? Icons.volume_up
                                : Icons.mic,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          // Transcript and Response Area
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "You",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcript,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    if (_aiResponse.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            "Assistant",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                          if (_isSpeaking) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiResponse,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                    if (_isAILoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                    const SizedBox(height: 40),
                    Text(
                      _isListening
                          ? "Listening..."
                          : (_isSpeaking
                              ? "Tap to interrupt"
                              : "Tap the microphone to ask a question"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
