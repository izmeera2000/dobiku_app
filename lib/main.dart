import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'globals.dart'; // tempat anda define creditCardsNotifier
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Tambahkan global notifier untuk dark mode
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);
final ValueNotifier<String> languageNotifier = ValueNotifier<String>("en, ms");
final ValueNotifier<String> selectedLanguageNotifier = ValueNotifier("English");
final GlobalKey<_LaundryBasketSectionState> _basketKey =
    GlobalKey<_LaundryBasketSectionState>();

void fetchCards() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('credit_cards')
      .get();

  for (var doc in snapshot.docs) {
    print("Card: ${doc.data()}");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(DobikuApp());
}

class DobikuApp extends StatelessWidget {
  const DobikuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(lang),
              supportedLocales: const [Locale('en'), Locale('ms')],
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SignInScreen(),
            );
          },
        );
      },
    );
  }
}

// -----------------------------
// SIGN IN SCREEN
// -----------------------------
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _loginUser() async {
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan kata laluan diperlukan")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(email: email)),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akaun tidak dijumpai. Sila daftar dahulu."),
          ),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kata laluan salah.")));
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Format email tidak sah.")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Login gagal: \${e.message}")));
      }
    }
  }

  void _goToForgotPasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _goToRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Dobiku",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text("Login", style: GoogleFonts.poppins(fontSize: 20)),
                const SizedBox(height: 10),
                Text(
                  "Masukkan email dan kata laluan untuk log masuk",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Kata Laluan",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loginUser,
                  child: const Text("Login"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _goToForgotPasswordScreen,
                  child: const Text("Lupa Kata Laluan?"),
                ),
                TextButton(
                  onPressed: _goToRegisterScreen,
                  child: const Text("Belum ada akaun? Daftar di sini"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------
// REGISTER SCREEN
// -----------------------------
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _registerUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan kata laluan diperlukan.")),
      );
      return;
    }

    try {
      // Register the user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Get the user ID
      String uid = userCredential.user!.uid;

      // Add user info to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pendaftaran berjaya!")));

      Navigator.pop(context); // Kembali ke SignInScreen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pendaftaran gagal: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Akaun")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Kata Laluan",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text("Daftar"),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------
// FORGOT PASSWORD SCREEN
// -----------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  void _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sila masukkan email.")));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emel reset kata laluan telah dihantar.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ralat: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Kata Laluan")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text("Hantar Emel Reset"),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('role')) {
        return doc['role'];
      }
    }
    return 'user'; // Default role if not found
  }

  Future<void> _onRefresh() async {
    await Future.delayed(Duration(seconds: 1));
    print("Data refreshed!");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Default to 'user' if error or no data
        final role = snapshot.data ?? 'user';

        return Scaffold(
          backgroundColor: Colors.grey,
          appBar: AppBar(
            title: Text(
              "Welcome, $email!",
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            backgroundColor: Colors.deepPurpleAccent,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: selectedLanguageNotifier,
                  builder: (context, selectedLanguage, _) {
                    return Text(
                      selectedLanguage == "Malay" ? "Perkhidmatan" : "Services",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildServiceTile(
                      Icons.delivery_dining,
                      "Clothes pick up",
                      context,
                    ),
                    _buildServiceTile(Icons.payment, "DobiPay", context),
                    if (role == "admin")
                      _buildServiceTile(
                        Icons.admin_panel_settings,
                        "Admin Panel",
                        context,
                      ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        Profile(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                  ),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceTile(IconData icon, String title, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == "Clothes pick up") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClothesPickUpScreen()),
          );
        } else if (title == "DobiPay") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DobiPayScreen()),
          );
        } else if (title == "Admin Panel") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderListScreen()),
          );
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            SizedBox(height: 10),
            Text(title, style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders List"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;

              final int basketCount = order['basketCount'] ?? 0;
              final double basketPrice = (order['basketPrice'] ?? 0).toDouble();
              final double totalPrice = (order['totalPrice'] ?? 0).toDouble();
              final Timestamp timestamp = order['createdAt'];
              final DateTime createdAt = timestamp.toDate();

              final String pickupName = order['pickupName'] ?? '-';
              final String pickupPhone = order['pickupPhone'] ?? '-';
              final String pickupAddress = order['pickupAddress'] ?? '-';
              final String laundryOption = order['laundryOption'] ?? '-';
              final String laundryName = order['laundryName'] ?? '-';
              final String paymentMethod = order['paymentMethod'] ?? '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.shopping_basket,
                    color: Colors.green,
                    size: 40,
                  ),
                  title: Text("Basket Count: $basketCount"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Basket Price: RM ${basketPrice.toStringAsFixed(2)}",
                      ),
                      Text("Total Price: RM ${totalPrice.toStringAsFixed(2)}"),
                      Text(
                        "Created At: ${DateFormat.yMMMd().add_jm().format(createdAt)}",
                      ),
                      const SizedBox(height: 8),
                      Text("Pickup Name: $pickupName"),
                      Text("Pickup Phone: $pickupPhone"),
                      Text("Pickup Address: $pickupAddress"),
                      Text("Laundry Option: $laundryOption"),
                      Text("Laundry Name: $laundryName"),
                      Text("Payment Method: $paymentMethod"),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ClothesPickUpScreen extends StatefulWidget {
  const ClothesPickUpScreen({super.key});
  @override
  _ClothesPickUpScreenState createState() => _ClothesPickUpScreenState();
}

class _ClothesPickUpScreenState extends State<ClothesPickUpScreen> {
  String selectedLaundryOption = "Choose";
  String selectedPaymentMethod = "Visa ending in *1234";

  // Simpan data alamat yang dihantar dari AddAddressPage
  String? pickupName;
  String? pickupPhone;
  String? pickupAddress;

  // Simpan nama dobi yang dipilih dari NearbyLaundryScreen
  String? selectedLaundryName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Clothes Pick-Up",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Pickup Address"),

            // Paparkan alamat jika ada
            if (pickupAddress != null)
              Card(
                color: Colors.deepPurple[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    size: 30,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    "$pickupName\n$pickupPhone\n$pickupAddress",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),

            // Butang untuk tambah alamat
            _buildInfoCard("Add Address", Icons.add_location_alt, () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddAddressPage()),
              );

              if (result != null && result is Map) {
                setState(() {
                  pickupName = result['name'];
                  pickupPhone = result['phone'];
                  pickupAddress = result['address'];
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Alamat ditambah: ${result['name']}, ${result['address']}",
                    ),
                  ),
                );
              }
            }),

            _buildSectionTitle("Cari Dobi Sekitar"),

            // Paparkan nama dobi jika telah dipilih
            if (selectedLaundryName != null)
              Card(
                color: Colors.deepPurple[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_laundry_service,
                    size: 30,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    selectedLaundryName!,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),

            // Butang untuk cari dobi
            _buildInfoCard("Cari Dobi Berdekatan", Icons.search, () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NearbyLaundryScreen()),
              );
              if (result != null && result is String) {
                setState(() {
                  selectedLaundryName = result;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Dobi dipilih: $result")),
                );
              }
            }),

            _buildSectionTitle("Payment"),
            _buildInfoCard(selectedPaymentMethod, Icons.payment, () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentPage()),
              );
              if (result != null && result is String) {
                setState(() => selectedPaymentMethod = result);
              }
            }),

            _buildSectionTitle("Laundry Options"),
            _buildInfoCard(
              selectedLaundryOption,
              Icons.card_giftcard,
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LaundryOptionsPage()),
                );
                if (result != null && result is String) {
                  setState(() => selectedLaundryOption = result);
                }
              },
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Laundry Basket"),
            LaundryBasketSection(
              pickupName: pickupName,
              pickupPhone: pickupPhone,
              pickupAddress: pickupAddress,
              paymentMethod: selectedPaymentMethod,
              laundryOption: selectedLaundryOption,
              laundryName: selectedLaundryName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildInfoCard(String text, IconData icon, VoidCallback onTap) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: ListTile(
      leading: Icon(icon, size: 30, color: Colors.redAccent),
      title: Text(text, style: GoogleFonts.poppins(fontSize: 16)),
      onTap: onTap,
    ),
  );
}

// Placeholder pages
class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool isDefault = false;

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila lengkapkan semua maklumat")),
      );
      return;
    }

    final result = {
      'name': name,
      'phone': phone,
      'address': address,
      'isDefault': isDefault,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Alamat Baru"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputField("Nama Penerima", _nameController),
            const SizedBox(height: 12),
            _buildInputField(
              "Nombor Telefon",
              _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildInputField("Alamat Lengkap", _addressController, maxLines: 3),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Jadikan Alamat Ini Sebagai Default"),
              value: isDefault,
              onChanged: (value) => setState(() => isDefault = value),
              activeColor: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text("Simpan Alamat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    );
  }
}

class NearbyLaundryScreen extends StatefulWidget {
  const NearbyLaundryScreen({super.key});

  @override
  State<NearbyLaundryScreen> createState() => _NearbyLaundryScreenState();
}

class _NearbyLaundryScreenState extends State<NearbyLaundryScreen> {
  List<String> laundries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavedLaundries(); // ✅ Muat dobi manual dulu
    fetchNearbyLaundries(); // ✅ Kemudian dobi dari API
  }

  Future<void> loadSavedLaundries() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('manual_laundries') ?? [];
    setState(() {
      laundries.addAll(saved); // Manual dobi ditambah ke senarai
    });
  }

  Future<void> saveManualLaundry(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('manual_laundries') ?? [];
    saved.add(name);
    await prefs.setStringList('manual_laundries', saved);
  }

  Future<void> fetchNearbyLaundries() async {
    const apiKey = 'YOUR_GOOGLE_PLACES_API_KEY'; // Ganti dengan API key sebenar
    const location = '4.8500,100.7333'; // Kamunting
    const radius = 3000;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$location'
      '&radius=$radius'
      '&type=laundry'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'] as List;
        final fetchedNames = results
            .map((place) => place['name'].toString())
            .toList();
        setState(() {
          laundries.insertAll(0, fetchedNames); // Letak dobi API di atas
          isLoading = false;
        });
      } else {
        setState(() {
          laundries.insert(0, "Tiada dobi ditemui.");
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        laundries.insert(0, "Ralat semasa mengambil data.");
        isLoading = false;
      });
    }
  }

  void _showAddLaundryDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Nama Kedai Dobi"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: "Contoh: Dobi Segar Wangi",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => laundries.add(newName));
                await saveManualLaundry(newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Dobi ditambah: $newName")),
                );
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dobi Berdekatan"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: laundries.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.local_laundry_service),
                title: Text(laundries[index]),
                onTap: () {
                  Navigator.pop(context, laundries[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLaundryDialog,
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddLaundryPage extends StatefulWidget {
  const AddLaundryPage({super.key});

  @override
  State<AddLaundryPage> createState() => _AddLaundryPageState();
}

class _AddLaundryPageState extends State<AddLaundryPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  void _submit() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sila isi semua maklumat")));
      return;
    }

    final result = {'name': name, 'address': address};
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Kedai Dobi"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Kedai",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Alamat",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text("Simpan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Select Payment Method"),
            ValueListenableBuilder<List<String>>(
              valueListenable: creditCardsNotifier,
              builder: (context, cards, _) {
                return Column(
                  children: cards
                      .map((card) => _buildCardTile(card, context))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCardTile(String cardInfo, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(
          Icons.credit_card,
          size: 30,
          color: Colors.deepPurpleAccent,
        ),
        title: Text(cardInfo, style: GoogleFonts.poppins(fontSize: 16)),
        onTap: () {
          Navigator.pop(context, cardInfo);
        },
      ),
    );
  }
}

class LaundryOptionsPage extends StatelessWidget {
  const LaundryOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Laundry Options",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionButton(context, "Washing only"),
            _buildOptionButton(context, "Dry only"),
            _buildOptionButton(context, "Washing and dry"),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context, option); // Return selected option
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          textStyle: GoogleFonts.poppins(fontSize: 18),
        ),
        child: Text(option),
      ),
    );
  }
}

class LaundryBasketSection extends StatefulWidget {
  final String? pickupName;
  final String? pickupPhone;
  final String? pickupAddress;
  final String? paymentMethod;
  final String? laundryOption;
  final String? laundryName;

  const LaundryBasketSection({
    super.key,
    this.pickupName,
    this.pickupPhone,
    this.pickupAddress,
    this.paymentMethod,
    this.laundryOption,
    this.laundryName,
  });

  @override
  State<LaundryBasketSection> createState() => _LaundryBasketSectionState();
}

class _LaundryBasketSectionState extends State<LaundryBasketSection> {
  int basketCount = 1;
  double basketPrice = 7.85;

  double get totalPrice => basketCount * basketPrice;

  Map<String, dynamic> getOrderDetails() {
    return {
      'basketCount': basketCount,
      'basketPrice': basketPrice,
      'totalPrice': totalPrice,
    };
  }

  void _submitOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check address
    if (widget.pickupAddress == null ||
        widget.pickupName == null ||
        widget.pickupPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila tambah alamat dahulu.")),
      );
      return;
    }

    final orderData = {
      'userId': user.uid,
      'basketCount': basketCount,
      'basketPrice': basketPrice,
      'totalPrice': totalPrice,
      'pickupName': widget.pickupName,
      'pickupPhone': widget.pickupPhone,
      'pickupAddress': widget.pickupAddress,
      'paymentMethod': widget.paymentMethod,
      'laundryOption': widget.laundryOption,
      'laundryName': widget.laundryName,
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(orderData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesanan berjaya dihantar ke Firebase")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ralat: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Laundry Basket",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (basketCount > 1) {
                  setState(() {
                    basketCount--;
                  });
                }
              },
            ),
            Text(
              basketCount.toString(),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  basketCount++;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Price per basket: RM${basketPrice.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        Text(
          "Total Price: RM${totalPrice.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _submitOrder,
          icon: Icon(Icons.shopping_cart),
          label: Text("Pesan"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            textStyle: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// Global list to store credit cards dynamically
List<String> creditCards = [
  "Visa ending in *1234",
  "Mastercard ending in *5678",
];

class DobiPayScreen extends StatelessWidget {
  const DobiPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DobiPay",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Payment Methods"),
              _buildInfoCard("Credit Card*1234", Icons.payment, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.deepPurpleAccent),
        title: Text(text, style: GoogleFonts.poppins(fontSize: 16)),
        onTap: () {
          if (text.contains("Credit Card")) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageCardsScreen()),
            );
          }
        },
      ),
    );
  }
}

// New Page: Manage Credit Cards
class ManageCardsScreen extends StatefulWidget {
  const ManageCardsScreen({super.key});

  @override
  _ManageCardsScreenState createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Cards"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ValueListenableBuilder<List<String>>(
              valueListenable: creditCardsNotifier,
              builder: (context, cards, _) {
                return Column(
                  children: cards.map((card) => _buildCardTile(card)).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newCard = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCardScreen(),
                  ),
                );
                if (newCard != null) {
                  creditCardsNotifier.value = List.from(
                    creditCardsNotifier.value,
                  )..add(newCard);
                }
              },
              child: const Text("Add New Card"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(String cardInfo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(
          Icons.credit_card,
          size: 30,
          color: Colors.deepPurpleAccent,
        ),
        title: Text(cardInfo, style: GoogleFonts.poppins(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            creditCardsNotifier.value = List.from(creditCardsNotifier.value)
              ..remove(cardInfo);
          },
        ),
      ),
    );
  }
}

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Kad"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        // ✅ Tambah scroll untuk elak overflow
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Nombor Kad",
                prefixIcon: const Icon(Icons.credit_card),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    // Tambah logik kamera jika perlu
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      hintText: "BB/TT",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "CVV/CVV2",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final cardNumber = _cardNumberController.text.trim();
                  if (cardNumber.isNotEmpty && cardNumber.length >= 4) {
                    final last4Digits = cardNumber.substring(
                      cardNumber.length - 4,
                    );
                    final newCard = "Card ending in *$last4Digits";

                    // Simpan ke Firebase
                    await FirebaseFirestore.instance
                        .collection('credit_cards')
                        .add({'card': newCard});

                    // Kemas kini local notifier
                    creditCardsNotifier.value = [
                      ...creditCardsNotifier.value,
                      newCard,
                    ];

                    // Kembali ke skrin sebelumnya
                    Navigator.pop(context, newCard);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sila masukkan nombor kad yang sah.'),
                      ),
                    );
                  }
                },
                child: const Text("Simpan Kad"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileOption(Icons.settings, "Settings", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }),
            _buildProfileOption(Icons.feedback, "Feedback", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            }),
            _buildProfileOption(Icons.logout, "Sign Out", () {
              SignOutHelper.showSignOutDialog(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.deepPurpleAccent),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 18)),
        onTap: onTap,
      ),
    );
  }
}

// ------------------ SETTINGS PAGE ------------------

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Map<String, String>> languageOptions = [
    {"label": "English", "value": "English"},
    {"label": "Bahasa Malaysia", "value": "Malay"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingsOption(
              Icons.language,
              "Language",
              DropdownButton<String>(
                value: selectedLanguageNotifier.value,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedLanguageNotifier.value = newValue;
                    });
                  }
                },
                items: languageOptions
                    .map(
                      (item) => DropdownMenuItem(
                        value: item["value"],
                        child: Text(item["label"]!),
                      ),
                    )
                    .toList(),
              ),
            ),
            _buildSettingsOption(
              Icons.dark_mode,
              "Dark Mode",
              Switch(
                value: isDarkModeNotifier.value,
                onChanged: (value) {
                  setState(() {
                    isDarkModeNotifier.value = value;
                  });
                },
              ),
            ),
            _buildSettingsOption(
              Icons.track_changes,
              "Tracking",
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackingPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    IconData icon,
    String title,
    Widget trailingWidget,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.deepPurpleAccent),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 18)),
        trailing: trailingWidget,
      ),
    );
  }
}

// ------------------ FEEDBACK PAGE ------------------

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Feedback",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Center(
        child: Text("Feedback Page", style: GoogleFonts.poppins(fontSize: 18)),
      ),
    );
  }
}

// ------------------ TRACKING PAGE ------------------

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  final List<Map<String, dynamic>> trackingSteps = const [
    {'status': 'Pakaian Diterima', 'icon': Icons.inbox, 'completed': true},
    {
      'status': 'Sedang Dicuci',
      'icon': Icons.local_laundry_service,
      'completed': true,
    },
    {
      'status': 'Sedang Dikeringkan',
      'icon': Icons.wb_sunny,
      'completed': false,
    },
    {
      'status': 'Siap Dilipat',
      'icon': Icons.check_circle_outline,
      'completed': false,
    },
    {
      'status': 'Dalam Penghantaran',
      'icon': Icons.delivery_dining,
      'completed': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tracking Proses",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: trackingSteps.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final step = trackingSteps[index];
          return ListTile(
            leading: Icon(
              step['icon'],
              color: step['completed'] ? Colors.green : Colors.grey,
              size: 32,
            ),
            title: Text(
              step['status'],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: step['completed'] ? Colors.black : Colors.grey,
              ),
            ),
            trailing: Icon(
              step['completed']
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: step['completed'] ? Colors.green : Colors.grey,
            ),
          );
        },
      ),
    );
  }
}

class SignOutHelper {
  static void showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            },
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }
}
