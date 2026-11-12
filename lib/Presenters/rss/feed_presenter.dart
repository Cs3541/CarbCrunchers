import 'package:carb_cruncher/models/rss/feed_repository.dart';
import 'package:carb_cruncher/models/rss/rss_item.dart';

import '../../models/rss/rss_feed.dart';

abstract class FeedView {
  void showLoading();
  void showItems(List<RssItem> items);
  void showError(String message);
}

class FeedPresenter {
  FeedPresenter({required this.view, required this.repository});

  final FeedView view;
  final FeedRepository repository;

  bool _disposed = false;

  Future<void> loadFeed() async {
    if (_disposed) return;
    view.showLoading();
    try {
      final feed = await repository.fetchFeed();
      if (_disposed) return;
      view.showItems(feed.items);
    } catch (e) {
      if (_disposed) return;
      view.showError(e.toString());
    }
  }

  void dispose() {
    _disposed = true;
    repository.dispose();
  }
}
