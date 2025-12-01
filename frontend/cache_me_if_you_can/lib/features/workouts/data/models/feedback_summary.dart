class FeedbackSummary {
  final String featureKey;
  final double averageRating;
  final int responsesCount;
  final DateTime? lastResponseAt;
  final List<String> sampleComments;

  const FeedbackSummary({
    required this.featureKey,
    required this.averageRating,
    required this.responsesCount,
    required this.lastResponseAt,
    required this.sampleComments,
  });

  FeedbackSummary copyWith({
    String? featureKey,
    double? averageRating,
    int? responsesCount,
    DateTime? lastResponseAt,
    List<String>? sampleComments,
  }) {
    return FeedbackSummary(
      featureKey: featureKey ?? this.featureKey,
      averageRating: averageRating ?? this.averageRating,
      responsesCount: responsesCount ?? this.responsesCount,
      lastResponseAt: lastResponseAt ?? this.lastResponseAt,
      sampleComments: sampleComments ?? this.sampleComments,
    );
  }
}
