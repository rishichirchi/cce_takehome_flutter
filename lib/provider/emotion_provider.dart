import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmotionNotifier extends StateNotifier<String>{
  EmotionNotifier() : super('Neutral');

  void setEmotion(String emotion){
    log('Emotion: $emotion');
    state = emotion;
  }

}

final emotionProvider = StateNotifierProvider<EmotionNotifier, String>((ref) => EmotionNotifier());