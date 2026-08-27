class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.unitKerja,
  });

  final int id;
  final String? email;
  final String name;
  final String unitKerja;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final email = json['email'];
    final name = json['name'];
    final unitKerja = json['unit_kerja'];

    if (idValue is! num ||
        (email != null && email is! String) ||
        name is! String ||
        unitKerja is! String) {
      throw const FormatException('Invalid user payload.');
    }

    return AppUser(
      id: idValue.toInt(),
      email: email,
      name: name,
      unitKerja: unitKerja,
    );
  }
}
