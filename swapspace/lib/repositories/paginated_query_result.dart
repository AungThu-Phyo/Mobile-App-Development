import 'package:cloud_firestore/cloud_firestore.dart';

class PaginatedQueryResult<T> {
  final List<T> items;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PaginatedQueryResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}
