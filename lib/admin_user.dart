import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 🔥 Firebase Admin Role Management
Future<void> setAdminRole(String uid) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'role': 'admin',
  });
}

Future<bool> isAdmin(User user) async {
  DocumentSnapshot doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  return doc.exists && doc['role'] == 'admin';
}

// 🔑 Admin Login Page
class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signInAdmin() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      bool admin = await isAdmin(userCredential.user!);
      if (admin) {
        Navigator.pushNamed(context, '/adminDashboard');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Access Denied")));
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Login")),
      body: Column(
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: "Password"),
            obscureText: true,
          ),
          ElevatedButton(onPressed: signInAdmin, child: Text("Login")),
        ],
      ),
    );
  }
}

// 🛠 Admin Dashboard for User Management
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['email']),
                subtitle: Text(doc['role']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => FirebaseFirestore.instance
                      .collection('users')
                      .doc(doc.id)
                      .delete(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// 🚀 Navigation Setup
void main() {
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => AdminLoginPage(),
        '/adminDashboard': (context) => AdminDashboard(),
      },
    ),
  );
}
