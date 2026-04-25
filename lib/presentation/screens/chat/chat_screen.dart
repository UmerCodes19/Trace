import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_chat_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  List<SimpleMessageModel> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  String? _chatTitle;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadChatInfo();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _refreshMessages();
      }
    });
  }

  Future<void> _loadChatInfo() async {
    final api = ref.read(apiServiceProvider);
    final chat = await api.getChat(widget.chatId);
    if (chat != null && mounted) {
      setState(() {
        _chatTitle = chat['postTitle'] ?? 'Chat';
      });
    }
  }

  Future<void> _loadMessages() async {
    final api = ref.read(apiServiceProvider);
    final messagesList = await api.getChatMessages(widget.chatId);

    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    await api.markMessagesRead(widget.chatId, uid);

    if (mounted) {
      setState(() {
        _messages = messagesList
            .map((m) => SimpleMessageModel.fromMap(m))
            .toList();
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _refreshMessages() async {
    if (!mounted) return;

    final api = ref.read(apiServiceProvider);
    final messagesList = await api.getChatMessages(widget.chatId);
    final newMessages = messagesList
        .map((m) => SimpleMessageModel.fromMap(m))
        .toList();

    if (newMessages.length != _messages.length) {
      final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
      await api.markMessagesRead(widget.chatId, uid);

      setState(() {
        _messages = newMessages;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final content = text?.trim() ?? imageUrl ?? '';
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    final api = ref.read(apiServiceProvider);
    await api.sendMessage({
      'chatId': widget.chatId,
      'senderId': uid,
      'text': text ?? '',
      'imageUrl': imageUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    await _loadMessages();
    setState(() => _isSending = false);
  }

  Future<void> _sendImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _isSending = true);
    showAppSnack(context, 'Uploading image...');

    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadChatImage(File(picked.path), widget.chatId);
      await _sendMessage(imageUrl: url);
      showAppSnack(context, '✓ Image sent');
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Failed to upload image', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.cardBg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary(context),
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _chatTitle ?? 'Chat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            Text(
              '${_messages.length} messages',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _markReturned(),
            child: Text(
              'Returned ✓',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.foundSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface(context),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: accent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Meet in a public spot on campus (Library, Cafeteria)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: i % 2 == 0
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: SkeletonBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 40 + (i % 3) * 12,
                          radius: 18,
                        ),
                      ),
                    ),
                  )
                : _messages.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Start a Conversation',
                        subtitle:
                            'Send a message to arrange pickup\nor discuss the item.',
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMine = msg.senderId == uid;
                          final showDate =
                              i == 0 ||
                              _messages[i].timestamp.day !=
                                  _messages[i - 1].timestamp.day;

                          return Column(
                            children: [
                              if (showDate) _DateChip(date: msg.timestamp),
                              _MessageBubble(msg: msg, isMine: isMine),
                            ],
                          );
                        },
                      ),
          ),
          _InputBar(
            controller: _msgCtrl,
            isSending: _isSending,
            onSend: () => _sendMessage(text: _msgCtrl.text),
            onImage: _sendImage,
          ),
        ],
      ),
    );
  }

  Future<void> _markReturned() async {
    final api = ref.read(apiServiceProvider);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: AppColors.foundSuccess,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Item Returned!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Great! Mark this item as successfully returned?\n\nKarma points will be added to your profile.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.foundSuccess,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final chat = await api.getChat(widget.chatId);
              final postId = chat?['postId'] as String?;
              if (postId != null) {
                final post = await api.getPost(postId);
                if (post != null &&
                    (post['status'] as String? ?? 'open') != 'resolved') {
                  await api.updatePost(postId, {'status': 'resolved'});
                  final ownerId = post['userId'] as String? ?? '';
                  if (ownerId.isNotEmpty) {
                    await api.updateUserStats(ownerId, {'itemsReturned': 1});
                  }
                  if (uid.isNotEmpty && uid != ownerId) {
                    await api.updateUserStats(uid, {'karmaPoints': 50});
                  }
                }
              }
              AppHaptics.success();
              if (mounted) {
                showAppSnack(context, 'Item marked as returned');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMine});
  final SimpleMessageModel msg;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myBubbleColor = accent;
    final otherBubbleColor = AppColors.cardBg(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: msg.imageUrl != null
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMine ? myBubbleColor : otherBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
            border: isMine
                ? null
                : Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: isMine
                    ? accent.withOpacity(0.15)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (msg.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _ChatImage(url: msg.imageUrl!),
                ),
              if (msg.text.isNotEmpty)
                Text(
                  msg.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isMine
                        ? Colors.white
                        : AppColors.textPrimary(context),
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                AppDateUtils.shortTime(msg.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isMine
                      ? Colors.white.withOpacity(0.7)
                      : AppColors.textHint(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatImage extends StatelessWidget {
  const _ChatImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isRemote = url.startsWith('http://') || url.startsWith('https://');
    if (isRemote) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 220,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 220,
          height: 150,
          color: AppColors.surface(context),
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 220,
          height: 150,
          color: AppColors.surface(context),
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }

    return Image.file(
      File(url),
      width: 220,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 220,
        height: 150,
        color: AppColors.surface(context),
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Text(
          AppDateUtils.friendlyDate(date),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onImage,
  });
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onImage;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _hasText = widget.controller.text.trim().isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                10,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context).withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: AppColors.border(context),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onImage,
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: accent,
                  size: 22,
                ),
                tooltip: 'Attach image',
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textHint(context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.surface(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: (_hasText && !widget.isSending) ? widget.onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: (_hasText && !widget.isSending)
                        ? LinearGradient(
                            colors: [
                              accent,
                              HSLColor.fromColor(accent)
                                  .withHue(
                                    (HSLColor.fromColor(accent).hue + 25) % 360,
                                  )
                                  .toColor(),
                            ],
                          )
                        : null,
                    color: (_hasText && !widget.isSending)
                        ? null
                        : AppColors.surface(context),
                    shape: BoxShape.circle,
                    boxShadow: (_hasText && !widget.isSending)
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: widget.isSending
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: (_hasText && !widget.isSending)
                              ? Colors.white
                              : AppColors.textHint(context),
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
