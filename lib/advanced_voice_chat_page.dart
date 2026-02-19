import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      create: (context) =>
          VoiceChatBloc(apiService: ApiService())..add(StartListeningEvent()),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Waves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.33,
            child: const _WavefrontAnimation(),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Samsung AI Assistant",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Indicator
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.equalizer,
                                color: Colors.white, size: 16)
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                                duration: 500.ms,
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2))
                            .then()
                            .scale(
                                duration: 500.ms,
                                begin: const Offset(1.2, 1.2),
                                end: const Offset(0.8, 0.8)),
                        const SizedBox(width: 8),
                        const Text(
                          "Live",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Chat Area (Log Style)
                Expanded(
                  child: BlocConsumer<VoiceChatBloc, VoiceChatState>(
                    listener: (context, state) => _scrollToBottom(),
                    builder: (context, state) {
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        itemCount: state.messages.length +
                            (state.currentAiResponse.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          final isLast = index ==
                              state.messages.length +
                                  (state.currentAiResponse.isNotEmpty ? 1 : 0) -
                                  1;
                          if (index < state.messages.length) {
                            final msg = state.messages[index];
                            return _LogEntry(
                                text: msg.text,
                                isUser: msg.isUser,
                                isLast: isLast);
                          } else {
                            return _LogEntry(
                                text: state.currentAiResponse,
                                isUser: false,
                                isLast: true);
                          }
                        },
                      );
                    },
                  ),
                ),

                // Status Indicators
                BlocBuilder<VoiceChatBloc, VoiceChatState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Floating Indicator (Left): Listening
                          if (state.status == VoiceChatStatus.listening)
                            const Row(
                              children: [
                                Text(
                                  "Listening...",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 16),
                                ),
                                SizedBox(width: 4),
                                _DotIndicator(),
                              ],
                            )
                          else
                            const SizedBox.shrink(),

                          // Floating Indicator (Right): Processing Pulse
                          if (state.status == VoiceChatStatus.processing)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.cyanAccent.withOpacity(0.5),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .scale(
                                    duration: 1.5.seconds,
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.2, 1.2))
                                .fadeOut()
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    );
                  },
                ),

                // Control Bar
                const _VoiceControlBar(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isLast;

  const _LogEntry(
      {required this.text, required this.isUser, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FadeIn(
        duration: 400.ms,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? "You:" : "Samsung AI:",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.white,
                fontSize: 18,
                fontStyle: isUser ? FontStyle.italic : FontStyle.normal,
                fontWeight: isUser ? FontWeight.w400 : FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceControlBar extends StatelessWidget {
  const _VoiceControlBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceChatBloc, VoiceChatState>(
      builder: (context, state) {
        final isListening = state.status == VoiceChatStatus.listening;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlIconButton(
                  icon: Icons.videocam_outlined, onPressed: () {}),
              _ControlIconButton(
                  icon: Icons.present_to_all_outlined, onPressed: () {}),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isListening) {
                    context.read<VoiceChatBloc>().add(StopListeningEvent());
                  } else {
                    context.read<VoiceChatBloc>().add(StartListeningEvent());
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? Colors.blueAccent : Colors.white12,
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              _ControlIconButton(
                icon: Icons.close,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                backgroundColor: Colors.redAccent,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _ControlIconButton(
      {required this.icon, required this.onPressed, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      iconSize: 28,
      padding: const EdgeInsets.all(12),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      icon: Icon(icon),
    );
  }
}

class _WavefrontAnimation extends StatefulWidget {
  const _WavefrontAnimation();

  @override
  State<_WavefrontAnimation> createState() => _WavefrontAnimationState();
}

class _WavefrontAnimationState extends State<_WavefrontAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(_controller.value),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;

  _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep Navy to Vibrant Cyan Gradient
    final Gradient baseGradient = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Color(0xFF001F3F), // Deep Navy
        Color(0xFF00BFFF), // Vibrant Cyan
      ],
    );

    final paint1 = Paint()
      ..shader = baseGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.4); // For blending

    final paint2 = Paint()
      ..shader = baseGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.3);

    final paint3 = Paint()
      ..shader = baseGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.5);

    final paint4 = Paint()
      ..shader = baseGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.2);

    _drawWave(canvas, size, paint2, 0.4, 1.2, progress);
    _drawWave(canvas, size, paint4, 0.3, 1.5, progress + 0.2);
    _drawWave(canvas, size, paint1, 0.2, 1.1, progress + 0.4);
    _drawWave(canvas, size, paint3, 0.15, 1.0, progress + 0.6);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double heightFactor,
      double speedFactor, double offset) {
    final path = Path();
    final waveAmplitude = size.height * heightFactor;
    final baseHeight = size.height * 0.4;

    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight +
          math.sin((x / size.width * 2 * math.pi) +
                  (offset * 2 * math.pi * speedFactor)) *
              waveAmplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: (index * 200).ms, duration: 400.ms)
            .fadeOut(delay: (index * 200).ms, duration: 400.ms);
      }),
    );
  }
}
