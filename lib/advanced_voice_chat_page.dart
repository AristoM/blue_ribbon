import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:blue_ribbon/bloc/voice_chat/voice_chat_bloc.dart';
import 'package:blue_ribbon/bloc/voice_chat/voice_chat_event.dart';
import 'package:blue_ribbon/bloc/voice_chat/voice_chat_state.dart';

class AdvancedVoiceChatPage extends StatelessWidget {
  final String jobId;

  const AdvancedVoiceChatPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VoiceChatBloc(apiService: ApiService())
        ..add(StartListeningEvent()), // Auto-start listening
      child: const _VoiceChatView(),
    );
  }
}

class _VoiceChatView extends StatefulWidget {
  const _VoiceChatView();

  @override
  State<_VoiceChatView> createState() => _VoiceChatViewState();
}

class _VoiceChatViewState extends State<_VoiceChatView> {
  final ScrollController _scrollController = ScrollController();

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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "AI Assistant",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Chat Area
                Expanded(
                  child: BlocConsumer<VoiceChatBloc, VoiceChatState>(
                    listener: (context, state) {
                      _scrollToBottom();
                    },
                    builder: (context, state) {
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: state.messages.length +
                            (state.currentAiResponse.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < state.messages.length) {
                            final msg = state.messages[index];
                            return _ChatBubble(
                                text: msg.text, isUser: msg.isUser);
                          } else {
                            // Current streaming AI response
                            return _ChatBubble(
                                text: state.currentAiResponse, isUser: false);
                          }
                        },
                      );
                    },
                  ),
                ),
                // Live Transcript Overlay
                BlocBuilder<VoiceChatBloc, VoiceChatState>(
                  builder: (context, state) {
                    if (state.status == VoiceChatStatus.listening &&
                        state.currentTranscript.isNotEmpty) {
                      return FadeInUp(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            state.currentTranscript,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }
                    if (state.status == VoiceChatStatus.processing) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: _ThinkingIndicator(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Mic Button
                const _MicButton(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isUser ? Colors.blueAccent : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 20),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceChatBloc, VoiceChatState>(
      builder: (context, state) {
        bool isListening = state.status == VoiceChatStatus.listening;
        bool isSpeaking = state.status == VoiceChatStatus.speaking;
        bool isProcessing = state.status == VoiceChatStatus.processing;

        return GestureDetector(
          onTap: () {
            if (isListening) {
              context.read<VoiceChatBloc>().add(StopListeningEvent());
            } else {
              context.read<VoiceChatBloc>().add(StartListeningEvent());
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isListening || isSpeaking) const _RippleAnimation(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isListening
                        ? [Colors.blue, Colors.cyan]
                        : isSpeaking
                            ? [Colors.green, Colors.lightGreen]
                            : [Colors.white24, Colors.white12],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isListening ? Colors.blue : Colors.white10)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: isProcessing
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          isListening
                              ? Icons.mic
                              : isSpeaking
                                  ? Icons.volume_up
                                  : Icons.mic_none,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RippleAnimation extends StatelessWidget {
  const _RippleAnimation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.1),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5))
        .fadeOut(duration: const Duration(seconds: 1));
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: Colors.white54,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(delay: Duration(milliseconds: index * 200))
            .fadeOut(delay: Duration(milliseconds: index * 200));
      }),
    );
  }
}
