import 'package:equatable/equatable.dart';

class FoodReview extends Equatable {
  final String userName;
  final double rating;
  final String comment;
  final String timestamp;

  const FoodReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'rating': rating,
    'review': comment,
    'timestamp': timestamp,
  };

  factory FoodReview.fromJson(Map<String, dynamic> json) {
    return FoodReview(
      userName: json['userName'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['review'] as String? ?? json['comment'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [userName, rating, comment, timestamp];
}
