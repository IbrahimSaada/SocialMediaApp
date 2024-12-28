import 'package:flutter/material.dart';
import '***REMOVED***/maintenance/expiredtoken.dart' show handleSessionExpired;
import '../models/notification_model.dart';
import '../page/question_details_page.dart';
import '../page/user_private_question_details_page.dart';
import '../services/notificationservice.dart';
import '../services/SessionExpiredException.dart';
import '../page/post_details_page.dart';
import '../page/comment_details_page.dart';
import '../page/repost_details_page.dart';
import '../page/answer_details_page.dart';
import '../page/private_question_details_page.dart';
import '../home/add_friends_page.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<NotificationModel>> _futureNotifications;
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _cachedNotifications = [];

  @override
  void initState() {
    super.initState();
    // Load notifications (with SessionExpiredException handling)
    _futureNotifications = _loadNotifications();
  }

  /// Loads notifications, handling session-expired scenarios
  Future<List<NotificationModel>> _loadNotifications() async {
    try {
      return await _notificationService.getUserNotifications();
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
      // Return empty list so UI won't crash
      return [];
    } catch (e) {
      print('Error loading notifications: $e');
      rethrow;
    }
  }

  /// Refresh notifications from server
  void _refreshNotifications() {
    setState(() {
      // Wrap in a function so we can handle session-expired again
      _futureNotifications = _loadNotifications();
    });
  }

  /// Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _refreshNotifications();
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
        ),
      );
    }
  }

  /// Called when user swipes (Dismissible) to delete a notification
  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      final success =
          await _notificationService.deleteNotification(notification.notificationId);
      if (!success) {
        // If delete was unauthorized or failed, restore the item
        // (because onDismissed removes it from the list)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete notification.'),
          ),
        );
        // Re-insert the notification and refresh
        setState(() {
          _cachedNotifications.insert(0, notification);
        });
      }
    } on SessionExpiredException {
      if (context.mounted) {
        handleSessionExpired(context);
      }
    } catch (e) {
      print('Delete notification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete notification'),
        ),
      );
      // Also restore notification in case of unknown failure
      setState(() {
        _cachedNotifications.insert(0, notification);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
        elevation: 0,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While the future is running
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load notifications'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }

          // Cache the notifications to a local list so we can manipulate them
          _cachedNotifications = snapshot.data!;

          final todayNotifications = _cachedNotifications.where((notification) {
            final now = DateTime.now();
            return notification.createdAt.day == now.day &&
                notification.createdAt.month == now.month &&
                notification.createdAt.year == now.year;
          }).toList();

          final earlierNotifications = _cachedNotifications.where((notification) {
            final now = DateTime.now();
            return notification.createdAt.isBefore(now) &&
                (notification.createdAt.day != now.day ||
                    notification.createdAt.month != now.month ||
                    notification.createdAt.year != now.year);
          }).toList();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, color: Color(0xFFF45F67)),
                      tooltip: 'Mark All As Read',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    if (todayNotifications.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ...todayNotifications.map(
                      (notification) => buildNotificationCard(notification, screenWidth),
                    ),
                    if (earlierNotifications.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Earlier This Week',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ...earlierNotifications.map(
                      (notification) => buildNotificationCard(notification, screenWidth),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildNotificationCard(
    NotificationModel notification,
    double screenWidth,
  ) {
    final iconData = getIconForNotificationType(notification.type);
    final timestamp = getTimeDifference(notification.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Dismissible(
        key: Key(notification.notificationId.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (direction) async {
          // Temporarily remove it from the list
          setState(() {
            _cachedNotifications.remove(notification);
          });
          // Attempt to delete from API
          await _deleteNotification(notification);
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF45F67).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: const Color(0xFFF45F67),
              ),
            ),
            // Show bold text if 'isRead' is false
            title: Text(
              notification.message,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: _getResponsiveFontSize(screenWidth),
              ),
            ),
            subtitle: Text(
              timestamp,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            onTap: () async {
              try {
                // Mark as read on tap
                await _notificationService.markAsRead(notification.notificationId);
                _refreshNotifications();
                // Then navigate based on notification type
                handleNotificationTap(notification);
              } on SessionExpiredException {
                if (context.mounted) {
                  handleSessionExpired(context);
                }
              } catch (e) {
                print('Error marking notification as read: $e');
              }
            },
          ),
        ),
      ),
    );
  }

  void handleNotificationTap(NotificationModel notification) {
    print('Tapped on: ${notification.type}');
    print('Notification details: $notification');

    if (notification.relatedEntityId != null ||
        notification.type == 'Follow' ||
        notification.type == 'Accept' ||
        notification.type == 'FollowedBack') {
      if (notification.type == 'Answer' || notification.type == 'AnswerVerified') {
        final questionId = notification.relatedEntityId!;
        List<int> answerIds = [];
        if (notification.aggregated_answer_ids != null &&
            notification.aggregated_answer_ids!.isNotEmpty) {
          answerIds = notification.aggregated_answer_ids!
              .split(',')
              .map((id) => int.parse(id.trim()))
              .toList();
        } else if (notification.commentId != null) {
          answerIds = [notification.commentId!];
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnswerDetailsPage(
              answerIds: answerIds,
              questionId: questionId,
            ),
          ),
        );
      } else if (notification.type == 'Follow' ||
          notification.type == 'Accept' ||
          notification.type == 'FollowedBack') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddFriendsPage(),
          ),
        );
      } else if (notification.type == 'Like' ||
          notification.type == 'Comment' ||
          notification.type == 'Share' ||
          notification.type == 'Reply') {
        if (notification.type == 'Reply' &&
            notification.aggregated_comment_ids != null) {
          // Parse aggregated comment IDs
          final commentIds = notification.aggregated_comment_ids!
              .split(',')
              .map((id) => int.parse(id.trim()))
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentDetailsPage(
                postId: notification.relatedEntityId!,
                aggregatedCommentIds: commentIds,
              ),
            ),
          );
        } else if (notification.type == 'Comment') {
          if (notification.aggregated_comment_ids != null &&
              notification.aggregated_comment_ids!.isNotEmpty) {
            final commentIds = notification.aggregated_comment_ids!
                .split(',')
                .map((id) => int.parse(id.trim()))
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentDetailsPage(
                  postId: notification.relatedEntityId!,
                  aggregatedCommentIds: commentIds,
                ),
              ),
            );
          } else if (notification.commentId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentDetailsPage(
                  postId: notification.relatedEntityId!,
                  commentId: notification.commentId!,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PostDetailsPage(postId: notification.relatedEntityId!),
              ),
            );
          }
        } else if (notification.type == 'Share') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepostDetailsPage(
                postId: notification.relatedEntityId!,
                isMultipleShares: notification.message.contains('others'),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PostDetailsPage(postId: notification.relatedEntityId!),
            ),
          );
        }
      } else if (notification.type == 'QuestionLike') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionDetailsPage(
              questionId: notification.relatedEntityId!,
            ),
          ),
        );
      } else if (notification.type == 'PrivateQuestion') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivateQuestionDetailsPage(
              userId: notification.recipientUserId,
              questionId: notification.relatedEntityId!,
            ),
          ),
        );
      } else if (notification.type == 'PrivateQuestionAnswered') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AcceptedPrivateQuestionDetailsPage(
              questionId: notification.relatedEntityId!,
            ),
          ),
        );
      } else {
        print('Unhandled notification type: ${notification.type}');
      }
    } else {
      print('No related entity id for this notification');
    }
  }

  IconData getIconForNotificationType(String type) {
    switch (type) {
      case 'Like':
        return Icons.thumb_up;
      case 'Comment':
        return Icons.comment;
      case 'Reply':
        return Icons.reply;
      case 'Share':
        return Icons.share;
      case 'Follow':
        return Icons.person_add;
      case 'FriendRequest':
        return Icons.person_add_alt_1;
      case 'AnswerVerified':
        return Icons.verified;
      case 'Decline':
        return Icons.close;
      case 'Accept':
        return Icons.check_circle;
      case 'FollowedBack':
        return Icons.person;
      case 'QuestionLike':
        return Icons.thumb_up_alt;
      case 'Answer':
        return Icons.question_answer;
      case 'PrivateQuestion':
        return Icons.question_answer;
      default:
        return Icons.notifications;
    }
  }

  String getTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  double _getResponsiveFontSize(double screenWidth) {
    if (screenWidth < 360) {
      return 12;
    } else if (screenWidth < 720) {
      return 14;
    } else {
      return 16;
    }
  }
}
