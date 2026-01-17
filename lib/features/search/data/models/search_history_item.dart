/// Search History Item Model
/// Represents a user's search history entry from Supabase
class SearchHistoryItem {
  final String id;
  final String userId;
  final String query;
  final DateTime createdAt;

  const SearchHistoryItem({
    required this.id,
    required this.userId,
    required this.query,
    required this.createdAt,
  });

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      query: map['query'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'query': query,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
