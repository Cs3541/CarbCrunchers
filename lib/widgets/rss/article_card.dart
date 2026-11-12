import 'package:carb_cruncher/models/rss/rss_item.dart';
import 'package:flutter/material.dart';

class ArticleCard extends StatelessWidget {
  final RssItem article;

  const ArticleCard({super.key, required this.article});

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
