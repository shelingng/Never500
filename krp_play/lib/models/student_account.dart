class StudentAccount {
  final String fullName;
  final String email;
  final String contact;
  final String matric;
  final String category;
  final String password;
  final String faculty;

  const StudentAccount({
    required this.fullName,
    required this.email,
    required this.contact,
    required this.matric,
    required this.category,
    required this.password,
    this.faculty = 'Not provided',
  });
}
