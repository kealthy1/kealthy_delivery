import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kealthy_delivery/Pages/LandingPages/SearchOrders.dart';
import '../../Riverpod/custom_toast.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);

class LoginFields extends ConsumerStatefulWidget {
  const LoginFields({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginFields> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkPhoneNumber();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('ID');

    if (phoneNumber != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnlinePage()),
      );
    }
  }

  Future<void> _saveUserData(String id, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ID', id);
    await prefs.setString('userId', userId);
  }

  Future<void> _login() async {
    ref.read(isLoadingProvider.notifier).state = true;
    try {
      final phoneNumber = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final userCollection =
          FirebaseFirestore.instance.collection('DeliveryUsers');
      final snapshot = await userCollection
          .where('ID', isEqualTo: phoneNumber)
          .where('Password', isEqualTo: password)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();

        await _saveUserData(userData['ID'], snapshot.docs.first.id);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnlinePage()),
        );
      } else {
        showCustomToast(
          context,
          "Invalid phone number or password",
        );
      }
    } catch (e) {
      showCustomToast(
        context,
        "Error Cant Login",
      );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.width * 0.3,
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth < 400
                            ? constraints.maxWidth
                            : 400,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10.0,
                              spreadRadius: 5.0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: constraints.maxWidth * 0.05,
                                      height: constraints.maxWidth * 0.05,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: constraints.maxWidth * 0.05,
                                      height: constraints.maxWidth * 0.05,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade700,
                                        shape: BoxShape.circle,
                                      ),
                                      margin: const EdgeInsets.only(left: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontFamily: "poppins",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Greetings Delivery Partner',
                              style: TextStyle(
                                fontFamily: "poppins",
                                fontSize: constraints.maxWidth * 0.05,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _phoneController,
                              hintText: 'Phone Number',
                              prefixIcon:
                                  const Icon(CupertinoIcons.person_circle_fill),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              prefixIcon:
                                  const Icon(CupertinoIcons.lock_circle),
                              isObscure: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _login();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                minimumSize: const Size(double.infinity, 0),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hintText;
  final Widget prefixIcon;
  final bool isObscure;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isObscure = false,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        prefixIconColor: Colors.black38,
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: "poppins",
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
