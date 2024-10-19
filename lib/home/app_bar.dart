// widgets/app_bar.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '***REMOVED***/services/loginservice.dart';
import '***REMOVED***/menu/menu_page.dart';

PreferredSizeWidget buildTopAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: const Color(0xFFF45F67),
    automaticallyImplyLeading: false,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: FutureBuilder<String?>(
          future: LoginService().getProfilePic(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircleAvatar(
                backgroundImage: AssetImage('assets/images/default.png'),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              return CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(snapshot.data!),
              );
            } else {
              return const CircleAvatar(
                backgroundImage: AssetImage('assets/images/default.png'),
              );
            }
          },
        ),
        onPressed: () {
          // Open Menu Page
          showDialog(
            context: context,
            builder: (context) => MenuPage(),
          );
        },
      ),
    ),
    title: Text(
      '***REMOVED***',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            blurRadius: 5.0,
            color: Color(0xFFF45F67).withOpacity(0.6),
            offset: Offset(2.0, 2.0),
          ),
          Shadow(
            blurRadius: 5.0,
            color: Colors.black.withOpacity(0.3),
            offset: Offset(-2.0, -2.0),
          ),
        ],
      ),
    ),
    centerTitle: true,
  );
}
