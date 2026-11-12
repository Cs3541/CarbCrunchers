import 'package:carb_cruncher/models/rss/rss_item.dart';
import 'package:flutter/material.dart';

class ArticleCard extends StatelessWidget {
  final RssItem article;

  ArticleCard({super.key, required this.article});
  final _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: article.mediaUrl == null
                    ? _placeholder()
                    : Image.network(
                        article.mediaUrl!,
                        fit: BoxFit.cover, // fill the box, crop the edges
                        errorBuilder: (_, _, _) => _placeholder(),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.description ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Published on: ${article.pubDate ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          controller: _controller,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in article.categories ?? [])
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Chip(
                                    label: Text(category),
                                    backgroundColor: Colors.blue[100],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}
