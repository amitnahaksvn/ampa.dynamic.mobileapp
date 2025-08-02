import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, FilteringTextInputFormatter;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> saveOrUpdateUser(User user, {required bool isInsert}) async {
    final userData = {
      "uid": user.uid,
      "email": user.email ?? "",
      "emailVerified": user.emailVerified,
      "displayName": user.displayName ?? "",
      "photoUrl": user.photoURL ?? "",
      "phoneNumber": user.phoneNumber ?? "",
      "disabled": false,
      "providerId": user.providerData.isNotEmpty ? user.providerData[0].providerId : "",
      "customClaims": {},
      "creationTime": user.metadata.creationTime?.toIso8601String() ?? "",
      "lastSignInTime": user.metadata.lastSignInTime?.toIso8601String() ?? "",
    };

    if (isInsert) {
      // Insert new user
      await http.post(
        Uri.parse(ApiConfig.userAuth),
        headers: {
          'accept': 'application/octet-stream',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );
    } else {
      // Update existing user with full userData
      await http.put(
        Uri.parse(ApiConfig.userAuth),
        headers: {
          'accept': 'application/octet-stream',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );
    }
  }
  bool _welcomeShown = false;
  @override
  void initState() {
    super.initState();
    _loadCountries();
  }
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isSendingOtp = false;
  String _verificationId = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, String>> _countries = [];
  String _selectedCountryCode = '';
  bool _isPhoneNumberValid = false;
  bool _isOtpValid = false;
  bool _isOtpSubmitting = false;

  Future<void> _loadCountries() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/countries.json',
      );
      final List<dynamic> data = json.decode(response);
      if (mounted) {
        setState(() {
          _countries = data.map((e) => Map<String, String>.from(e)).toList();
        });
        await _setCountryCodeFromLocale();
      }
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }

  Future<void> _setCountryCodeFromLocale() async {
    // Hard code +91 to be selected in dropdown
    if (_countries.isNotEmpty) {
      final match = _countries.firstWhere(
        (c) => c['code'] == '+91',
        orElse: () => _countries.first,
      );
      setState(() {
        _selectedCountryCode = match['code'] ?? _countries.first['code']!;
      });
    }
  }

  String _countryCodeFromFlag(String flag) {
    // Convert flag emoji to country code (e.g., 🇮🇳 -> IN)
    // Unicode math: each flag char is 0x1F1E6 + (A-Z)
    if (flag.runes.length == 2) {
      final int base = 0x1F1E6;
      final chars = flag.runes.map((r) => String.fromCharCode(r - base + 65)).join();
      return chars;
    }
    return '';
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSendingOtp = true;
      });
      final phoneNumber = '$_selectedCountryCode${_phoneNumberController.text}';
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber, // Add your country code
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              _isPhoneNumberValid = false;
              _otpSent = false;
              _isSendingOtp = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification Failed: ${e.message ?? "Unknown error"}')),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isSendingOtp = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OTP sent to ${_phoneNumberController.text}'),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      } catch (e) {
        setState(() {
          _isPhoneNumberValid = false;
          _otpSent = false;
          _isSendingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending OTP: ${e.toString()}')),
        );
      }
    } else {
      setState(() {
        _isSendingOtp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number.')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length == 6) {
      setState(() {
        _isOtpSubmitting = true;
      });
      try {
        print('====== VERIFY OTP STARTED ======');
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _otpController.text,
        );
        
        print('Authenticating with Firebase...');
        final result = await _auth.signInWithCredential(credential);
        final user = result.user;
        final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
        
        print('Authentication successful. User: ${user?.uid}, isNewUser: $isNewUser');
        
        // Let the main app handle user_auth verification
        // No need to call saveOrUpdateUser here since RootAuthHandler will handle it
        
        if (mounted) {
          print('Navigating to home after successful login');
          // Let the natural auth flow handle navigation
          // Just return to root which will trigger the auth state change
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/',
            (route) => false,
          );
          
          // Show toastr after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          });
        }
        print('====== VERIFY OTP COMPLETED ======');
      } catch (e) {
        print('ERROR in _verifyOtp: $e');
        setState(() {
          _isOtpSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP or authentication error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
    }
  }

  void _validatePhoneNumber(String value) {
    final wasValid = _isPhoneNumberValid;
    final isNowValid = value.isNotEmpty && value.length >= 10;
    setState(() {
      _isPhoneNumberValid = isNowValid;
    });
    // Only auto-send OTP when becoming valid, not on every change
    if (!wasValid && isNowValid) {
      _sendOtp();
    }
  }

  void _onOtpChanged(String value) {
    setState(() {
      _isOtpValid = value.length == 6;
    });
    if (value.length == 6 && !_isOtpSubmitting) {
      _submitOtpAuto();
    }
  }

  Future<void> _submitOtpAuto() async {
    setState(() {
      _isOtpSubmitting = true;
    });
    try {
      print('====== AUTO SUBMIT OTP STARTED ======');
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
      
      print('Authenticating with Firebase...');
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
      
      print('Authentication successful. User: ${user?.uid}, isNewUser: $isNewUser');
      
      // Let the main app handle user_auth verification
      // No need to call saveOrUpdateUser here since RootAuthHandler will handle it
      
      if (mounted) {
        print('Navigating to home after successful auto login');
        // Let the natural auth flow handle navigation
        // Just return to root which will trigger the auth state change
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/',
          (route) => false,
        );
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        });
      }
      print('====== AUTO SUBMIT OTP COMPLETED ======');
    } catch (e) {
      print('ERROR in _submitOtpAuto: $e');
      setState(() {
        _isOtpSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP or authentication error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show welcome SnackBar only once after build
    if (!_welcomeShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (FirebaseAuth.instance.currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Welcome Boss'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Close',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
              // No duration: stays until closed
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Home'),
            ),
          );
        }
      });
      _welcomeShown = true;
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF833ab4),
              Color(0xFFfd1d1d),
              Color(0xFFfcb045),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Instagram-style logo text
                const Text(
                  'AmPa',
                  style: TextStyle(
                    fontFamily: 'Billabong', // Use a custom font if available
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCountryCode,
                                  decoration: const InputDecoration(
                                    labelText: 'Country',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: _countries.map((country) {
                                    final flag = country['flag'] ?? '';
                                    final code = country['code'] ?? '';
                                    final name = country['name'] ?? '';
                                    return DropdownMenuItem<String>(
                                      value: code,
                                      child: Row(
                                        children: [
                                          Text(flag, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 8),
                                          Text(code, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (context) {
                                    return _countries.map((country) {
                                      final flag = country['flag'] ?? '';
                                      final code = country['code'] ?? '';
                                      return Row(
                                        children: [
                                          Text(flag, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 8),
                                          Text(code, style: const TextStyle(fontSize: 14)),
                                        ],
                                      );
                                    }).toList();
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCountryCode = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 3,
                                child: TextFormField(
                                  controller: _phoneNumberController,
                                  enabled: !_otpSent,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    prefixIcon: const Icon(Icons.phone_android),
                                    counterText: '', // Hide the 0/10 counter
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: _validatePhoneNumber,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    if (value.length != 10) {
                                      return 'Phone number must be exactly 10 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (!_otpSent)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3897f0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: (_isPhoneNumberValid && !_isSendingOtp) ? _sendOtp : null,
                                child: _isSendingOtp
                                  ? const Text('Sending OTP...')
                                  : const Text('Send OTP'),
                              ),
                            ),
                          if (_otpSent) ...[
                            TextFormField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: 'Enter OTP',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              onChanged: _onOtpChanged,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: const BorderSide(color: Color(0xFF3897f0)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _otpSent = false;
                                      _otpController.clear();
                                      _isOtpValid = false;
                                      _isOtpSubmitting = false;
                                    });
                                  },
                                  child: const Text('Change Number'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3897f0),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: _isOtpValid && !_isOtpSubmitting ? _verifyOtp : null,
                                  child: _isOtpSubmitting
                                    ? const Text('Validating...')
                                    : const Text('Verify OTP'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Instagram-style footer
                const Text(
                  '© 2025 Dynamic from AmPa',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
