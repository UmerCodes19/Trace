import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiLabelingServiceProvider = Provider<AiLabelingService>(
  (_) => AiLabelingService(),
);

class AiLabelingService {
  final _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.70),
  );

  /// Extracts AI tags from a local image file.
  Future<List<String>> labelImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labels    = await _labeler.processImage(inputImage);

    return labels
        .where((l) => l.confidence >= 0.70)
        .map((l) => l.label.toLowerCase())
        .toList();
  }

  /// Compute simple tag similarity for matching (cosine-like overlap ratio).
  double tagSimilarity(List<String> tagsA, List<String> tagsB) {
    if (tagsA.isEmpty || tagsB.isEmpty) return 0.0;
    final setA = tagsA.toSet();
    final setB = tagsB.toSet();
    final intersection = setA.intersection(setB).length;
    final union        = setA.union(setB).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  void dispose() {
    _labeler.close();
  }
}
