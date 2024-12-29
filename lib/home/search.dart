import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

// Models
import 'package:cook/models/SearchUserModel.dart';

// Services
import 'package:cook/services/search_service.dart';
import 'package:cook/services/LoginService.dart';
import 'package:cook/services/FollowService.dart';

// Exceptions
import 'package:cook/maintenance/expiredtoken.dart'; // Session-expired dialog or screen
import 'package:cook/services/SessionExpiredException.dart';
import 'package:cook/services/blocked_user_exception.dart';
import 'package:cook/services/bannedexception.dart';

// UI
import 'package:cook/profile/otheruserprofilepage.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // Search results & saved (favorited) users
  List<SearchUserModel> searchResults = [];
  List<SearchUserModel> savedUsers = [];

  // Pagination / Loading
  bool isLoading = false;
  bool isFetchingMore = false;
  int currentPage = 1;
  int pageSize = 10;

  // Current user context
  int? currentUserId;
  final SearchService _searchService = SearchService();
  final LoginService _loginService = LoginService();
  final ScrollController _scrollController = ScrollController();
  String currentQuery = "";

  @override
  void initState() {
    super.initState();
    loadSavedUsers();
    getCurrentUserId();

    // Infinite scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchMoreUsers();
      }
    });
  }

  /// Fetch the current logged-in user ID
  Future<void> getCurrentUserId() async {
    int? userId = await _loginService.getUserId();
    setState(() {
      currentUserId = userId;
    });
  }

  /// Perform a new user search
  Future<void> searchUsers(String query) async {
    // If we haven't retrieved currentUserId yet, skip
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
      currentQuery = query;
      currentPage = 1;
      searchResults.clear();
    });

    try {
      // Call the search service
      List<SearchUserModel> users = await _searchService.searchUsers(
        query,
        currentUserId!,
        currentPage,
        pageSize,
      );

      // Remove any duplicates or already-saved users
      users.removeWhere((u) =>
          searchResults.any((existing) => existing.userId == u.userId));
      users.removeWhere((u) =>
          savedUsers.any((saved) => saved.userId == u.userId));

      setState(() {
        searchResults.addAll(users);
      });
    } on SessionExpiredException {
      if (context.mounted) handleSessionExpired(context);
    }
    // Handle blocked & banned logic
    on BlockedUserException catch (bue) {
      // The user or target might be blocked
      final reason = bue.reason;
      showSnackBarMessage(reason, Colors.redAccent);
    } on BannedException catch (bex) {
      // The user is banned
      showSnackBarMessage("You are banned. Reason: ${bex.reason}", Colors.red);
    } catch (e) {
      // Other errors
      setState(() {
        searchResults.clear();
      });
      print("Error in searchUsers: $e");
      showSnackBarMessage(
        'An error occurred while searching. Please try again.',
        Colors.red,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetch additional (paginated) results
  Future<void> fetchMoreUsers() async {
    if (isFetchingMore || currentUserId == null || currentQuery.isEmpty) return;

    setState(() {
      isFetchingMore = true;
      currentPage++;
    });

    try {
      List<SearchUserModel> moreUsers = await _searchService.searchUsers(
        currentQuery,
        currentUserId!,
        currentPage,
        pageSize,
      );

      // Remove duplicates
      moreUsers.removeWhere((u) =>
          searchResults.any((existing) => existing.userId == u.userId));
      moreUsers.removeWhere((u) =>
          savedUsers.any((saved) => saved.userId == u.userId));

      setState(() {
        searchResults.addAll(moreUsers);
      });
    } on SessionExpiredException {
      if (context.mounted) handleSessionExpired(context);
    } on BlockedUserException catch (bue) {
      showSnackBarMessage(bue.reason, Colors.redAccent);
    } on BannedException catch (bex) {
      showSnackBarMessage("You are banned. Reason: ${bex.reason}", Colors.red);
    } catch (e) {
      print("Error in fetchMoreUsers: $e");
      showSnackBarMessage(
        'An error occurred while fetching more users.',
        Colors.red,
      );
    } finally {
      setState(() {
        isFetchingMore = false;
      });
    }
  }

  /// Save a user to local favorites (prevents duplicates)
  Future<void> saveUser(SearchUserModel user) async {
    if (savedUsers.any((savedUser) => savedUser.userId == user.userId)) {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedUsers.add(user);
    List<String> savedUserStrings =
        savedUsers.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList('savedUsers', savedUserStrings);
    setState(() {});
  }

  /// Load saved users from local storage
  Future<void> loadSavedUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedUserStrings = prefs.getStringList('savedUsers');
    if (savedUserStrings != null) {
      setState(() {
        savedUsers = savedUserStrings
            .map((userString) =>
                SearchUserModel.fromJson(jsonDecode(userString)))
            .toList();
      });
    }
  }

  /// Remove a user from the saved list
  Future<void> removeSavedUser(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedUsers.removeAt(index);
    List<String> savedUserStrings =
        savedUsers.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList('savedUsers', savedUserStrings);
    setState(() {});
  }

  /// Helper: Show a snack bar message
  void showSnackBarMessage(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Build a shimmer effect widget for loading states
  Widget buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(10, (index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 25,
            ),
            title: Container(
              height: 10.0,
              width: double.infinity,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 10.0,
              width: 150,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  /// Build the follow/unfollow button logic
  Widget buildFollowButton(SearchUserModel user, int currentUserId) {
    return StatefulBuilder(
      builder: (context, setButtonState) {
        // Derive button text/color from user.isFollowing & user.amFollowing
        String buttonText = "Follow";
        Color buttonColor = const Color(0xFFF45F67);

        if (user.isFollowing && !user.amFollowing) {
          // They follow you, you don't follow them => "Follow Back"
          buttonText = "Follow Back";
          buttonColor = const Color(0xFFF45F67);
        } else if (!user.isFollowing && user.amFollowing) {
          // You follow them, they don't follow you => "Following"
          buttonText = "Following";
          buttonColor = Colors.grey;
        } else if (!user.isFollowing && !user.amFollowing) {
          // Neither follows each other => "Follow"
          buttonText = "Follow";
          buttonColor = const Color(0xFFF45F67);
        } else if (user.isFollowing && user.amFollowing) {
          // Mutual follow => "Following"
          buttonText = "Following";
          buttonColor = Colors.grey;
        }

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            // Optimistic UI update
            setButtonState(() {
              user.amFollowing = !user.amFollowing;
            });

            try {
              if (!user.amFollowing) {
                // Unfollow
                await FollowService().unfollowUser(currentUserId, user.userId);
              } else {
                // Follow
                await FollowService().followUser(currentUserId, user.userId);
              }
            } on SessionExpiredException {
              if (context.mounted) handleSessionExpired(context);
              // Revert state
              setButtonState(() {
                user.amFollowing = !user.amFollowing;
              });
            } on BlockedUserException catch (bue) {
              // Revert state
              setButtonState(() {
                user.amFollowing = !user.amFollowing;
              });
              showSnackBarMessage(bue.reason, Colors.redAccent);
            } on BannedException catch (bex) {
              // Revert state
              setButtonState(() {
                user.amFollowing = !user.amFollowing;
              });
              showSnackBarMessage(
                  "You are banned. Reason: ${bex.reason}", Colors.red);
            } catch (e) {
              // Revert state
              setButtonState(() {
                user.amFollowing = !user.amFollowing;
              });
              print("Error in buildFollowButton onPressed: $e");
              showSnackBarMessage(
                "An error occurred. Please try again.",
                Colors.red,
              );
            }
          },
          child: Text(buttonText),
        );
      },
    );
  }

  /// When user taps on a search item
  void selectUser(SearchUserModel user) {
    saveUser(user); // Store user in favorites
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // Custom AppBar with extra spacing
      appBar:  AppBar(
          backgroundColor: const Color(0xFFF45F67),
          elevation: 4,
          shadowColor: Colors.grey.shade200,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back arrow
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              // Centered title
              const Expanded(
                child: Center(
                  child: Text(
                    'SEARCH',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Placeholder to balance the layout
              SizedBox(width: 48), // Same width as the back arrow for symmetry
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                onSubmitted: searchUsers,
                decoration: InputDecoration(
                  hintText: 'Search for a user...',
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(0xFFF45F67), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(0xFFF45F67), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(0xFFF45F67), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Loading shimmer
              if (isLoading) Expanded(child: buildShimmer()),

              // Saved Users Section
              if (!isLoading && savedUsers.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Saved Users",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: savedUsers.length,
                          itemBuilder: (context, index) {
                            final user = savedUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.profilePic),
                              ),
                              title: Text(user.username),
                              subtitle: Text(user.fullName),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => removeSavedUser(index),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtherUserProfilePage(
                                      otherUserId: user.userId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(
                color: Color(0xFFF45F67),
                thickness: 2,
              ),

              // Search Results
              if (!isLoading && searchResults.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Search Results",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              searchResults.length + (isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Loader indicator at the bottom
                            if (index == searchResults.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final user = searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user.profilePic),
                              ),
                              title: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  user.username,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                user.fullName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing:
                                  buildFollowButton(user, currentUserId!),
                              onTap: () {
                                // Save the user to local favorites
                                selectUser(user);
                                // Navigate to profile
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtherUserProfilePage(
                                      otherUserId: user.userId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
