import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String articleId;
  final String userId;
  final String userName;
  final bool isAnonymous;
  final String text;
  final String? parentId;
  final int level; // 0 = top level, 1 = reply, 2 = nested reply (max)
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommentModel> replies; // Nested replies

  CommentModel({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.userName,
    required this.isAnonymous,
    required this.text,
    this.parentId,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      articleId: data['articleId']?.toString() ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonym',
      isAnonymous: data['isAnonymous'] ?? false,
      text: data['text'] ?? '',
      parentId: data['parentId'],
      level: data['level'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replies: [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'articleId': int.parse(articleId),
      'userId': userId,
      'userName': userName,
      'isAnonymous': isAnonymous,
      'text': text,
      'parentId': parentId,
      'level': level,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CommentModel copyWith({
    String? id,
    String? articleId,
    String? userId,
    String? userName,
    bool? isAnonymous,
    String? text,
    String? parentId,
    int? level,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }
}
