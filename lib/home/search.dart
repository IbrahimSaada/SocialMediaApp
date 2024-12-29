import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

// Models (Adjust imports as per your project structure)
import '***REMOVED***/models/SearchUserModel.dart';

// Services
import '***REMOVED***/services/search_service.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/services/FollowService.dart';

// Exceptions
import '***REMOVED***/maintenance/expiredtoken.dart'; // Session-expired dialog or screen
import '***REMOVED***/services/SessionExpiredException.dart';
import '***REMOVED***/services/blocked_user_exception.dart';
import '***REMOVED***/services/bannedexception.dart';

// UI
import '***REMOVED***/profile/otheruserprofilepage.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // Controllers & Debounce
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
    _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Debounce logic to avoid calling search on every character instantly
  void _onSearchChanged() {
    // Cancel previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Wait 300ms after user stops typing
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      searchUsers(query);
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

    // If query is empty, just clear results & stop
    if (query.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Call the search service
      List<SearchUserModel> users = await _searchService.searchUsers(
        query,
        currentUserId!,
        currentPage,
        pageSize,
      );

      // Remove duplicates or already-saved users
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
      final reason = bue.reason;
      showSnackBarMessage(reason, Colors.redAccent);
    } on BannedException catch (bex) {
      showSnackBarMessage("You are banned. Reason: ${bex.reason}", Colors.red);
    } catch (e) {
      debugPrint("Error in searchUsers: $e");
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

      // Remove duplicates or saved
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
      debugPrint("Error in fetchMoreUsers: $e");
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

  /// Save a user to local favorites
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
        String buttonText = "Follow";
        Color buttonColor = const Color(0xFFF45F67);

        if (user.isFollowing && !user.amFollowing) {
          // They follow you, you don't follow them => "Follow Back"
          buttonText = "Follow Back";
        } else if (!user.isFollowing && user.amFollowing) {
          // You follow them => "Following"
          buttonText = "Following";
          buttonColor = Colors.grey;
        } else if (user.isFollowing && user.amFollowing) {
          // Mutual => "Following"
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
              debugPrint("Error in buildFollowButton onPressed: $e");
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
        appBar: AppBar(
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
              const SizedBox(width: 48),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                cursorColor: const Color(0xFFF45F67),
                decoration: InputDecoration(
                  hintText: 'Search for a user...',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      searchUsers('');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFF45F67),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFF45F67),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFF45F67),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Loading shimmer
              if (isLoading)
                Expanded(child: buildShimmer()),

              // Show "No Results Found" if not loading, search is not empty, and results are 0
              if (!isLoading && currentQuery.isNotEmpty && searchResults.isEmpty)
                Expanded(
                  child: Center(
                    child: Text("No results found for '$currentQuery'."),
                  ),
                ),

              // Saved Users Section
              if (!isLoading && savedUsers.isNotEmpty && currentQuery.isEmpty)
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

              // Search Results (Only show if we have results)
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
                          itemCount: searchResults.length + (isFetchingMore ? 1 : 0),
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
                              trailing: buildFollowButton(user, currentUserId!),
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
