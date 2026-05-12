import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/ai_chat_config.dart';
import '../services/ai_chat_service.dart';
import '../services/firebase_data_service.dart';
import '../theme/app_design_system.dart';

class AIChatWidget extends StatefulWidget {
  const AIChatWidget({super.key});

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final AIChatService _chatService = AIChatService();
  final FirebaseDataService _dataService = FirebaseDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  bool _isOpen = false;
  bool _isLoading = false;
  bool _welcomeMessageShown = false;

  Future<void> _showWelcomeMessage() async {
    if (_welcomeMessageShown) {
      return;
    }

    var userName = 'Kullanici';

    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final userProfile =
              await _dataService.getUserProfile().timeout(const Duration(seconds: 3));

          final fullName = userProfile?['fullName']?.toString().trim() ?? '';
          if (fullName.isNotEmpty) {
            userName = fullName.split(' ').first;
          }
        } catch (_) {
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            userName = user.displayName!.split(' ').first;
          } else if (user.email != null) {
            userName = user.email!.split('@').first;
          }
        }
      }
    } catch (_) {}

    if (!mounted || _welcomeMessageShown) {
      return;
    }

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content':
            'Merhaba $userName!\n\nBen ${AIChatConfig.botName}. Urunler, siparis durumu ve genel sorular konusunda yardimci olabilirim.',
      });
      _welcomeMessageShown = true;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) {
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _messageFocusNode.requestFocus();
      }
    });

    try {
      final response = await _chatService.sendMessage(
        message: message,
        conversationHistory: _messages
            .where((m) => m['role'] != 'system')
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('Chat widget error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Bir hata olustu. Lutfen tekrar deneyin.',
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _messageFocusNode.canRequestFocus) {
          _messageFocusNode.requestFocus();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_isOpen)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildFloatingButton(context),
          ),
        if (_isOpen)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildChatWindow(context),
          ),
      ],
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    final colors = context.appTheme;

    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(30),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isOpen = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _messageFocusNode.requestFocus();
            }
          });
          _showWelcomeMessage();
        },
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: colors.accentGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: colors.glowShadow,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: colors.textInverse,
                  size: 28,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surfaceElevated, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow(BuildContext context) {
    final colors = context.appTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      width: isMobile ? screenWidth - 40 : 400,
      height: isMobile ? screenWidth * 0.8 : 600,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: colors.mediumShadow,
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMessagesList(context)),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: colors.accentGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.smart_toy,
              color: colors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AIChatConfig.botName,
                  style: GoogleFonts.inter(
                    color: colors.textInverse,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Cevrimici',
                  style: GoogleFonts.inter(
                    color: colors.textInverse.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textInverse),
            onPressed: () {
              setState(() {
                _isOpen = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    final colors = context.appTheme;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceInteractive,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final message = _messages[index];
        final isUser = message['role'] == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: colors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: colors.textInverse,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? colors.accent : colors.surfaceInteractive,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isUser
                          ? colors.accent.withValues(alpha: 0.42)
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: GoogleFonts.inter(
                      color: isUser ? colors.textInverse : colors.textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceInteractive,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Icon(
                    Icons.person,
                    color: colors.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final colors = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Mesajinizi yazin...',
                hintStyle: GoogleFonts.inter(
                  color: colors.textMuted,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.accent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: colors.inputFill,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isLoading ? colors.borderStrong : colors.accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.send,
                  color: colors.textInverse,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
