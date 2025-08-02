import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class PersonalInfoPage extends StatefulWidget {
  final User user;
  final VoidCallback onComplete;
  const PersonalInfoPage({Key? key, required this.user, required this.onComplete}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  @override
  void dispose() {
    _localizationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  bool _infoExists = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  String? _gender;
  String? _localization;
  final _localizationController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email ?? '';
    _loadLocalization().then((_) {
      setState(() {});
    });
    _fetchPersonalInfo().then((_) {
      if (_infoExists) {
        // If personal information exists, navigate to the main page using the callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete();
        });
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _loadLocalization() async {
    final prefs = await SharedPreferences.getInstance();
    String? loc = prefs.getString('localization');
    if (loc == null || loc.isEmpty) {
      // Try to get device locale if not set in prefs
      try {
        final locale = WidgetsBinding.instance.window.locale;
        loc = locale.languageCode;
      } catch (_) {
        loc = 'en'; // fallback
      }
      await prefs.setString('localization', loc);
    }
    _localization = loc;
    _localizationController.text = _localization ?? '';
  }

  Future<void> _saveLocalization(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localization', value);
  }

  Future<void> _fetchPersonalInfo() async {
    setState(() { _loading = true; });
    final url = Uri.parse('${ApiConfig.userInfo}/${widget.user.uid}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _gender = data['gender'];
      _localization = data['localization'] ?? _localization;
      _localizationController.text = _localization ?? '';
      if (data['dateOfBirth'] != null && data['dateOfBirth'].toString().contains('-')) {
        final parts = data['dateOfBirth'].split('-');
        if (parts.length == 3) {
          _selectedYear = int.tryParse(parts[0]);
          _selectedMonth = int.tryParse(parts[1]);
          _selectedDay = int.tryParse(parts[2]);
        }
      } else {
        _selectedYear = null;
        _selectedMonth = null;
        _selectedDay = null;
      }
      // Only set _infoExists true if ALL required fields are present and non-empty
      _infoExists = (_firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _gender != null && _gender!.isNotEmpty &&
          _selectedYear != null && _selectedMonth != null && _selectedDay != null &&
          _localization != null && _localization!.isNotEmpty);
      setState(() {});
    } else {
      // If not 200, treat as no info exists
      _firstNameController.text = '';
      _lastNameController.text = '';
      _emailController.text = '';
      _gender = null;
      _localization = _localization ?? '';
      _localizationController.text = _localization ?? '';
      _selectedYear = null;
      _selectedMonth = null;
      _selectedDay = null;
      _infoExists = false;
      setState(() {});
    }
    setState(() { _loading = false; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    String? dob = (_selectedYear != null && _selectedMonth != null && _selectedDay != null)
        ? '${_selectedYear!.toString().padLeft(4, '0')}-${_selectedMonth!.toString().padLeft(2, '0')}-${_selectedDay!.toString().padLeft(2, '0')}'
        : null;
    final data = {
      'uid': widget.user.uid,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'dateOfBirth': dob, // match your C# model property name
      'gender': _gender,
      'localization': _localization,
    };
    print('Submitting data:');
    print(data);
    await _saveLocalization(_localization ?? '');
    http.Response res;
    if (_infoExists) {
      // Update existing info (PUT)
      final url = Uri.parse('${ApiConfig.userInfo}/${widget.user.uid}');
      res = await http.put(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 404) {
        // If not found, fallback to POST (create)
        final postUrl = Uri.parse(ApiConfig.userInfo);
        res = await http.post(postUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
      }
    } else {
      // Add new info (POST)
      final url = Uri.parse(ApiConfig.userInfo);
      res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    }
    setState(() { _loading = false; });
    if (res.statusCode == 200 || res.statusCode == 201) {
      widget.onComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save info: ${res.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _infoExists
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text('Personal information already submitted!', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: widget.onComplete,
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'First Name'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          // Email is now optional
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedDay,
                                items: List.generate(31, (i) => i + 1)
                                    .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedDay = v),
                                decoration: const InputDecoration(labelText: 'Day'),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedMonth,
                                items: List.generate(12, (i) => i + 1)
                                    .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text([
                                            'January',
                                            'February',
                                            'March',
                                            'April',
                                            'May',
                                            'June',
                                            'July',
                                            'August',
                                            'September',
                                            'October',
                                            'November',
                                            'December',
                                          ][m - 1]),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedMonth = v),
                                decoration: const InputDecoration(labelText: 'Month'),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final selected = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      final years = List.generate(100, (i) => DateTime.now().year - i);
                                      TextEditingController searchController = TextEditingController();
                                      List<int> filteredYears = List.from(years);
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title: const Text('Select Year'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: searchController,
                                                  decoration: const InputDecoration(hintText: 'Search year'),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      filteredYears = years
                                                          .where((y) => y.toString().contains(val))
                                                          .toList();
                                                    });
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  height: 200,
                                                  width: 80,
                                                  child: ListView.builder(
                                                    itemCount: filteredYears.length,
                                                    itemBuilder: (context, idx) {
                                                      final y = filteredYears[idx];
                                                      return ListTile(
                                                        title: Text(y.toString()),
                                                        onTap: () => Navigator.of(context).pop(y),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                  if (selected != null) {
                                    setState(() => _selectedYear = selected);
                                  }
                                },
                                child: AbsorbPointer(
                                  child: DropdownButtonFormField<int>(
                                    value: _selectedYear,
                                    items: _selectedYear != null
                                        ? [DropdownMenuItem(value: _selectedYear, child: Text(_selectedYear.toString()))]
                                        : [],
                                    onChanged: (_) {},
                                    decoration: const InputDecoration(labelText: 'Year'),
                                    validator: (v) => v == null ? 'Required' : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                          decoration: const InputDecoration(labelText: 'Gender'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Text('Localization:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text((_localization != null && _localization!.isNotEmpty) ? _localization! : 'Not set',
                                  style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
