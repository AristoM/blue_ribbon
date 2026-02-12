import 'package:equatable/equatable.dart';

enum VoiceChatStatus { idle, listening, processing, speaking, error }

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp];
}

class VoiceChatState extends Equatable {
  final VoiceChatStatus status;
  final List<ChatMessage> messages;
  final String currentTranscript;
  final String currentAiResponse;
  final String? errorMessage;

  const VoiceChatState({
    this.status = VoiceChatStatus.idle,
    this.messages = const [],
    this.currentTranscript = '',
    this.currentAiResponse = '',
    this.errorMessage,
  });

  VoiceChatState copyWith({
    VoiceChatStatus? status,
    List<ChatMessage>? messages,
    String? currentTranscript,
    String? currentAiResponse,
    String? errorMessage,
  }) {
    return VoiceChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      currentAiResponse: currentAiResponse ?? this.currentAiResponse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        currentTranscript,
        currentAiResponse,
        errorMessage,
      ];
}
