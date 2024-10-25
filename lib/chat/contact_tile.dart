// widgets/contact_tile.dart

import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  final String contactName;
  final String lastMessage;
  final String profileImage;
  final bool isOnline;
  final String lastActive;
  final bool isMuted;
  final bool isTyping;
  final int unreadMessages;
  final Function onMuteToggle;
  final Function onDelete;

  const ContactTile({
    required this.contactName,
    required this.lastMessage,
    required this.profileImage,
    required this.isOnline,
    required this.lastActive,
    required this.isMuted,
    required this.isTyping,
    required this.unreadMessages,
    required this.onMuteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(isMuted ? Icons.volume_up : Icons.volume_off, color: Colors.white),
            SizedBox(width: 8),
            Text(isMuted ? 'Unmute' : 'Mute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMuteToggle();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return true;
        }
        return false;
      },
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(profileImage),
              radius: 25,
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(contactName, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isMuted) Icon(Icons.volume_off, color: Colors.grey),
          ],
        ),
        subtitle: Text(
          isTyping
              ? 'typing...'
              : isOnline
                  ? 'Active now'
                  : 'Active $lastActive',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: unreadMessages > 0
            ? CircleAvatar(
                backgroundColor: Colors.red,
                radius: 12,
                child: Text(
                  '$unreadMessages',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : null,
      ),
    );
  }
}
