import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _articleStatsCollection = 'article_stats';
  static const String _articleCommentsCollection = 'article_comments';
  static const String _userInteractionsCollection = 'user_interactions';

  // ==================== ARTICLE STATS ====================

  /// Get article statistics (views, likes, comments count)
  /// Returns map with {views: int, likes: int, comments: int}
  Future<Map<String, int>> getArticleStats(int articleId) async {
    try {
      final doc = await _firestore
          .collection(_articleStatsCollection)
          .doc(articleId.toString())
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'views': data['views'] ?? 0,
          'likes': data['likes'] ?? 0,
          'comments': data['comments'] ?? 0,
        };
      }

      return {'views': 0, 'likes': 0, 'comments': 0};
    } catch (e) {
      return {'views': 0, 'likes': 0, 'comments': 0};
    }
  }

  /// Increment view count when article is opened
  Future<void> incrementViewCount(int articleId) async {
    try {
      final docRef = _firestore
          .collection(_articleStatsCollection)
          .doc(articleId.toString());

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          transaction.update(docRef, {
            'views': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'articleId': articleId,
            'views': 1,
            'likes': 0,
            'comments': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Silent fail for view increment
    }
  }

  /// Toggle like for an article (like/unlike)
  /// Returns true if liked, false if unliked
  Future<bool> toggleLike(int articleId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final interactionDoc = _firestore
          .collection(_userInteractionsCollection)
          .doc(user.uid)
          .collection('liked_articles')
          .doc(articleId.toString());

      final statsDoc = _firestore
          .collection(_articleStatsCollection)
          .doc(articleId.toString());

      return await _firestore.runTransaction<bool>((transaction) async {
        final interactionSnapshot = await transaction.get(interactionDoc);
        final isLiked = interactionSnapshot.exists;

        if (isLiked) {
          // Unlike
          transaction.delete(interactionDoc);
          transaction.update(statsDoc, {
            'likes': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false;
        } else {
          // Like
          transaction.set(interactionDoc, {
            'articleId': articleId,
            'likedAt': FieldValue.serverTimestamp(),
          });

          final statsSnapshot = await transaction.get(statsDoc);
          if (statsSnapshot.exists) {
            transaction.update(statsDoc, {
              'likes': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(statsDoc, {
              'articleId': articleId,
              'views': 0,
              'likes': 1,
              'comments': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          return true;
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has liked an article
  Future<bool> hasUserLikedArticle(String articleId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_userInteractionsCollection)
          .doc(userId)
          .collection('liked_articles')
          .doc(articleId)
          .get();

      return doc.exists;
    } catch (e) {

      return false;
    }
  }

  // ==================== COMMENTS ====================

  /// Post a comment on an article
  /// [parentId] - Optional: for nested replies (max 3 levels: 0, 1, 2)
  Future<String> postComment({
    required int articleId,
    required String content,
    String? parentId,
    int level = 0,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (level > 2) {
        throw Exception('Maximum comment nesting level reached');
      }

      final commentData = {
        'articleId': articleId,
        'userId': user.uid,
        'userName': user.displayName ?? (user.isAnonymous ? 'Anonym' : 'User'),
        'userEmail': user.email,
        'isAnonymous': user.isAnonymous,
        'content': content,
        'parentId': parentId,
        'level': level,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_articleCommentsCollection)
          .add(commentData);

      // Increment comment count in article stats
      await _incrementCommentCount(articleId);

      return docRef.id;
    } catch (e) {

      rethrow;
    }
  }

  /// Get comments for an article (with nested structure)
  /// Returns Stream for real-time updates
  Stream<List<Map<String, dynamic>>> getCommentsStream(int articleId) {
    return _firestore
        .collection(_articleCommentsCollection)
        .where('articleId', isEqualTo: articleId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    });
  }

  /// Get comments as one-time fetch
  Future<List<Map<String, dynamic>>> getComments(int articleId) async {
    try {
      final snapshot = await _firestore
          .collection(_articleCommentsCollection)
          .where('articleId', isEqualTo: articleId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {

      return [];
    }
  }

  /// Delete a comment (user can only delete their own)
  Future<void> deleteComment(String commentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection(_articleCommentsCollection)
          .doc(commentId)
          .get();

      if (!doc.exists) throw Exception('Comment not found');

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Unauthorized to delete this comment');
      }

      await _firestore
          .collection(_articleCommentsCollection)
          .doc(commentId)
          .delete();

      // Decrement comment count
      await _decrementCommentCount(data['articleId'] as int);
    } catch (e) {

      rethrow;
    }
  }

  /// Helper: Increment comment count in stats
  Future<void> _incrementCommentCount(int articleId) async {
    final docRef = _firestore
        .collection(_articleStatsCollection)
        .doc(articleId.toString());

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        transaction.update(docRef, {
          'comments': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'articleId': articleId,
          'views': 0,
          'likes': 0,
          'comments': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Helper: Decrement comment count in stats
  Future<void> _decrementCommentCount(int articleId) async {
    final docRef = _firestore
        .collection(_articleStatsCollection)
        .doc(articleId.toString());

    await docRef.update({
      'comments': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== ARTICLE DETAIL METHODS ====================

  /// Increment article views (alias for incrementViewCount)
  Future<void> incrementArticleViews(String articleId) async {
    return incrementViewCount(int.parse(articleId));
  }

  /// Like an article
  Future<void> likeArticle(String articleId, String userId) async {
    try {
      final interactionDoc = _firestore
          .collection(_userInteractionsCollection)
          .doc(userId)
          .collection('liked_articles')
          .doc(articleId);

      final statsDoc = _firestore
          .collection(_articleStatsCollection)
          .doc(articleId);

      await _firestore.runTransaction((transaction) async {
        // IMPORTANT: All reads must happen BEFORE any writes
        final statsSnapshot = await transaction.get(statsDoc);
        
        // Now do all writes
        transaction.set(interactionDoc, {
          'articleId': int.parse(articleId),
          'likedAt': FieldValue.serverTimestamp(),
        });

        if (statsSnapshot.exists) {
          transaction.update(statsDoc, {
            'likes': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(statsDoc, {
            'articleId': int.parse(articleId),
            'views': 0,
            'likes': 1,
            'comments': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Unlike an article
  Future<void> unlikeArticle(String articleId, String userId) async {
    try {
      final interactionDoc = _firestore
          .collection(_userInteractionsCollection)
          .doc(userId)
          .collection('liked_articles')
          .doc(articleId);

      final statsDoc = _firestore
          .collection(_articleStatsCollection)
          .doc(articleId);

      await _firestore.runTransaction((transaction) async {
        // IMPORTANT: All reads must happen BEFORE any writes
        final statsSnapshot = await transaction.get(statsDoc);
        
        // Now do all writes
        transaction.delete(interactionDoc);

        if (statsSnapshot.exists) {
          transaction.update(statsDoc, {
            'likes': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        // If stats don't exist, just delete the interaction (silent fail for stats)
      });
    } catch (e) {
      rethrow;
    }
  }
}
