import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: SplashScreen(),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Welcome to Chat App",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Login Page
class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomePage()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () => login(context), child: Text("Login")),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage())),
              child: Text("Register"),
            )
          ],
        ),
      ),
    );
  }
}

// Register Page
class RegisterPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  void register(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final cred = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await firestore.collection("users").doc(cred.user!.uid).set({
        "uid": cred.user!.uid,
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "role": "user",
        "registrationDate": DateTime.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: firstNameController, decoration: InputDecoration(labelText: "First Name")),
              TextField(controller: lastNameController, decoration: InputDecoration(labelText: "Last Name")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
              SizedBox(height: 16),
              ElevatedButton(onPressed: () => register(context), child: Text("Register")),
            ],
          ),
        ),
      ),
    );
  }
}

// Home Page with Navigation Drawer + Boards
class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> boards = [
    {'name': 'Games', 'icon': Icons.videogame_asset},
    {'name': 'Business', 'icon': Icons.business_center},
    {'name': 'Public Health', 'icon': Icons.health_and_safety},
    {'name': 'Study', 'icon': Icons.menu_book},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Message Boards")),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Welcome!", style: TextStyle(fontSize: 20))),
            ListTile(
              leading: Icon(Icons.forum),
              title: Text("Message Boards"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile page coming soon."))),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () => FirebaseAuth.instance.signOut().then((_) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
              }),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: boards.length,
        itemBuilder: (context, index) {
          final board = boards[index];
          return ListTile(
            leading: Icon(board['icon']),
            title: Text(board['name']),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatPage(boardName: board['name'])),
            ),
          );
        },
      ),
    );
  }
}

// Chat Page
class ChatPage extends StatelessWidget {
  final String boardName;
  final msgController = TextEditingController();

  ChatPage({required this.boardName});

  void sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && msgController.text.trim().isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final displayName = '${userDoc['firstName']} ${userDoc['lastName']}';

      await FirebaseFirestore.instance.collection('messages_$boardName').add({
        'text': msgController.text.trim(),
        'user': displayName,
        'timestamp': DateTime.now(),
      });
      msgController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(boardName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages_$boardName')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index];
                    return ListTile(
                      title: Text(msg['user']),
                      subtitle: Text(msg['text']),
                      trailing: Text(
                        (msg['timestamp'] as Timestamp).toDate().toLocal().toString().substring(0, 16),
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(child: TextField(controller: msgController, decoration: InputDecoration(hintText: "Type a message..."))),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}