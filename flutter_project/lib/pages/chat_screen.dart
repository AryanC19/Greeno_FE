import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../services/api_service.dart';
import '../widgets/gradient_app_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late FlutterTts flutterTts;
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _ttsEnabled = true;

  // Speech-to-text variables
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastError = '';
  late AnimationController _micAnimationController;
  late Animation<double> _micScaleAnimation;
  late Animation<double> _micOpacityAnimation;

  // Theming (aligned with onboarding / care plan)
  final Color gradientStart = const Color(0xFF1E88E5); // primary blue
  final Color gradientEnd = const Color(0xFF2EAD6D); // accent green
  final Color softBg = const Color(0xFFF8FAFE);

  // Static list to persist chat across navigation
  static final List<ChatMessage> _messages = [];
  static bool _hasWelcomeMessage = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initializeTts();
    // Initialize animation controller for microphone button
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _micScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));

    _micOpacityAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize speech recognition
    _initSpeech();

    if (!_hasWelcomeMessage) {
      _messages.clear();
      final welcomeMessage = "👋 Hi! I'm Greeno, your AI care assistant.\n\nI can help you with: \n• 💊 Medications – mark doses as taken or not taken\n• 📅 Appointments – confirm or decline upcoming visits\n• 📝 Care plan questions – meds, schedules, reminders\n• 🥗 Diet & 🏋️ Exercise guidance (general info)\n\nJust type your question or tap the 🎤 mic to start.";

      _messages.add(
        ChatMessage(
          text: welcomeMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _hasWelcomeMessage = true;
      // Speak welcome message after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_ttsEnabled) _speak(welcomeMessage);
        });
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.2); // Slightly higher pitch for friendly voice
    await flutterTts.setSpeechRate(0.5); // Slower rate for clarity

    // Set error handler
    flutterTts.setErrorHandler((message) {
      print('TTS Error: $message');
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    });
  }

  /// Initialize speech recognition - this only needs to happen once per app session
  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (!_speechEnabled) {
        _lastError = 'Speech recognition not available on this device';
      }
    } catch (e) {
      _lastError = 'Failed to initialize speech recognition: $e';
      _speechEnabled = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    if (mounted) {
      setState(() {
        _isListening = status == 'listening';
      });

      if (status == 'listening') {
        _micAnimationController.repeat(reverse: true);
      } else {
        _micAnimationController.stop();
        _micAnimationController.reset();
      }

      // Auto-restart if speech stopped due to timeout but user didn't manually stop
      if (status == 'done' && _isListening) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isLoading) {
            _startListening();
          }
        });
      }
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    if (mounted) {
      setState(() {
        _lastError = error.toString();
        _isListening = false;
      });
      _micAnimationController.stop();
      _micAnimationController.reset();

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech recognition error: ${error.errorMsg ?? error.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Start listening for speech input
  void _startListening() async {
    if (!_speechEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Speech recognition not available. Please check permissions.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () {
              // Could open app settings here if needed
            },
          ),
        ),
      );
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'en_US',
        // Extended timeout settings for longer speech sessions
        listenFor: const Duration(seconds: 30), // Maximum listening duration
        pauseFor: const Duration(seconds: 6), // Wait 6 seconds after silence before stopping
        // Optional: Enable sound on Android devices
        onSoundLevelChange: null, // Disable sound level monitoring for better performance
      );
      setState(() {
        _isListening = true;
        _lastError = '';
      });
    } catch (e) {
      setState(() {
        _lastError = 'Failed to start listening: $e';
        _isListening = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start listening: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Stop listening for speech input
  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      _micAnimationController.stop();
      _micAnimationController.reset();
    } catch (e) {
      setState(() {
        _lastError = 'Failed to stop listening: $e';
        _isListening = false;
      });
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _messageController.text = result.recognizedWords;
        // Move cursor to end of text
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
      });
    }
  }

  /// Toggle speech recognition on/off
  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.sendChatMessage(text);
      if (!mounted) return;
      final assistantMessage = (response != null && response.isNotEmpty)
          ? response
          : "I'm sorry, I couldn't process that right now. Please try again shortly.";

      setState(() {
        _messages.add(ChatMessage(
          text: assistantMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();

      // Automatically speak Greeno's response
      if (_ttsEnabled) {
        await _speak(assistantMessage);
      }
    } catch (_) {
      if (!mounted) return;
      final errorMessage = "I'm having trouble connecting. Please check your connection and retry.";
      setState(() {
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();

      // Speak error message too
      if (_ttsEnabled) {
        await _speak(errorMessage);
      }
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Chat cleared. I'm here whenever you need me again.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  /// Clean text for TTS by removing emojis and unnecessary formatting
  String _cleanTextForTTS(String text) {
    // More comprehensive emoji removal - covers all major emoji ranges
    String cleaned = text
        // Basic emoticons and smileys
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '')
        // Miscellaneous symbols and pictographs
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '')
        // Transport and map symbols
        .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '')
        // Regional indicator symbols (flags)
        .replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), '')
        // Miscellaneous symbols
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
        // Dingbats
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
        // Supplemental symbols and pictographs
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '')
        // Additional symbols and arrows
        .replaceAll(RegExp(r'[\u{2190}-\u{21FF}]', unicode: true), '')
        // Mathematical operators
        .replaceAll(RegExp(r'[\u{2200}-\u{22FF}]', unicode: true), '')
        // Miscellaneous technical
        .replaceAll(RegExp(r'[\u{2300}-\u{23FF}]', unicode: true), '')
        // Additional miscellaneous symbols
        .replaceAll(RegExp(r'[\u{2B00}-\u{2BFF}]', unicode: true), '')
        // Remove any remaining emoji-like characters
        .replaceAll(RegExp(r'[👋💊📅📝🥗🏋️🎤]'), ''); // Specific emojis from your welcome message

    // Clean up bullet points and add pauses for better TTS
    cleaned = cleaned.replaceAll('•', '. '); // Replace bullet with period and space for pause

    // Add longer pauses after newlines for better speech flow
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*'), '. '); // Replace newlines with periods for pauses

    // Clean up multiple periods and spaces
    cleaned = cleaned.replaceAll(RegExp(r'\.{2,}'), '.'); // Remove multiple periods
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

    // Add pause after colons for better list reading
    cleaned = cleaned.replaceAll(':', ': ');

    return cleaned.trim();
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) return;

    try {
      // Stop any current speech
      await flutterTts.stop();

      setState(() {
        _isSpeaking = true;
      });

      // Clean the text for TTS
      String cleanText = _cleanTextForTTS(text);

      // Ensure we have something to speak
      if (cleanText.isEmpty) {
        setState(() {
          _isSpeaking = false;
        });
        return;
      }

      print('TTS speaking: $cleanText'); // Debug log

      await flutterTts.setLanguage("en-US");

      // Try to set a voice, but don't fail if it's not available
      try {
        // Get available voices first
        List<dynamic> voices = await flutterTts.getVoices;

        // Look for a suitable English voice
        var englishVoices = voices.where((voice) =>
          voice['locale'].toString().startsWith('en')).toList();

        if (englishVoices.isNotEmpty) {
          // Use the first available English voice
          await flutterTts.setVoice({
            "name": englishVoices.first['name'],
            "locale": englishVoices.first['locale']
          });
        }
      } catch (voiceError) {
        print('Voice setting failed, using default: $voiceError');
        // Continue with default voice
      }

      await flutterTts.setPitch(1.2); // Friendly pitch
      await flutterTts.setSpeechRate(0.5); // Clear speech rate

      // Speak the cleaned text
      await flutterTts.speak(cleanText);

    } catch (e) {
      print('TTS Error: $e');
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: buildGradientAppBar(
        titleWidget: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(90), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/greeno.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.android, color: Colors.white.withAlpha(230), size: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Greeno Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: .3,
                    ),
                  ),
                  if (_isSpeaking)
                    Text(
                      'Speaking...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(200),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // TTS Toggle Button
            IconButton(
              onPressed: () {
                setState(() {
                  _ttsEnabled = !_ttsEnabled;
                });
                if (!_ttsEnabled) {
                  flutterTts.stop();
                }
              },
              icon: Icon(
                _ttsEnabled ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        actionIcon: Icons.delete_outline,
        onAction: _messages.isEmpty ? null : _clearChat,
        gradientStart: gradientStart,
        gradientEnd: gradientEnd,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) return _buildTypingIndicator();
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _greenoAvatar(size: 30),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gradientStart.withAlpha(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(gradientStart),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Greeno is thinking…',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool user = message.isUser;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(user ? 20 : 4),
      bottomRight: Radius.circular(user ? 4 : 20),
    );

    final Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: user
            ? LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: user ? null : Colors.white,
        borderRadius: borderRadius,
        border: user ? null : Border.all(color: gradientStart.withAlpha(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontSize: 15.5,
              color: user ? Colors.white : Colors.black87,
              height: 1.35,
              fontWeight: user ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (!user && _ttsEnabled) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Stop button
                GestureDetector(
                  onTap: () async {
                    await flutterTts.stop();
                    setState(() {
                      _isSpeaking = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.stop,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Speaker/Play button
                GestureDetector(
                  onTap: () => _speak(message.text),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: gradientStart.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.volume_up,
                      size: 16,
                      color: gradientStart,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!user) ...[
            _greenoAvatar(size: 30),
            const SizedBox(width: 10),
          ],
          Flexible(child: bubble),
          if (user) ...[
            const SizedBox(width: 10),
            _userAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _greenoAvatar({double size = 32}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
          boxShadow: [
            BoxShadow(
              color: gradientStart.withAlpha(70),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/greeno.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.android, color: Colors.white, size: 20),
          ),
        ),
      );

  Widget _userAvatar() => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: gradientStart.withAlpha(160), width: 2),
          gradient: LinearGradient(colors: [gradientEnd, gradientStart]),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 18),
      );

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator for speech recognition
            if (_isListening || (!_speechEnabled && _lastError.isNotEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _isListening
                      ? gradientStart.withAlpha(20)
                      : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isListening
                        ? gradientStart.withAlpha(60)
                        : Colors.orange.withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isListening) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(gradientStart),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Listening... Tap mic to stop',
                        style: TextStyle(
                          fontSize: 13,
                          color: gradientStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastError.contains('not available')
                              ? 'Speech recognition not available'
                              : 'Speech recognition error',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Input row with text field, mic button, and send button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: gradientStart.withAlpha(35)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isLoading && !_isListening, // Disable while listening
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening for your voice...'
                            : 'Ask about medications, appointments, or your plan...',
                        hintStyle: TextStyle(
                          color: _isListening ? gradientStart.withAlpha(150) : Colors.grey,
                          fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _isListening ? null : _sendMessage(),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildMicrophoneButton(),
                const SizedBox(width: 8),
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build animated microphone button with speech recognition functionality
  Widget _buildMicrophoneButton() {
    return AnimatedBuilder(
      animation: _micAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _micScaleAnimation.value : 1.0,
          child: Opacity(
            opacity: _isListening ? _micOpacityAnimation.value : 1.0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isListening
                    ? LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade600,
                        ],
                      )
                    : LinearGradient(
                        colors: _speechEnabled
                            ? [gradientStart.withAlpha(200), gradientEnd.withAlpha(200)]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? Colors.red.withAlpha(60)
                        : gradientStart.withAlpha(40),
                    blurRadius: _isListening ? 12 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _speechEnabled && !_isLoading ? _toggleListening : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 24,
                      semanticLabel: _isListening
                          ? 'Stop listening'
                          : _speechEnabled
                              ? 'Start voice input'
                              : 'Voice input not available',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: (_isLoading || _isListening)
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [gradientStart, gradientEnd]
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: (_isLoading || _isListening) ? null : _sendMessage,
        icon: Icon(
          _isLoading ? Icons.hourglass_empty : Icons.send,
          color: Colors.white,
        ),
        tooltip: _isListening
            ? 'Cannot send while listening'
            : _isLoading
                ? 'Sending message...'
                : 'Send message',
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    flutterTts.stop();
    _micAnimationController.dispose();
    super.dispose();
  }

  static void clearChatHistory() {
    _messages.clear();
    _hasWelcomeMessage = false;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
