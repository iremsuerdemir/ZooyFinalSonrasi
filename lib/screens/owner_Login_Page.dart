import 'package:flutter/material.dart';
import 'package:zoozy/screens/explore_screen.dart';
import 'package:zoozy/screens/forgot_password.dart';
import 'package:zoozy/screens/privacy_policy_page.dart';
import 'package:zoozy/screens/register_page.dart';
import 'package:zoozy/screens/terms_of_service_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoozy/services/guest_access_service.dart';
import 'package:zoozy/services/auth_service.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  /// BACKEND API ile email/şifre login
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        ScaffoldMessenger.of(context).clearSnackBars();

        // Backend API'ye POST isteği
        final response = await _authService.login(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (response.success && response.user != null) {
          // Başarılı login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', response.user!.displayName);
          await prefs.setString('email', response.user!.email.toLowerCase());
          await GuestAccessService.disableGuestMode();

          bool needsApproval = response.user != null &&
              (!response.user!.termsAccepted ||
                  !response.user!.privacyAccepted);

          if (!needsApproval) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  "Giriş başarılı! ${response.user!.displayName}. Yönlendiriliyorsunuz...",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
            await Future.delayed(const Duration(seconds: 2));
          }

          if (mounted) {
            if (needsApproval) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const TermsOfServicePage(showBackButton: false)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ExploreScreen()),
              );
            }
          }
        } else {
          // Başarısız login: Eğer Google uyarısı ise Sarı, değilse Kırmızı göster
          final isGoogleWarning = response.message.contains("Google");
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message,
                // Sarı arka planda siyah yazı daha okunaklı olur
                style: TextStyle(
                  color: isGoogleWarning ? Colors.black87 : Colors.white,
                  fontWeight: isGoogleWarning ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: isGoogleWarning ? Colors.amber : Colors.red,
              duration: Duration(seconds: isGoogleWarning ? 6 : 3), // Uyarı mesajı daha uzun ekranda kalsın
              behavior: SnackBarBehavior.floating,
              margin: isGoogleWarning ? const EdgeInsets.all(10) : null,
              shape: isGoogleWarning 
                  ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  : null,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  /// BACKEND API ile Google login
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      ScaffoldMessenger.of(context).clearSnackBars();

      final FirebaseAuth auth = FirebaseAuth.instance;
      final GoogleSignIn googleSignIn = GoogleSignIn();

      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await auth.signInWithCredential(credential);
      } else {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider
          ..addScope('email')
          ..addScope('profile');

        await auth.signInWithPopup(googleProvider);
      }

      final user = auth.currentUser;

      if (user != null && mounted) {
        // Firebase bilgilerini backend'e gönder
        final response = await _authService.googleLogin(
          firebaseUid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Kullanıcı',
          photoUrl: user.photoURL,
        );

        if (response.success && response.user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', response.user!.displayName);
          await prefs.setString('email', response.user!.email.toLowerCase());
          await prefs.setString('firebaseUid', user.uid);
          await GuestAccessService.disableGuestMode();

          bool needsApproval = response.user != null &&
              (!response.user!.termsAccepted ||
                  !response.user!.privacyAccepted);

          if (!needsApproval) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  "Google ile giriş başarılı! Hoş geldiniz ${response.user!.displayName}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
            await Future.delayed(const Duration(seconds: 2));
          }

          if (mounted) {
            if (needsApproval) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const TermsOfServicePage(showBackButton: false)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ExploreScreen()),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google ile giriş başarısız: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// -------------------------------
  /// UI
  /// -------------------------------
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: Text(
            "Giriş Yap",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2A4FF), Color(0xFFFFC1C1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top +
                AppBar().preferredSize.height +
                28,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "E-posta",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF7A4FAD),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen e-posta adresinizi girin.';
                    }
                    if (!RegExp(
                      r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Şifre",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF7A4FAD),
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF7A4FAD),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen şifrenizi girin.';
                    }
                    if (value.trim().length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                /// -------------------------
                /// LOGIN BUTTON (GÜNCELLENDİ)
                /// -------------------------
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isLoading ? Colors.grey : const Color(0xFF7A4FAD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "E-posta ile Giriş Yap",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      final email = _emailController.text.trim();

                      // Email girilmişse o email'i ForgotPassword sayfasına gönder
                      if (email.isNotEmpty &&
                          RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                              .hasMatch(email)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ForgotPassword(initialEmail: email),
                          ),
                        );
                      } else {
                        // Email girilmemişse uyarı göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Lütfen önce e-posta adresinizi girin."),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Şifrenizi mi unuttunuz?",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "veya ile devam et",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _isLoading ? null : _signInWithGoogle,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.network(
                            "https://cdn-icons-png.flaticon.com/512/300/300221.png",
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Hesabınız yok mu? ",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          color: Color(0xFF7A4FAD),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF7A4FAD),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Kayıt Ol veya Giriş Yap’a tıklayarak, Hizmet Şartları ve Gizlilik Politikası’nı kabul etmiş oluyorum.",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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
