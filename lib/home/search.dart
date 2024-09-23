import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cook/models/SearchUserModel.dart';
import 'package:cook/services/search_service.dart';

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
  final SearchService _searchService = SearchService();
  final ScrollController _scrollController = ScrollController();
  String currentQuery = "";

  @override
  void initState() {
    super.initState();
    loadSavedUsers(); // Load saved users when app starts

    // Infinite scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchMoreUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Search for users
  Future<void> searchUsers(String query) async {
    setState(() {
      isLoading = true;
      currentQuery = query;
      currentPage = 1;
      searchResults.clear();
    });

    try {
      List<SearchUserModel> users = await _searchService.searchUsers(query, currentPage, pageSize);
      // Exclude already saved users from search results
      users.removeWhere((user) => savedUsers.any((savedUser) => savedUser.userId == user.userId));
      setState(() {
        searchResults = users;
      });
    } catch (e) {
      setState(() {
        searchResults = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch more users (pagination)
  Future<void> fetchMoreUsers() async {
    if (isFetchingMore) return;
    setState(() {
      isFetchingMore = true;
      currentPage++;
    });

    try {
      List<SearchUserModel> moreUsers =
          await _searchService.searchUsers(currentQuery, currentPage, pageSize);
      moreUsers.removeWhere((user) => savedUsers.any((savedUser) => savedUser.userId == user.userId));
      setState(() {
        searchResults.addAll(moreUsers);
      });
    } catch (e) {
      // Handle error if needed
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
  Widget buildFollowButton(SearchUserModel user) {
    bool isFollowing = false; // Initially not following
    return StatefulBuilder(builder: (context, setState) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange, // Orange background
          foregroundColor: Colors.white, // White font color
        ),
        onPressed: isFollowing
            ? null
            : () {
                setState(() {
                  isFollowing = true;
                });
              },
        child: Text(isFollowing ? 'Following' : 'Follow'),
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
                              trailing: buildFollowButton(user),
                              onTap: () => selectUser(user),
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
