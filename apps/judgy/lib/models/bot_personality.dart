class BotPersonality {
  const BotPersonality({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
  });

  factory BotPersonality.fromJson(Map<String, dynamic> json) {
    return BotPersonality(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      description: json['description'] as String,
    );
  }

  // TODO(bramp): Add comments explaining each field and how it should be used.
  final String id;
  final String name;
  final String role;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
    };
  }
}
