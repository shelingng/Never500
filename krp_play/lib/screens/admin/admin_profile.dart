import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;
  String _memberSinceLabel = 'KRP Sports Unit · Facility Administrator';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No logged-in admin session found.')),
          );
        }
        return;
      }

      _userId = user.id;

      final Map<String, dynamic>? row = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final meta = user.userMetadata ?? const <String, dynamic>{};

      final fullName = (row?['full_name'] ??
              meta['full_name'] ??
              user.email?.split('@').first ??
              'Facility Admin')
          .toString()
          .trim();

      final staffId = (row?['matric_number'] ??
              row?['staff_id'] ??
              meta['matric_number'] ??
              meta['staff_id'] ??
              '')
          .toString()
          .trim();

      final email = (row?['email'] ?? user.email ?? '').toString().trim();

      final contact = (row?['phone_number'] ??
              row?['contact_number'] ??
              meta['phone_number'] ??
              meta['contact_number'] ??
              '')
          .toString()
          .trim();

      final createdRaw = (row?['created_at'] ?? user.createdAt).toString();
      final parsedDate = DateTime.tryParse(createdRaw);
      if (parsedDate != null) {
        _memberSinceLabel =
            'KRP Sports Unit · Administrator since ${parsedDate.year}';
      }

      if (mounted) {
        setState(() {
          _nameController.text = fullName;
          _staffIdController.text = staffId;
          _emailController.text = email;
          _contactController.text = contact;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final userId = _userId ?? _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final fullName = _nameController.text.trim();
    final staffId = _staffIdController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name cannot be empty.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> payload = {
        'full_name': fullName,
        'matric_number': staffId,
        'phone_number': contact,
      };

      try {
        await _supabase.from('profiles').update(payload).eq('id', userId);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        // Fallback if schema uses staff_id / contact_number instead
        if (msg.contains('column') && msg.contains('does not exist')) {
          await _supabase.from('profiles').update({
            'full_name': fullName,
            'staff_id': staffId,
            'contact_number': contact,
          }).eq('id', userId);
        } else {
          rethrow;
        }
      }

      try {
        await _supabase.auth.updateUser(
          UserAttributes(
            email: email.isNotEmpty && email != _supabase.auth.currentUser?.email
                ? email
                : null,
            data: {
              'full_name': fullName,
              'matric_number': staffId,
              'phone_number': contact,
            },
          ),
        );
      } catch (_) {}

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleEditOrSave() async {
    if (_isSaving) return;
    if (_isEditing) {
      await _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Color(0xFF173F32)),
        ),
      );
    }

    final currentName = _nameController.text.trim();
    final initials = _initialsFromName(currentName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2F865),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF173F32),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _isSaving ? null : _loadProfile,
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                          tooltip: 'Reload profile',
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          onPressed: _toggleEditOrSave,
                          child: Text(
                            _isSaving
                                ? 'Saving...'
                                : (_isEditing ? 'Save profile' : 'Edit profile'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'FACILITY ADMINISTRATOR',
                  style: TextStyle(
                    color: Color(0xFFD2F865),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentName.isEmpty ? 'Facility Admin' : currentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _memberSinceLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Form Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '— ADMIN ACCOUNT',
                  style: TextStyle(
                    color: Color(0xFF173F32),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile & permissions',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Full access',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  'Full name',
                  _nameController,
                  _isEditing && !_isSaving,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Staff ID',
                  _staffIdController,
                  _isEditing && !_isSaving,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Official email',
                  _emailController,
                  _isEditing && !_isSaving,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Contact number',
                  _contactController,
                  _isEditing && !_isSaving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isEnabled, {
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: isEnabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: !isEnabled,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}