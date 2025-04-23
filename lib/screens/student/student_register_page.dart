import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({Key? key}) : super(key: key);

  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _selectedFacultyId;
  String? _selectedDepartmentId;

  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _programmeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedCampus;
  final List<String> _campuses = ['Kigali', 'Nyanza', 'Rwamagane'];

  bool _isLoading = false;
  bool _fingerprintRegistered = false;

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Create user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Fetch faculty name from faculties collection
        String? facultyName;
        if (_selectedFacultyId != null) {
          final facultyDoc = await FirebaseFirestore.instance.collection('faculties').doc(_selectedFacultyId).get();
          if (facultyDoc.exists) {
            final data = facultyDoc.data() as Map<String, dynamic>?;
            facultyName = data?['name'];
          }
        }

        // Fetch department name from departments collection
        String? departmentName;
        if (_selectedDepartmentId != null) {
          final departmentDoc = await FirebaseFirestore.instance.collection('departments').doc(_selectedDepartmentId).get();
          if (departmentDoc.exists) {
            final data = departmentDoc.data() as Map<String, dynamic>?;
            departmentName = data?['name'];
          }
        }

        // Save additional user info in Firestore with names instead of IDs
        await FirebaseFirestore.instance.collection('students').doc(userCredential.user?.uid).set({
          'registrationNumber': _regNumberController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'campus': _selectedCampus,
          'phone': _phoneController.text.trim(),
          'country': _countryController.text.trim(),
          'faculty': facultyName,
          'department': departmentName,
          'programme': _programmeController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'student',
          'fingerprintRegistered': _fingerprintRegistered,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student registered successfully and email sent')),
        );
        Navigator.of(context).pop(); // Go back after successful registration
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Removed _fetchFaculties call since StreamBuilder is used now
  }

  // Removed _fetchFaculties and _fetchDepartments methods to use StreamBuilder instead


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _regNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number (e.g. 20136/2022)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Registration Number';
                  }
                  if (!RegExp(r'^\d{5}/\d{4}$').hasMatch(value)) {
                    return 'Enter a valid Registration Number (e.g. 20136/2022)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter First Name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Middle Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Last Name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Campus',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCampus,
                items: _campuses
                    .map((campus) => DropdownMenuItem(
                          value: campus,
                          child: Text(campus),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCampus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a campus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Phone number';
                  }
                  if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Country';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('faculties').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final faculties = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedFacultyId,
                    items: faculties.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: data['name'],
                        child: Text(data['name'] ?? 'No Name'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFacultyId = value;
                        _selectedDepartmentId = null;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select Faculty';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              (_selectedFacultyId == null)
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Please select a faculty first',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('departments')
                          .where('facultyName', isEqualTo: _selectedFacultyId)
                          //.orderBy('name') // Removed to avoid composite index error
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Error loading departments: \${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final departments = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedDepartmentId,
                          items: departments.isEmpty
                              ? [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('No departments available'),
                                  )
                                ]
                              : departments.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: data['name'],
                                    child: Text(data['name'] ?? 'No Name'),
                                  );
                                }).toList(),
                          onChanged: departments.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedDepartmentId = value;
                                  });
                                },
                          validator: (value) {
                            if (departments.isNotEmpty && (value == null || value.isEmpty)) {
                              return 'Please select Department';
                            }
                            return null;
                          },
                        );
                      },
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _programmeController,
                decoration: const InputDecoration(
                  labelText: 'Programme',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Programme';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Email';
                  }
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
