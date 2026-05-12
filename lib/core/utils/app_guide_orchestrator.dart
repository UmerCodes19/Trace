import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../services/tutorial_service.dart';
import '../../presentation/widgets/common/guide_tooltip.dart';

class AppGuideOrchestrator {
  static void showTutorial({
    required BuildContext context,
    required String featureKey,
    required List<TargetFocus> targets,
    required TutorialService tutorialService,
    VoidCallback? onFinish,
  }) {
    // Instantiate TutorialCoachMark
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.7),
      textSkip: "SKIP",
      paddingFocus: 4,
      opacityShadow: 0.7,
      pulseEnable: true,
      onFinish: () {
        tutorialService.markFeatureTourCompleted(featureKey);
        if (onFinish != null) onFinish();
      },
      onSkip: () {
        tutorialService.markFeatureTourCompleted(featureKey);
        if (onFinish != null) onFinish();
        return true;
      },
    ).show(context: context);
  }

  static TargetFocus buildTarget({
    required GlobalKey key,
    required String title,
    required String description,
    required String stepLabel,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 12,
  }) {
    return TargetFocus(
      identify: key.toString(),
      keyTarget: key,
      alignSkip: Alignment.bottomRight,
      shape: shape,
      radius: radius,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return GuideTooltip(
              title: title,
              description: description,
              currentStepLabel: stepLabel,
              onNext: () => controller.next(),
              onSkip: () => controller.skip(),
            );
          },
        ),
      ],
    );
  }
}
