import 'package:carb_cruncher/models/rss/feed_repository.dart';
import 'package:carb_cruncher/models/rss/rss_item.dart';
import 'package:carb_cruncher/presenters/rss/feed_presenter.dart';
import 'package:carb_cruncher/views/article_page.dart';
import 'package:carb_cruncher/widgets/rss/article_card.dart';
import 'package:flutter/material.dart';

class ArticlesPage extends StatefulWidget {
  ArticlesPage({super.key});

  final FeedRepository feedRepository = FeedRepository();

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> implements FeedView {
  late FeedPresenter _presenter;
  List<RssItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _presenter = FeedPresenter(view: this, repository: widget.feedRepository);
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _presenter.loadFeed();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void showLoading() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  @override
  void showItems(List<RssItem> items) {
    setState(() {
      _items = items;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage ?? 'An error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadFeed, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _presenter.loadFeed,
      child: ListView.separated(
        itemBuilder: (context, i) {
          final item = _items[i];
          debugPrint('Building item ${item.mediaUrl} at index $i');
          return ArticleCard(article: item);
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _items.length,
      ),
    );
  }
}
