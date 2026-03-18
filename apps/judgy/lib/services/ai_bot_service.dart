// Firebase AI template APIs are currently experimental.
// ignore_for_file: experimental_member_use, public_member_api_docs, lines_longer_than_80_chars

import 'package:firebase_ai/firebase_ai.dart';
import 'package:judgy/models/game_models.dart';

class AIBotService {
  AIBotService({TemplateGenerativeModel? templateModel})
    : _templateModel = templateModel;

  final TemplateGenerativeModel? _templateModel;

  // TODO(bramp): Why lazily create this. Let's just create and store on init.
  TemplateGenerativeModel _getTemplateModel() {
    final templateModel = _templateModel;
    if (templateModel != null) return templateModel;
    return FirebaseAI.vertexAI().templateGenerativeModel();
  }

  /// AI evaluates its hand to pick the best/funniest noun for the adjective.
  Future<CardModel?> selectNounToPlay({
    required Player botPlayer,
    required CardModel currentAdjective,
  }) async {
    if (botPlayer.hand.isEmpty) return null;

    // TODO(bramp): We need to add card description
    final handDescriptions = botPlayer.hand
        .map((card) => 'ID: ${card.id} - ${card.text}')
        .join('\n');

    try {
      final model = _getTemplateModel();

      // Assumes a server prompt template named 'bot-select-noun' exists.
      // TODO(bramp): We should require "botPlayer.botPersonality", and not check for null here.
      final response = await model.generateContent(
        // TODO(bramp): The `bot-select-noun` templateId should be configurable with Remote Config.
        'bot-select-noun',
        inputs: {
          'botName': botPlayer.botPersonality?.name ?? 'Standard Bot',
          'botRole': botPlayer.botPersonality?.role ?? 'Participant',
          'botDescription':
              botPlayer.botPersonality?.description ?? 'Pick cards randomly.',
          'adjective': currentAdjective.text,
          'handDescriptions': handDescriptions,
        },
      );

      // TODO(bramp): Change the prompt to return the card, and some funny commentary.
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

    try {
      final model = _getTemplateModel();

      // Assumes a server prompt template named 'bot-judge' exists.
      final response = await model.generateContent(
        // TODO(bramp): The `bot-judge` templateId should be configurable with Remote Config.
        'bot-judge',
        inputs: {
          // TODO(bramp): The `bot-select-noun` templateId should be configurable with Remote Config.
          'judgeName': judgePlayer.botPersonality?.name ?? 'Standard Judge',
          'judgeRole': judgePlayer.botPersonality?.role ?? 'Judge',
          'judgeDescription':
              judgePlayer.botPersonality?.description ??
              'Pick the most fitting card objectively.',
          'adjective': currentAdjective.text,
          'submissionDescriptions': submissionDescriptions,
        },
      );

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
