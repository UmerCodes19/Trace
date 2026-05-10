import 'package:flutter/material.dart';

class TutorialKeys {
  // Nav Items
  static final GlobalKey navHomeKey = GlobalKey();
  static final GlobalKey navMapKey = GlobalKey();
  static final GlobalKey navCreateKey = GlobalKey();
  static final GlobalKey navReelsKey = GlobalKey();
  static final GlobalKey navInboxKey = GlobalKey();
  static final GlobalKey navProfileKey = GlobalKey();

  // Feed Module
  static final GlobalKey feedFilterKey = GlobalKey();
  static final GlobalKey feedFirstItemKey = GlobalKey();
  static final GlobalKey feedSearchKey = GlobalKey();

  // Map Module
  static final GlobalKey mapToggleKey = GlobalKey();
  static final GlobalKey mapFilterKey = GlobalKey();
  static final GlobalKey mapCanvasKey = GlobalKey();

  // Create Post Module
  static final GlobalKey createPostPhotosKey = GlobalKey();
  static final GlobalKey createPostMapKey = GlobalKey();

  // Additional In-Screen Anchors
  static final GlobalKey reelsContentKey = GlobalKey();
  static final GlobalKey inboxListKey = GlobalKey();
  static final GlobalKey profileSectionKey = GlobalKey();
}
