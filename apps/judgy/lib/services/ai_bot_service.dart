import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:judgy/models/bot_personality.dart';
import 'package:judgy/models/game_models.dart';

class AIBotService {
  AIBotService();

  GenerativeModel _getModel(BotPersonality? personality) {
    if (personality == null) {
      // ignore: deprecated_member_use, Migration pending
      return FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-pro',
      );
    }

    // TODO: drop in remote config and prompt templates later
    // See: https://firebase.google.com/docs/ai-logic/server-prompt-templates/syntax-and-examples?api=dev
    // ignore: deprecated_member_use, Migration pending
    return FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-pro',
      systemInstruction: Content.system(
        'You are ${personality.name}, playing an Apples-to-Apples style game.\n'
        'Role: ${personality.role}.\n'
        'Personality: ${personality.description}\n'
        'Stay strictly in character and pick cards based on your unique personality.',
      ),
    );
  }

  /// AI evaluates its hand to pick the best/funniest noun for the adjective.
  Future<CardModel?> selectNounToPlay({
    required Player botPlayer,
    required CardModel currentAdjective,
  }) async {
    if (botPlayer.hand.isEmpty) return null;

    final handDescriptions = botPlayer.hand
        .map((card) => 'ID: ${card.id} - ${card.text}')
        .join('\n');

    final prompt =
        '''
The current Adjective card played by the Judge is: "${currentAdjective.text}"

Here is your hand of Noun cards:
$handDescriptions

Based on the adjective, pick the Noun card from your hand that YOU would pick.
Reply with ONLY the ID of the selected card, nothing else. Do not add any extra text or punctuation.
''';

    try {
      final model = _getModel(botPlayer.botPersonality);
      final response = await model.generateContent([Content.text(prompt)]);
      var selectedId = response.text?.trim() ?? '';
      // Removing any non-word characters just in case it added periods or formatting
      selectedId = selectedId.replaceAll(RegExp(r'[^\w\-]'), '');

      return botPlayer.hand.firstWhere(
        (card) => card.id == selectedId,
        orElse: () => botPlayer.hand.first,
      );
    } on Object {
      // In case of any error with Vertex AI, just pick a random card.
      return botPlayer.hand.first;
    }
  }

  /// AI acts as the judge and selects the winning noun.
  Future<PlayedCard?> judgeWinningCard({
    required Player judgePlayer,
    required CardModel currentAdjective,
    required List<PlayedCard> submissions,
  }) async {
    if (submissions.isEmpty) return null;

    final submissionDescriptions = submissions
        .map((play) => 'ID: ${play.card.id} - ${play.card.text}')
        .join('\n');

    final prompt =
        '''
You are the judge this round.
The round's Adjective is: "${currentAdjective.text}"

Here are the Noun cards played by the other players:
$submissionDescriptions

Which one do YOU think is the best match (based on your personal preferences and character)?
Reply with ONLY the ID of the winning card, nothing else. Do not add any extra text or punctuation.
''';

    try {
      final model = _getModel(judgePlayer.botPersonality);
      final response = await model.generateContent([Content.text(prompt)]);
      var winningId = response.text?.trim() ?? '';
      winningId = winningId.replaceAll(RegExp(r'[^\w\-]'), '');

      return submissions.firstWhere(
        (play) => play.card.id == winningId,
        orElse: () => submissions.first,
      );
    } on Object {
      return submissions.first;
    }
  }
}
