import 'dart:convert';

class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };

  String toPayload() => jsonEncode(toJson());

  factory Post.fromPayload(String payload) {
    final Map<String, dynamic> map = jsonDecode(payload) as Map<String, dynamic>;
    return Post.fromJson(map);
  }
}
