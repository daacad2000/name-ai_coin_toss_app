enum AIChatacterRole { coinTosser, reportWriter }

class AICharacter {
  final String characterId;
  final String name;
  final String avatarUrl;
  final String description;
  final AIChatacterRole role;
  final String? voiceTone;

  AICharacter({
    required this.characterId,
    required this.name,
    required this.avatarUrl,
    required this.description,
    required this.role,
    this.voiceTone,
  });
}