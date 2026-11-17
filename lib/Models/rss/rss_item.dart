import 'package:xml/xml.dart';

class RssItem {
  final String title;
  final String link;
  final String commentsUrl;
  final String author;
  final String pubDate;
  final List<String> categories;
  final String guid;
  final String description;
  final String content;
  final String commentRssUrl;
  final int commentCount;
  final String mediaUrl; // default value

  const RssItem({
    required this.title,
    required this.link,
    required this.commentsUrl,
    required this.author,
    required this.pubDate,
    required this.categories,
    required this.guid,
    required this.description,
    required this.content,
    required this.mediaUrl,
    required this.commentRssUrl,
    required this.commentCount,
  });

  factory RssItem.fromXml(String xml) {
    String text(String name) =>
        XmlDocument.parse(xml).rootElement.getElement(name)?.innerText.trim() ??
        '';

    String? mediaUrl = XmlDocument.parse(xml).rootElement
        .getElement("media:content")
        ?.getAttribute("url");

    String? author = XmlDocument.parse(xml).rootElement
        .getElement("dc:creator")
        ?.innerText;

    return RssItem(
      title: text("title"),
      link: text("link"),
      mediaUrl: mediaUrl ?? '', // Use the media URL if available, otherwise default to an empty string
      commentsUrl: text("comments"),
      author: author ?? 'NutritionFacts.org author', // Use the author if available, otherwise default to an empty string
      pubDate: text("pubDate"),
      categories: XmlDocument.parse(xml).rootElement
          .findElements("category")
          .map((e) => e.innerText)
          .toList(),
      guid: text("guid"),
      description: text("description"),
      content: text("content:encoded"),
      commentRssUrl: text("wfw:commentRss"),
      commentCount: int.tryParse(text("slash:comments")) ?? 0,
    );
  }
}
