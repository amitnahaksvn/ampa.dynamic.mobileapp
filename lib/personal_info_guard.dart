import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'personal_info_page.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'dart:convert';

class PersonalInfoGuard extends StatefulWidget {
  final Widget child;
  const PersonalInfoGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<PersonalInfoGuard> createState() => _PersonalInfoGuardState();
}

class _PersonalInfoGuardState extends State<PersonalInfoGuard> {
  bool _loading = true;
  bool _hasPersonalInfo = false;
  late User _user;

  @override
  void initState() {
    super.initState();
    _checkPersonalInfo();
  }

  Future<void> _checkPersonalInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _hasPersonalInfo = false;
      });
      return;
    }
    _user = user;
    final url = Uri.parse('${ApiConfig.userInfo}/${user.uid}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['firstName'] != null && data['lastName'] != null && data['gender'] != null && data['dob'] != null && data['email'] != null && data['localization'] != null) {
        setState(() {
          _hasPersonalInfo = true;
          _loading = false;
        });
        return;
      }
    }
    setState(() {
      _hasPersonalInfo = false;
      _loading = false;
    });
  }

  void _onPersonalInfoComplete() {
    setState(() {
      _hasPersonalInfo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasPersonalInfo) {
      return PersonalInfoPage(user: _user, onComplete: _onPersonalInfoComplete);
    }
    return widget.child;
  }
}
