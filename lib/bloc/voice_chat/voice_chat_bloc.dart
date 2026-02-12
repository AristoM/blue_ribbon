import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'voice_chat_event.dart';
import 'voice_chat_state.dart';

class VoiceChatBloc extends Bloc<VoiceChatEvent, VoiceChatState> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ApiService _apiService;
  StreamSubscription? _chatSubscription;

  VoiceChatBloc({required ApiService apiService})
      : _apiService = apiService,
        super(const VoiceChatState()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<UpdateTranscriptEvent>(_onUpdateTranscript);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveChunkEvent>(_onReceiveChunk);
    on<StreamCompleteEvent>(_onStreamComplete);
    on<StartSpeakingEvent>(_onStartSpeaking);
    on<FinishSpeakingEvent>(_onFinishSpeaking);
    on<ErrorEvent>(_onError);
    on<ResetEvent>(_onReset);

    _initSystems();
  }

  Future<void> _initSystems() async {
    print('VoiceChatBloc: Initializing STT and TTS...');
    await _speechToText.initialize(
      onError: (error) {
        print('VoiceChatBloc: STT Error: ${error.errorMsg}');
        add(ErrorEvent('STT Error: ${error.errorMsg}'));
      },
      onStatus: (status) {
        print('VoiceChatBloc: STT Status: $status');
        if (status == 'notListening' &&
            state.status == VoiceChatStatus.listening) {
          // Might be silence detection handled by onResult, but backup here
        }
      },
    );

    try {
      print('VoiceChatBloc: Setting up TTS...');
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      if (Platform.isIOS) {
        // Essential for iOS to play through speakers
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      } else if (Platform.isAndroid) {
        // Android specific: Use media volume by default
        await _flutterTts.setQueueMode(1); // 1 = Flush, 0 = Add
      }

      _flutterTts.setStartHandler(() {
        print('VoiceChatBloc: TTS Started');
      });

      _flutterTts.setCompletionHandler(() {
        print('VoiceChatBloc: TTS Completed');
        add(FinishSpeakingEvent());
      });

      _flutterTts.setErrorHandler((msg) {
        print('VoiceChatBloc: TTS Error: $msg');
        add(ErrorEvent('TTS Error: $msg'));
      });

      // Verification check for Android
      if (Platform.isAndroid) {
        final engines = await _flutterTts.getEngines;
        print('VoiceChatBloc: Available TTS Engines on Android: $engines');

        // Prefer Google TTS engine if available
        if (engines.contains("com.google.android.tts")) {
          await _flutterTts.setEngine("com.google.android.tts");
          print('VoiceChatBloc: Set engine to com.google.android.tts');
        } else if (engines.isNotEmpty) {
          await _flutterTts.setEngine(engines.first);
          print('VoiceChatBloc: Set engine to ${engines.first}');
        }

        final isAvailable = await _flutterTts.isLanguageAvailable("en-US");
        print('VoiceChatBloc: en-US available on Android: $isAvailable');

        if (!isAvailable) {
          print(
              'VoiceChatBloc: WARNING: en-US NOT available on this Android device');
        }
      }

      print('VoiceChatBloc: TTS Setup Complete');
    } catch (e) {
      print('VoiceChatBloc: TTS Init Exception: $e');
    }
  }

  Future<void> _onStartListening(
      StartListeningEvent event, Emitter<VoiceChatState> emit) async {
    print('VoiceChatBloc: StartListeningEvent received');
    await _flutterTts.stop();
    bool available = await _speechToText.initialize();
    if (available) {
      emit(state.copyWith(
          status: VoiceChatStatus.listening, currentTranscript: ''));
      _speechToText.listen(
        onResult: (result) {
          add(UpdateTranscriptEvent(result.recognizedWords,
              isFinal: result.finalResult));
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    } else {
      add(const ErrorEvent('Speech recognition not available'));
    }
  }

  Future<void> _onStopListening(
      StopListeningEvent event, Emitter<VoiceChatState> emit) async {
    print('VoiceChatBloc: StopListeningEvent received');
    await _speechToText.stop();
    emit(state.copyWith(status: VoiceChatStatus.idle));
  }

  void _onUpdateTranscript(
      UpdateTranscriptEvent event, Emitter<VoiceChatState> emit) {
    emit(state.copyWith(currentTranscript: event.transcript));
    if (event.isFinal && event.transcript.isNotEmpty) {
      print('VoiceChatBloc: Final transcript received: ${event.transcript}');
      add(SendMessageEvent(
          event.transcript, 'JOB-2026-5678')); // Using mock JobID
    }
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<VoiceChatState> emit) async {
    print('VoiceChatBloc: SendMessageEvent received: ${event.message}');
    emit(state.copyWith(
      status: VoiceChatStatus.processing,
      messages: List.from(state.messages)
        ..add(ChatMessage(
          text: event.message,
          isUser: true,
          timestamp: DateTime.now(),
        )),
      currentAiResponse: '',
    ));

    await _chatSubscription?.cancel();
    _chatSubscription =
        _apiService.streamJobChat(event.jobId, event.message).listen(
      (chunk) => add(ReceiveChunkEvent(chunk)),
      onDone: () {
        print('VoiceChatBloc: API Stream Complete');
        add(StreamCompleteEvent());
      },
      onError: (e) {
        print('VoiceChatBloc: API Stream Error: $e');
        add(ErrorEvent(e.toString()));
      },
    );
  }

  void _onReceiveChunk(ReceiveChunkEvent event, Emitter<VoiceChatState> emit) {
    emit(state.copyWith(
      currentAiResponse: state.currentAiResponse + event.chunk,
    ));
  }

  void _onStreamComplete(
      StreamCompleteEvent event, Emitter<VoiceChatState> emit) {
    final fullResponse = state.currentAiResponse;
    print(
        'VoiceChatBloc: StreamCompleteEvent. AI Response length: ${fullResponse.length}');
    emit(state.copyWith(
      messages: List.from(state.messages)
        ..add(ChatMessage(
          text: fullResponse,
          isUser: false,
          timestamp: DateTime.now(),
        )),
    ));
    add(StartSpeakingEvent(fullResponse));
  }

  Future<void> _onStartSpeaking(
      StartSpeakingEvent event, Emitter<VoiceChatState> emit) async {
    print(
        'VoiceChatBloc: Starting to speak: ${event.text.substring(0, event.text.length > 20 ? 20 : event.text.length)}...');

    // Explicitly ensure STT is OFF before speaking
    await _speechToText.stop();

    emit(state.copyWith(status: VoiceChatStatus.speaking));

    // Small delay to allow audio session to switch from mic to playback
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await _flutterTts.speak(event.text);
    if (result == 1) {
      print('VoiceChatBloc: speak() call successful');
    } else {
      print('VoiceChatBloc: speak() call failed with result: $result');
    }
  }

  void _onFinishSpeaking(
      FinishSpeakingEvent event, Emitter<VoiceChatState> emit) {
    emit(state.copyWith(status: VoiceChatStatus.idle, currentAiResponse: ''));
    add(StartListeningEvent()); // Auto-resume listening!
  }

  void _onError(ErrorEvent event, Emitter<VoiceChatState> emit) {
    emit(state.copyWith(
        status: VoiceChatStatus.error, errorMessage: event.message));
  }

  void _onReset(ResetEvent event, Emitter<VoiceChatState> emit) {
    emit(const VoiceChatState());
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    return super.close();
  }
}
