import 'package:flutter/material.dart';
import 'dart:async';

// ignore: use_key_in_widget_constructors
class AskQuestionPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _AskQuestionPageState createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  final TextEditingController _questionController = TextEditingController();
  String selectedSection = 'My Questions'; // Set default section to 'My Questions'
  AnimationController? _controller; // Use nullable AnimationController to prevent late init errors

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this, // SingleTickerProviderStateMixin provides vsync
    );

    // ignore: prefer_const_constructors
    Timer(Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  void dispose() {
    // Dispose of the controller to avoid memory leaks if initialized
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_const_constructors
      backgroundColor: Color(0xFFF8F9FA),
      body: _showSplash ? buildSplashScreen() : buildAskQuestionPage(),
    );
  }

  Widget buildSplashScreen() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        // ignore: prefer_const_constructors
        duration: Duration(seconds: 3), // longer duration for complex animation
        curve: Curves.easeInOut,
        builder: (context, double value, child) {
          return Stack(
            children: [
              // Fade-in background
              Positioned.fill(
                child: Opacity(
                  opacity: value,
                  child: Container(
                    // ignore: prefer_const_constructors
                    decoration: BoxDecoration(
                      // ignore: prefer_const_constructors
                      gradient: LinearGradient(
                        // ignore: prefer_const_literals_to_create_immutables
                        colors: [Colors.deepOrangeAccent, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Animated scaling and fading text
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: value,
                        child: Text(
                          "ASK",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.15, // Scales with screen width
                            fontWeight: FontWeight.bold,
                            color: Color.lerp(Colors.white, Colors.orange, value),
                            shadows: [
                              Shadow(
                                blurRadius: value * 10,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(5 * value, 5 * value),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ignore: prefer_const_constructors
                    SizedBox(height: 20),
                    Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value * 0.9,
                        child: Text(
                          "QUESTION",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.1, // Scales with screen width
                            fontWeight: FontWeight.bold,
                            color: Color.lerp(Colors.white, Colors.teal, value),
                            shadows: [
                              Shadow(
                                blurRadius: value * 10,
                                color: Colors.black.withOpacity(0.4),
                                offset: Offset(-5 * value, 5 * value),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Sliding circle as a modern background animation element
              Positioned(
                top: MediaQuery.of(context).size.height * 0.7,
                left: MediaQuery.of(context).size.width * value - 100, // Sliding in from the left
                child: Opacity(
                  opacity: value * 0.8,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildAskQuestionPage() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
  backgroundColor: Colors.transparent,
  elevation: 0,
  flexibleSpace: Container(
    decoration: BoxDecoration(
      // ignore: prefer_const_constructors
      gradient: LinearGradient(
        // ignore: prefer_const_literals_to_create_immutables, prefer_const_constructors
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 5,
          blurRadius: 20,
        ),
      ],
    ),
  ),
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Profile Avatar with adjusted size
      ClipOval(
        child: Image.network(
          'https://via.placeholder.com/150', 
          width: 24, // Match size with icons
          height: 24, // Match size with icons
          fit: BoxFit.cover,
        ),
      ),

      // Adjusting the title text with Flexible and FittedBox
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown, // This will make the text scale down to fit
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ignore: prefer_const_constructors
              Text(
                "QUESTIONS & ANSWERS",
                // ignore: prefer_const_constructors
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Font size that can scale
                  letterSpacing: 1.2,
                ),
              ),
              // ignore: prefer_const_constructors
              SizedBox(height: 2),
              Text(
                "Find answers from the community",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),

      // Home and Settings icons with adjusted size
      Row(
        children: [
          IconButton(
            // ignore: prefer_const_constructors
            icon: Icon(Icons.home, color: Colors.white, size: 24), // Adjusted size
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          IconButton(
            // ignore: prefer_const_constructors
            icon: Icon(Icons.settings, color: Colors.white, size: 24), // Adjusted size
            onPressed: () {
              // Open Settings
            },
          ),
        ],
      ),
    ],
  ),

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input field for asking a question
            buildPostInputSection(),
            // ignore: prefer_const_constructors
            SizedBox(height: 20),
            // Section tabs
            buildSectionTabs(),
            // ignore: prefer_const_constructors
            SizedBox(height: 20),
            // Conditional rendering of the questions list based on the selected section
            Expanded(
              child: AnimatedSwitcher(
                // ignore: prefer_const_constructors
                duration: Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => SlideTransition(
                  // ignore: prefer_const_constructors
                  position: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(animation),
                  child: child,
                ),
                child: buildQuestionList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTabs() {
    return Center(
      child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Flexible(child: buildSectionTab('General Questions')), // Use Flexible
    // ignore: prefer_const_constructors
    Text('|', style: TextStyle(fontSize: 24, color: Colors.grey)),
    Flexible(child: buildSectionTab('My Questions')), // Use Flexible
  ],
),
    );
  }

  Widget buildSectionTab(String section) {
    bool isSelected = selectedSection == section;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSection = section;
          _controller?.forward(from: 0); // Trigger animation if initialized
        });
      },
      child: AnimatedBuilder(
        // ignore: prefer_const_constructors
        animation: _controller ?? AlwaysStoppedAnimation(0.0),
        builder: (context, child) {
          return Text(
            section,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05, // Scales with screen width
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              // ignore: prefer_const_constructors
              color: isSelected ? Color(0xFFE67E22) : Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget buildPostInputSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        // ignore: prefer_const_constructors
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // ignore: prefer_const_constructors
          color: Color(0xFFCCD5AE),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              // ignore: prefer_const_constructors
              offset: Offset(0, 4),
            ),
          ],
          // ignore: prefer_const_constructors
          border: Border.all(color: Color(0xFFD4AF37), width: 2),
        ),
        child: Row(
          children: [
            IconButton(
              // ignore: prefer_const_constructors
              icon: Icon(Icons.camera_alt, color: Color(0xFF6B705C), size: 24), // Reduced size
              onPressed: () {
                // Handle image selection
              },
            ),
            Expanded(
              child: TextField(
                controller: _questionController,
                // ignore: prefer_const_constructors
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  border: InputBorder.none,
                  isDense: true, // Make the text field more compact
                  // ignore: prefer_const_constructors
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                maxLines: 1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Color(0xFFD4AF37), size: 24), // Reduced size
              onPressed: () {
                // Handle selecting users to ask
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuestionList() {
    if (selectedSection == 'My Questions') {
      return buildQuestionsSection();
    } else {
      return buildGeneralQuestionsSection();
    }
  }

  Widget buildQuestionsSection() {
    return ListView(
      key: const ValueKey('Questions'),
      children: [
        buildQuestionCard(
          question: "How do I integrate Firebase with my Flutter app?",
          answers: 3,
          likes: 10,
          user: "User123",
          toWhom: "Everyone",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
        buildQuestionCard(
          question: "What's the best way to manage state in Flutter?",
          answers: 5,
          likes: 25,
          user: "User456",
          toWhom: "User789",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
        buildQuestionCard(
          question: "What's the best way to optimize Flutter API calls?",
          answers: 4,
          likes: 18,
          user: "UserAPI",
          toWhom: "Everyone",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
        buildQuestionCard(
          question: "What’s the best recipe for making pasta?",
          answers: 5,
          likes: 35,
          imageUrl: 'https://via.placeholder.com/150',
          user: "Foodie123",
          toWhom: "Everyone",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
      ],
    );
  }

  Widget buildGeneralQuestionsSection() {
    return ListView(
      key: const ValueKey('GeneralQuestions'),
      children: [
        buildQuestionCard(
          question: "Any tips on optimizing API calls in Flutter?",
          answers: 2,
          likes: 15,
          user: "User789",
          toWhom: "Everyone",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
        buildQuestionCard(
          question: "How to improve app performance in Flutter?",
          answers: 4,
          likes: 20,
          user: "UserGeneral1",
          toWhom: "Community",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
        buildQuestionCard(
          question: "Best way to integrate a payment gateway in Flutter?",
          answers: 5,
          likes: 25,
          user: "GeneralPayUser",
          toWhom: "Everyone",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
        buildQuestionCard(
          question: "What’s the best dessert recipe?",
          answers: 7,
          likes: 40,
          imageUrl: 'https://via.placeholder.com/150',
          user: "DessertLover",
          toWhom: "Everyone",
          userProfileUrl: 'https://via.placeholder.com/50', // Added profile picture URL
        ),
      ],
    );
  }

  Widget buildQuestionCard({
    required String question,
    required int answers,
    required int likes,
    String? imageUrl,
    required String user,
    required String toWhom,
    required String userProfileUrl, // Added profile picture URL
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => QuestionDetailPage(
              question: question,
              imageUrl: imageUrl,
              user: user,
              toWhom: toWhom,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(0.0, 1.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(1.0),
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: InkWell(
            splashColor: Colors.orange.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network('https://via.placeholder.com/150');
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(userProfileUrl), // Added profile picture
                          ),
                          const SizedBox(width: 10),
                          Text(
                            user, // Display username
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.045, // Scales with screen width
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.05, // Scales with screen width
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Asked by $user to $toWhom',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035, // Scales with screen width
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$answers Answers",
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.035, // Scales with screen width
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.thumb_up, color: Color(0xFFE67E22)),
                              const SizedBox(width: 5),
                              Text(
                                "$likes",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.04, // Scales with screen width
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionDetailPage extends StatelessWidget {
  final String question;
  final String? imageUrl;
  final String user;
  final String toWhom;

  const QuestionDetailPage({super.key, 
    required this.question,
    this.imageUrl,
    required this.user,
    required this.toWhom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl!, errorBuilder: (context, error, stackTrace) {
                return Image.network('https://via.placeholder.com/150');
              }),
            const SizedBox(height: 10),
            Text(
              question,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.06, // Scales with screen width
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Asked by $user to $toWhom',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035, // Scales with screen width
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
