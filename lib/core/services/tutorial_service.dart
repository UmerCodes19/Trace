import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ActiveTourState { none, home, map, create, reels, inbox, profile }

final activeTourStateProvider = StateProvider<ActiveTourState>((ref) => ActiveTourState.none);

final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});

class TutorialService {
  static const String _keyIntro = 'tutorial_intro_completed';
  static const String _keyFeed = 'tutorial_feed_completed';
  static const String _keyNav = 'tutorial_nav_completed';

  Future<bool> isFeatureTourCompleted(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tut_$featureKey') ?? false;
  }

  Future<void> markFeatureTourCompleted(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tut_$featureKey', true);
  }

  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('tut_'));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
