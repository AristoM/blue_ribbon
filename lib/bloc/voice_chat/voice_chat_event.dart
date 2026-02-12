import 'package:equatable/equatable.dart';

abstract class VoiceChatEvent extends Equatable {
  const VoiceChatEvent();

  @override
  List<Object?> get props => [];
}

class StartListeningEvent extends VoiceChatEvent {}

class StopListeningEvent extends VoiceChatEvent {}

class UpdateTranscriptEvent extends VoiceChatEvent {
  final String transcript;
  final bool isFinal;

  const UpdateTranscriptEvent(this.transcript, {this.isFinal = false});

  @override
  List<Object?> get props => [transcript, isFinal];
}

class SendMessageEvent extends VoiceChatEvent {
  final String message;
  final String jobId;

  const SendMessageEvent(this.message, this.jobId);

  @override
  List<Object?> get props => [message, jobId];
}

class ReceiveChunkEvent extends VoiceChatEvent {
  final String chunk;

  const ReceiveChunkEvent(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

class StreamCompleteEvent extends VoiceChatEvent {}

class StartSpeakingEvent extends VoiceChatEvent {
  final String text;

  const StartSpeakingEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class FinishSpeakingEvent extends VoiceChatEvent {}

class ErrorEvent extends VoiceChatEvent {
  final String message;

  const ErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ResetEvent extends VoiceChatEvent {}
