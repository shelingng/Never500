import 'package:flutter/material.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final TextEditingController _nameController = TextEditingController(text: 'Nur Aisyah Ahmad');
  final TextEditingController _staffIdController = TextEditingController(text: 'KRP-ADM-014');
  final TextEditingController _emailController = TextEditingController(text: 'admin.aisyah@utm.my');
  final TextEditingController _contactController = TextEditingController(text: '012-345 6789');

  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F), // Dark blue from wireframe
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
                      decoration: BoxDecoration(color: const Color(0xFFD2F865), borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Text('NA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF173F32)))),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                        if (!_isEditing) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated')));
                        }
                      },
                      child: Text(_isEditing ? 'Save profile' : 'Edit profile'),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                const Text('FACILITY ADMINISTRATOR', style: TextStyle(color: Color(0xFFD2F865), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(_nameController.text, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('KRP Sports Unit · Administrator since 2024', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Form Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('— ADMIN ACCOUNT', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profile & permissions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('Full access', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildTextField('Full name', _nameController, _isEditing),
                const SizedBox(height: 16),
                _buildTextField('Staff ID', _staffIdController, _isEditing),
                const SizedBox(height: 16),
                _buildTextField('Official email', _emailController, _isEditing),
                const SizedBox(height: 16),
                _buildTextField('Contact number', _contactController, _isEditing),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isEnabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: isEnabled,
          decoration: InputDecoration(
            filled: !isEnabled,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}