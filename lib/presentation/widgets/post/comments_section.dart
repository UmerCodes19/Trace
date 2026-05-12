import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../common/user_avatar.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

    _commentController.clear();
    AppHaptics.success();
    
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });

    try {
      await api.addComment(comment.toMap());
      // Force Riverpod cache invalidation to trigger refresh on ALL widgets watching this post's comments instantly!
      ref.invalidate(commentsProvider(widget.postId));
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to post comment', isError: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return commentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('Failed to load comments: $err')),
      ),
      data: (rawList) {
        final comments = rawList.map((m) => CommentModel.fromMap(m)).toList();
        final parentComments = comments.where((c) => c.parentId == null).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments (${comments.length})',
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
            
            // DOCKED COMMENT SYSTEM ACTIVE: 
            // We moved this input to the Scaffold Persistent Bottom Navigation Bar 
            // to remove redundancy and fulfill user request for immediate interaction.
            const SizedBox(height: 4), 

            
            if (comments.isEmpty)

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
                  final replies = comments.where((c) => c.parentId == parent.id).toList();
                  
                  return _CommentTile(
                    comment: parent,
                    replies: replies,
                    onReply: (id, name) {
                      ref.read(activeReplyProvider.notifier).state = ActiveReply(commentId: id, userName: name);
                      HapticFeedback.lightImpact();
                    },

                  );
                },
              ),
          ],
        );
      },
    );
  }


  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Replying to $_replyToName',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyToId = null;
                      _replyToName = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: AppColors.surface(context), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.only(left: 16, right: 6, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border(context).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint(context)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_upward_rounded, color: AppColors.pageBg(context), size: 20),
                  ),
                ),
              ],
            ),
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
    return Dismissible(
      key: Key('comment_${comment.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.jadePrimary.withOpacity(0.1),
        child: Icon(Icons.reply_rounded, color: AppColors.jadePrimary, size: 22),
      ),
      confirmDismiss: (direction) async {
        onReply(comment.id, comment.userName);
        return false; // Do not remove tile!
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

              UserAvatar(
                photoURL: comment.userAvatarUrl,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cleanCMSUsername(comment.userName),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      UserAvatar(
                        photoURL: reply.userAvatarUrl,
                        radius: 12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    cleanCMSUsername(reply.userName),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
    ),
    );
  }
}

