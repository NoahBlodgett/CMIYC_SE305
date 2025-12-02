import 'package:cloud_firestore/cloud_firestore.dart';

import 'data/services/daily_summary_service.dart';

final DailySummaryService dailySummaryService =
    DailySummaryService(db: FirebaseFirestore.instance);
