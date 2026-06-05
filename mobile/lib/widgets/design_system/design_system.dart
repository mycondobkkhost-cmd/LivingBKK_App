import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

export 'app_button.dart';
export 'app_card.dart';
export 'app_search_bar.dart';
export 'app_bottom_nav.dart';
export 'app_tag.dart';
export 'app_badge.dart';
export 'app_property_card.dart';
export 'app_avatar.dart';
export 'app_map_marker.dart';

/// Design system barrel — Airbnb × LivingInsider v2

extension DesignSystemContext on BuildContext {
  AppPalette get colors => palette;
}
