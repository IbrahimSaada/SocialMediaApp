import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  final String contactName;
  final String lastMessage;
  final String profileImage;
  final bool isOnline;
  final String lastActive;
  final bool isMuted;  // State to track if the contact is muted
  final bool isTyping;  // State to track if the contact is typing
  final int unreadMessages;
  final Function onMuteToggle;  // Function to toggle mute/unmute
  final Function onDelete;

  const ContactTile({
    required this.contactName,
    required this.lastMessage,
    required this.profileImage,
    required this.isOnline,
    required this.lastActive,
    required this.isMuted,  // Pass the mute state
    required this.isTyping,  // Pass the typing state
    required this.unreadMessages,
    required this.onMuteToggle,  // Function to handle muting/unmuting
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),  // Each contact must have a unique key
      background: Container(
        color: Colors.blue,  // Mute/Unmute background
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(isMuted ? Icons.volume_up : Icons.volume_off, color: Colors.white),  // Mute or unmute icon
            SizedBox(width: 8),
            Text(
              isMuted ? 'Unmute' : 'Mute',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,  // Delete background
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mute or Unmute action when swiping left
          onMuteToggle();
          return false;  // Prevent dismiss to keep the item in the list
        } else if (direction == DismissDirection.endToStart) {
          // Allow delete when swiping right
          return true;
        }
        return false;
      },
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(profileImage),
              radius: 25,
              backgroundColor: Color(0xFFF45F67),
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
              child: Text(
                contactName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isMuted)
              Icon(Icons.volume_off, color: Colors.grey),  // Show mute icon if muted
          ],
        ),
        subtitle: Text(
          isTyping
              ? 'typing...'  // Show typing status if contact is typing
              : isOnline
                  ? 'Active now'
                  : 'Active $lastActive',  // If not typing, show online/last active status
          style: TextStyle(color: Colors.grey),
        ),
        trailing: unreadMessages > 0
            ? CircleAvatar(
                backgroundColor: Color(0xFFF45F67),
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
