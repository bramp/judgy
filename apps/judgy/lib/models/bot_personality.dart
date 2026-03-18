/// Data model for botpersonality entities.
class BotPersonality {
  /// Creates a [BotPersonality].
  const BotPersonality({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
  });

  /// Creates a [BotPersonality] from a JSON map.
  factory BotPersonality.fromJson(Map<String, dynamic> json) {
    return BotPersonality(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      description: json['description'] as String,
    );
  }

  // TODO(bramp): Add comments explaining each field and how it should be used.
  /// Unique identifier.
  final String id;

  /// The name value.
  final String name;

  /// The role value.
  final String role;

  /// The description value.
  final String description;

  /// Converts this [BotPersonality] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
    };
  }
}
