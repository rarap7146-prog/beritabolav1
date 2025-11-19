import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class CommentSection extends StatefulWidget {
  final int articleId;

  const CommentSection({
    Key? key,
    required this.articleId,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputKey = GlobalKey();
  bool _isPosting = false;
  String? _replyingTo; // Comment ID being replied to
  int _replyLevel = 0;
  String _replyingToName = '';

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Silakan login untuk berkomentar')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty || text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar minimal 3 karakter'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await _firestoreService.postComment(
        articleId: widget.articleId,
        content: text,
        parentId: _replyingTo,
        level: _replyLevel,
      );

      _commentController.clear();
      setState(() {
        _replyingTo = null;
        _replyLevel = 0;
        _replyingToName = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Komentar berhasil diposting'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memposting komentar: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _setReply(String commentId, int level, String userName) {
    setState(() {
      _replyingTo = commentId;
      _replyLevel = level + 1;
      _replyingToName = userName;
    });
    
    // Scroll to input and focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inputKey.currentContext != null) {
        Scrollable.ensureVisible(
          _inputKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0, // Align to top
        );
      }
      // Focus the text field
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyLevel = 0;
      _replyingToName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Komentar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),

        // Comment Input
        Container(
          key: _inputKey,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply indicator
              if (_replyingTo != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Membalas $_replyingToName',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _cancelReply,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Text field
              TextField(
                controller: _commentController,
                maxLines: 3,
                enabled: !_isPosting,
                decoration: InputDecoration(
                  hintText: 'Tulis komentar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  suffixIcon: _isPosting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _postComment,
                        ),
                ),
              ),
            ],
          ),
        ),

        // Comments List
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getCommentsStream(widget.articleId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final comments = snapshot.data!;
            if (comments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada komentar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jadilah yang pertama berkomentar!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Build nested comment structure
            final topLevelComments = comments.where((c) => c['level'] == 0).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topLevelComments.length,
              itemBuilder: (context, index) {
                final comment = topLevelComments[index];
                final replies = comments
                    .where((c) =>
                        c['parentId'] == comment['id'] && c['level'] == 1)
                    .toList();

                return _CommentItem(
                  comment: comment,
                  replies: replies,
                  allComments: comments,
                  onReply: comment['level'] < 2
                      ? () => _setReply(
                            comment['id'],
                            comment['level'],
                            comment['userName'] ?? 'Anonym',
                          )
                      : null,
                  onReplyNested: _setReply,
                  currentUserId: _authService.currentUser?.uid,
                  onDelete: (commentId) async {
                    await _firestoreService.deleteComment(commentId);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final List<Map<String, dynamic>> replies;
  final List<Map<String, dynamic>> allComments;
  final VoidCallback? onReply;
  final Function(String, int, String)? onReplyNested;
  final String? currentUserId;
  final Function(String) onDelete;

  const _CommentItem({
    required this.comment,
    required this.replies,
    required this.allComments,
    this.onReply,
    this.onReplyNested,
    this.currentUserId,
    required this.onDelete,
  });

  String _formatTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Baru saja';
    
    try {
      DateTime dateTime;
      if (createdAt is Timestamp) {
        dateTime = createdAt.toDate();
      } else if (createdAt is DateTime) {
        dateTime = createdAt;
      } else {
        return 'Baru saja';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}h lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}j lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = comment['level'] ?? 0;
    final leftPadding = level * 32.0;
    final isOwner = currentUserId != null && comment['userId'] == currentUserId;

    return Container(
      padding: EdgeInsets.only(left: leftPadding, right: 16, top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (comment['userName']?[0] ?? 'A').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['userName'] ?? 'Anonym',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(comment['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button (only for owner)
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Komentar'),
                        content: const Text('Yakin ingin menghapus komentar ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete(comment['id']);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment text
          Text(
            comment['content'] ?? '',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Reply button
          if (onReply != null && level < 2)
            TextButton.icon(
              onPressed: onReply,
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Balas'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          // Nested replies
          if (replies.isNotEmpty)
            ...replies.map((reply) {
              final nestedReplies = allComments
                  .where((c) => c['parentId'] == reply['id'] && c['level'] == 2)
                  .toList();

              return _CommentItem(
                comment: reply,
                replies: nestedReplies,
                allComments: allComments,
                onReply: reply['level'] < 2 && onReplyNested != null
                    ? () => onReplyNested!(reply['id'], reply['level'], reply['userName'] ?? 'Anonym')
                    : null,
                onReplyNested: onReplyNested,
                currentUserId: currentUserId,
                onDelete: onDelete,
              );
            }).toList(),
        ],
      ),
    );
  }
}
