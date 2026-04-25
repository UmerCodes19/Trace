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
  bool _isLoading = true;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final api = ref.read(apiServiceProvider);
    final results = await api.getCommentsForPost(widget.postId);
    if (mounted) {
      setState(() {
        _comments = results.map((m) => CommentModel.fromMap(m)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

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

    try {
      await api.addComment(comment.toMap());
      _commentController.clear();
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
      await _loadComments();
      AppHaptics.success();
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to post comment', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Organize comments into parent-child structure
    final parentComments = _comments.where((c) => c.parentId == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Comments (${_comments.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, 
                    size: 40, color: AppColors.textHint(context)),
                  const SizedBox(height: 12),
                  Text('No comments yet. Be the first!',
                    style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
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
                  FocusScope.of(context).requestFocus(FocusNode()); // Optional: focus text field
                },
              );
            },
          ),
        const SizedBox(height: 20),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    'Replying to $_replyToName',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
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
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                onPressed: _submitComment,
                icon: Icon(Icons.send_rounded, 
                  color: Theme.of(context).colorScheme.primary),
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
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => onReply(comment.id, comment.userName),
                      child: Text(
                        'Reply',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
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
                  padding: const EdgeInsets.only(bottom: 8.0),
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
                      const SizedBox(width: 8),
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
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reply.text,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textPrimary(context),
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
