import 'dart:convert';

import 'package:http/http.dart' as http;

import 'rss_feed.dart';

class FeedRepository {
  FeedRepository({http.Client? client}) : _client = client ?? http.Client();

  static final Url = Uri.parse("https://nutritionfacts.org/feed");

  final http.Client _client;

  Future<RssFeed> fetchFeed() async {
    final response = await _client.get(Url);
    if (response.statusCode == 200) {
      return RssFeed.parse(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load feed');
    }
  }

  void dispose() {
    _client.close();
  }
}
