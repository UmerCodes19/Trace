import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  Timer? _pollingTimer;
  bool _isLoading = true;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) _loadComments(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool isPolling = false}) async {
    final api = ref.read(apiServiceProvider);
    final results = await api.getCommentsForPost(widget.postId);
    if (mounted) {
      if (isPolling && results.length == _comments.length) return;
      setState(() {
        _comments = results.map((m) => CommentModel.fromMap(m)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null || text.isEmpty) return;

    final api = ref.read(apiServiceProvider);
    final comment = CommentModel(
      id: const Uuid().v4(),
      postId: widget.postId,
      userId: user.uid,
      userName: user.name,
      userAvatarUrl: user.photoURL ?? '',
      text: text,
      parentId: _replyToId,
      timestamp: DateTime.now(),
    );

    final oldComments = List<CommentModel>.from(_comments);
    setState(() {
      _comments = [comment, ..._comments]; // Prepend new comments for better UX
      _replyToId = null;
      _replyToName = null;
    });
    _commentController.clear();
    AppHaptics.success();

    try {
      await api.addComment(comment.toMap());
    } catch (e) {
      setState(() {
        _comments = oldComments;
      });
      if (mounted) showAppSnack(context, 'Failed to post comment', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Organize comments into parent-child structure
    final parentComments = _comments.where((c) => c.parentId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments (${_comments.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Add a comment directly at the TOP for quick access
        _buildInputArea(),

        const SizedBox(height: 16),

        if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, 
                    size: 34, color: AppColors.textHint(context)),
                  const SizedBox(height: 10),
                  Text('No comments yet. Be the first!',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parentComments.length,
            itemBuilder: (context, index) {
              final parent = parentComments[index];
              final replies = _comments.where((c) => c.parentId == parent.id).toList();
              
              return _CommentTile(
                comment: parent,
                replies: replies,
                onReply: (id, name) {
                  setState(() {
                    _replyToId = id;
                    _replyToName = name;
                  });
                  FocusScope.of(context).requestFocus(FocusNode()); // Focus if needed
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Text(
                    'Replying to $_replyToName',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.jadePrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyToId = null;
                      _replyToName = null;
                    }),
                    child: const Icon(Icons.close_rounded, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: GoogleFonts.inter(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts or ask a question...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.jadePrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.onReply,
  });

  final CommentModel comment;
  final List<CommentModel> replies;
  final Function(String, String) onReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.userAvatarUrl.isNotEmpty
                    ? NetworkImage(comment.userAvatarUrl)
                    : null,
                child: comment.userAvatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppDateUtils.timeAgo(comment.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary(context).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.text,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary(context).withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => onReply(comment.id, comment.userName),
                      child: Text(
                        'Reply',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.jadePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: Column(
                children: replies.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: reply.userAvatarUrl.isNotEmpty
                            ? NetworkImage(reply.userAvatarUrl)
                            : null,
                        child: reply.userAvatarUrl.isEmpty
                            ? const Icon(Icons.person_rounded, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reply.userName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppDateUtils.timeAgo(reply.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.textSecondary(context).withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reply.text,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textPrimary(context).withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
