import 'package:carb_cruncher/models/rss/rss_item.dart';
import 'package:xml/xml.dart';

class RssFeed {
  final String title;
  final String link;
  final String description;
  final List<RssItem> items;

  const RssFeed({
    required this.title,
    required this.link,
    required this.description,
    required this.items,
  });

  factory RssFeed.parse(String xml) {
    final channel = XmlDocument.parse(xml).rootElement.getElement("channel");
    if (channel == null) {
      throw ArgumentError(
        "The provided XML does not contain a channel element.",
      );
    }
    return RssFeed(
      title: channel.getElement("title")?.innerText ?? '',
      link: channel.getElement("link")?.innerText ?? '',
      description: channel.getElement("description")?.innerText ?? '',
      items: channel
          .findElements("item")
          .map((item) => RssItem.fromXml(item.toXmlString()))
          .toList(),
    );
  }
}
