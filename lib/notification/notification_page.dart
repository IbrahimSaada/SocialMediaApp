// notification_page.dart

import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../page/question_details_page.dart';
import '../page/user_private_question_details_page.dart';
import '../services/notificationservice.dart';
import '../page/post_details_page.dart';
import '../page/comment_details_page.dart';
import '../page/repost_details_page.dart';
import '../profile/otheruserprofilepage.dart';
import '../page/answer_details_page.dart';
import '../page/private_question_details_page.dart'; // Import the new page

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<NotificationModel>> _futureNotifications;

  @override
  void initState() {
    super.initState();
    _futureNotifications = NotificationService().getUserNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notifications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFF45F67)),
        elevation: 0,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<NotificationModel> notifications = snapshot.data!;

            // Separate notifications into groups: Today and Earlier This Week
            final todayNotifications = notifications.where((notification) {
              final now = DateTime.now();
              return notification.createdAt.day == now.day &&
                  notification.createdAt.month == now.month &&
                  notification.createdAt.year == now.year;
            }).toList();

            final earlierNotifications = notifications.where((notification) {
              final now = DateTime.now();
              return notification.createdAt.isBefore(now) &&
                  notification.createdAt.day != now.day;
            }).toList();

            return Column(
              children: [
                // Fixed Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
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
                        icon: const Icon(Icons.filter_list,
                            color: Color(0xFFF45F67)),
                        onPressed: () {
                          // Handle filter action
                          print('Filter icon pressed');
                        },
                      ),
                    ],
                  ),
                ),
                // Scrollable Notifications
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      // Today Notifications Section
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
                      ...todayNotifications.map((notification) =>
                          buildNotificationCard(notification, screenWidth)),
                      // Earlier This Week Notifications Section
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
                      ...earlierNotifications.map((notification) =>
                          buildNotificationCard(notification, screenWidth)),
                    ],
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load notifications'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget buildNotificationCard(
      NotificationModel notification, double screenWidth) {
    IconData iconData = getIconForNotificationType(notification.type);
    String timestamp = getTimeDifference(notification.createdAt);

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
        onDismissed: (direction) {
          // Handle delete action
          print('Notification dismissed: ${notification.message}');
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
                color: Color(0xFFF45F67).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: Color(0xFFF45F67),
              ),
            ),
            title: Text(
              notification.message,
              style: TextStyle(
                fontWeight: FontWeight.bold,
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
            onTap: () {
              // Handle notification tap
              print('Tapped on: ${notification.type}');
              print('Notification details:');
              print('Type: ${notification.type}');
              print('relatedEntityId: ${notification.relatedEntityId}');
              print('commentId: ${notification.commentId}');

              if (notification.relatedEntityId != null) {
                if (notification.type == 'Answer' ||
                    notification.type == 'AnswerVerified') {
                  // For 'Answer' and 'AnswerVerified' notifications
                  int answerId = notification.commentId!;
                  int questionId = notification.relatedEntityId!;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnswerDetailsPage(
                        answerId: answerId,
                        questionId: questionId,
                      ),
                    ),
                  );
                } else if (notification.type == 'Follow' ||
                    notification.type == 'Accept' ||
                    notification.type == 'FollowedBack') {
                  // Navigate to OtherUserProfilePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherUserProfilePage(
                        otherUserId: notification.senderUserId!,
                      ),
                    ),
                  );
                }
                // Handle other notification types...
                else if (notification.type == 'Like' ||
                    notification.type == 'Comment' ||
                    notification.type == 'Share' ||
                    notification.type == 'Reply') {
                  if (notification.type == 'Reply' &&
                      notification.commentId != null) {
                    // Navigate to CommentDetailsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentDetailsPage(
                          postId: notification.relatedEntityId!,
                          commentId: notification.commentId!,
                        ),
                      ),
                    );
                  } else if (notification.type == 'Share') {
                    // Navigate to RepostDetailsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RepostDetailsPage(
                            sharePostId: notification.relatedEntityId!),
                      ),
                    );
                  } else {
                    // Navigate to PostDetailsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsPage(
                            postId: notification.relatedEntityId!),
                      ),
                    );
                  }
                } else if (notification.type == 'QuestionLike') {
                  // Navigate to QuestionDetailsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionDetailsPage(
                        questionId: notification.relatedEntityId!,
                      ),
                    ),
                  );
                } else if (notification.type == 'PrivateQuestion') {
                  // Navigate to PrivateQuestionDetailsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateQuestionDetailsPage(
                        userId: notification.recipientUserId,
                        questionId: notification.relatedEntityId!,
                      ),
                    ),
                  );
                }   else if (notification.type == 'PrivateQuestionAnswered') {
          // Navigate to AcceptedPrivateQuestionDetailsPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AcceptedPrivateQuestionDetailsPage(
                questionId: notification.relatedEntityId!,
              ),
            ),
          );
        }

                 else {
                  // Handle other notification types
                  print('Unhandled notification type: ${notification.type}');
                }
              } else {
                // Handle case where related_entity_id is null
                print('No related entity id for this notification');
              }
            },
          ),
        ),
      ),
    );
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
        return Icons.question_answer; // Add this line
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
      return 12; // Small phones
    } else if (screenWidth < 720) {
      return 14; // Medium devices
    } else {
      return 16; // Larger screens
    }
  }
}
