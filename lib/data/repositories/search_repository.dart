import '../services/firebase/firebase_providers.dart';

class SearchResultModel {
  final String title;
  final String subtitle;
  final String type;
  final String route;

  const SearchResultModel({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.route,
  });
}

class SearchRepository {
  Future<List<SearchResultModel>> search(String query) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return [];

    final users = await firestoreService.users.limit(50).get();
    final posts = await firestoreService.posts.limit(50).get();
    final matches = await firestoreService.matches.limit(50).get();
    final rooms = await firestoreService.chatRooms.limit(50).get();

    final results = <SearchResultModel>[];

    for (final doc in users.docs) {
      final data = doc.data();
      final username = data['username'] ?? '';

      if (username.toString().toLowerCase().contains(q)) {
        results.add(
          SearchResultModel(
            title: username.toString().startsWith('@')
                ? username.toString()
                : '@$username',
            subtitle: 'Taraftar profili',
            type: 'user',
            route: '/profile/${doc.id}',
          ),
        );
      }
    }

    for (final doc in posts.docs) {
      final data = doc.data();
      final title = data['title'] ?? '';
      final content = data['content'] ?? '';

      if (title.toString().toLowerCase().contains(q) ||
          content.toString().toLowerCase().contains(q)) {
        results.add(
          SearchResultModel(
            title: title.toString(),
            subtitle: 'Taraftar paylaşımı',
            type: 'post',
            route: '/post/${doc.id}',
          ),
        );
      }
    }

    for (final doc in matches.docs) {
      final data = doc.data();
      final home = data['homeTeam'] ?? '';
      final away = data['awayTeam'] ?? '';
      final title = '$home vs $away';

      if (title.toLowerCase().contains(q)) {
        results.add(
          SearchResultModel(
            title: title,
            subtitle: 'Maç',
            type: 'match',
            route: '/lineup/${doc.id}',
          ),
        );
      }
    }

    for (final doc in rooms.docs) {
      final data = doc.data();
      final name = data['name'] ?? '';

      if (name.toString().toLowerCase().contains(q)) {
        results.add(
          SearchResultModel(
            title: name.toString(),
            subtitle: 'Sohbet odası',
            type: 'chat',
            route: '/chat/${doc.id}',
          ),
        );
      }
    }

    return results;
  }
}
