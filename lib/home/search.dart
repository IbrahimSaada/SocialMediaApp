import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '***REMOVED***/models/SearchUserModel.dart';
import '***REMOVED***/services/search_service.dart';
import '***REMOVED***/services/LoginService.dart';
import '***REMOVED***/services/followService.dart';
import '***REMOVED***/maintenance/expiredtoken.dart';  // Import expired token handler

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<SearchUserModel> searchResults = [];
  List<SearchUserModel> savedUsers = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  int currentPage = 1;
  int pageSize = 10;
  int? currentUserId; // Store the currentUserId
  final SearchService _searchService = SearchService();
  final LoginService _loginService = LoginService(); // Instantiate LoginService
  final ScrollController _scrollController = ScrollController();
  String currentQuery = "";

  @override
  void initState() {
    super.initState();
    loadSavedUsers(); // Load saved users when app starts
    getCurrentUserId(); // Fetch current user ID

    // Infinite scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchMoreUsers(); // Fetch more users when the bottom of the list is reached
      }
    });
  }

  // Fetch current user ID from LoginService
  Future<void> getCurrentUserId() async {
    int? userId = await _loginService.getUserId();
    setState(() {
      currentUserId = userId; // Set current user ID in the state
    });
  }

  // Search for users
  Future<void> searchUsers(String query) async {
    if (currentUserId == null) return; // Ensure currentUserId is available
    setState(() {
      isLoading = true;
      currentQuery = query;
      currentPage = 1;
      searchResults.clear();
    });

    try {
      List<SearchUserModel> users = await _searchService.searchUsers(query, currentUserId!, currentPage, pageSize);
      // Remove duplicates in searchResults
      users.removeWhere((user) => searchResults.any((existingUser) => existingUser.userId == user.userId));
      
      // Exclude already saved users from search results
      users.removeWhere((user) => savedUsers.any((savedUser) => savedUser.userId == user.userId));
      setState(() {
        searchResults.addAll(users); // Merge non-duplicate users
      });
    } catch (e) {
      // Handle session expiration
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);  // Call session expired dialog
        }
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch more users (pagination)
  Future<void> fetchMoreUsers() async {
    if (isFetchingMore || currentUserId == null) return;
    setState(() {
      isFetchingMore = true;
      currentPage++;
    });

    try {
      List<SearchUserModel> moreUsers = await _searchService.searchUsers(currentQuery, currentUserId!, currentPage, pageSize);
      // Remove duplicates in searchResults
      moreUsers.removeWhere((user) => searchResults.any((existingUser) => existingUser.userId == user.userId));
      
      moreUsers.removeWhere((user) => savedUsers.any((savedUser) => savedUser.userId == user.userId));
      setState(() {
        searchResults.addAll(moreUsers);
      });
    } catch (e) {
      // Handle session expiration
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);  // Call session expired dialog
        }
      }
    } finally {
      setState(() {
        isFetchingMore = false;
      });
    }
  }

  // Save user to favorites (prevent duplicates)
  Future<void> saveUser(SearchUserModel user) async {
    if (savedUsers.any((savedUser) => savedUser.userId == user.userId)) {
      return; // Prevent duplicates in the saved list
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedUsers.add(user);
    List<String> savedUserStrings = savedUsers.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('savedUsers', savedUserStrings);
    setState(() {});
  }

  // Load saved users from local storage
  Future<void> loadSavedUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedUserStrings = prefs.getStringList('savedUsers');
    if (savedUserStrings != null) {
      setState(() {
        savedUsers = savedUserStrings
            .map((userString) => SearchUserModel.fromJson(jsonDecode(userString)))
            .toList();
      });
    }
  }

  // Clear all saved users
  Future<void> clearSavedUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedUsers');
    setState(() {
      savedUsers.clear();
    });
  }

  // Remove a specific user from saved list
  Future<void> removeSavedUser(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedUsers.removeAt(index);
    List<String> savedUserStrings = savedUsers.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('savedUsers', savedUserStrings);
    setState(() {});
  }

  // Shimmer effect for loading
  Widget buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(10, (index) {
          return ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white, radius: 25),
            title: Container(height: 10.0, width: double.infinity, color: Colors.white),
            subtitle: Container(height: 10.0, width: 150, color: Colors.white),
          );
        }),
      ),
    );
  }

  // User selection to save (prevent duplicates)
  void selectUser(SearchUserModel user) {
    saveUser(user); // Save to favorites
  }

  // Follow/Following button toggle
 Widget buildFollowButton(SearchUserModel user, int currentUserId) {
  return StatefulBuilder(builder: (context, setState) {
    // Initialize buttonText and buttonColor with default values
    String buttonText = "Follow"; // Default text (safe fallback)
    Color buttonColor = Colors.orange; // Default color (safe fallback)

    // Handle the button text and color based on the following states
    if (user.isFollowing && !user.amFollowing) {
      // Case 1: They are following you, but you are not following them
      buttonText = "Follow Back";
      buttonColor = Colors.orange;
    } else if (!user.isFollowing && user.amFollowing) {
      // Case 2: You are following them, but they are not following you
      buttonText = "Following";
      buttonColor = Colors.grey;
    } else if (!user.isFollowing && !user.amFollowing) {
      // Case 3: Neither of you are following each other
      buttonText = "Follow";
      buttonColor = Colors.orange;
    } else if (user.isFollowing && user.amFollowing) {
      // Case 4: Both of you are following each other
      buttonText = "Following";
      buttonColor = Colors.grey;
    }

    // Return the button with onPressed logic for follow/unfollow
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        // Optimistically update the UI first
        setState(() {
          if (!user.amFollowing) {
            // Update the UI to reflect the follow action immediately
            user.amFollowing = true;
          } else {
            // Update the UI to reflect the unfollow action immediately
            user.amFollowing = false;
          }
        });

        // Now, perform the async action in the background
        try {
          if (!user.amFollowing) {
            // Call the unfollow API
            await FollowService().unfollowUser(currentUserId, user.userId);
          } else {
            // Call the follow API
            await FollowService().followUser(currentUserId, user.userId);
          }
        } catch (e) {
          // Handle session expiration
          if (e.toString().contains('Session expired')) {
            if (context.mounted) {
              handleSessionExpired(context);  // Call session expired dialog
            }
          }

          // In case of error, revert the UI state
          setState(() {
            if (!user.amFollowing) {
              // Revert back to following
              user.amFollowing = true;
            } else {
              // Revert back to not following
              user.amFollowing = false;
            }
          });
        }
      },
      child: Text(buttonText),
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("SEARCH"),
          backgroundColor: Colors.orange,
          actions: [
            // Clear all saved users
            if (savedUsers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: clearSavedUsers,
              ),
          ],
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Loading shimmer effect
              if (isLoading)
                Expanded(child: buildShimmer()),

              // Saved Users Section
              if (!isLoading && savedUsers.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Saved Users",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Orange line between Saved Users and Search Results
              const Divider(color: Colors.orange, thickness: 2),

              // Search Results Section
              if (!isLoading && searchResults.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Search Results",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: searchResults.length + (isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
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
                              title: Text(user.username),
                              subtitle: Text(user.fullName),
                              // Pass both user and currentUserId to the buildFollowButton
                              trailing: buildFollowButton(user, currentUserId!), // Ensure currentUserId is passed
                              onTap: () => selectUser(user),  // Select user to save them
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
