import 'package:flutter/material.dart' as flutter;
import '../markdown.dart';

(List<flutter.InlineSpan>, List<Node>) markdownToFormattedMarkdown(
  String markdown, {
    Iterable<BlockSyntax> blockSyntaxes = const [],
    Iterable<InlineSyntax> inlineSyntaxes = const [],
    ExtensionSet? extensionSet,
    Resolver? linkResolver,
    LinkBuilder? linkBuilder,
    Resolver? imageLinkResolver,
    LinkBuilder? imageLinkBuilder,
    bool inlineOnly = false,
    bool encodeHtml = false,
    bool enableTagfilter = false,
    bool withDefaultBlockSyntaxes = true,
    bool withDefaultInlineSyntaxes = true,
}) {
  final document = Document(
    blockSyntaxes: blockSyntaxes,
    inlineSyntaxes: inlineSyntaxes,
    extensionSet: extensionSet,
    linkResolver: linkResolver,
    imageLinkResolver: imageLinkResolver,
    linkBuilder: linkBuilder,
    imageLinkBuilder: imageLinkBuilder,
    encodeHtml: encodeHtml,
    withDefaultBlockSyntaxes: withDefaultBlockSyntaxes,
    withDefaultInlineSyntaxes: withDefaultInlineSyntaxes,
  );

  final nodes = document.parse(markdown);

  return (renderToFormattedMarkdown(nodes), nodes);
}

List<flutter.InlineSpan> renderToFormattedMarkdown(List<Node> nodes) {
  return MarkdownRenderer().render(nodes);
}

class MarkdownRenderer implements NodeVisitor {
  final List<flutter.InlineSpan> spans = [];
  final List<flutter.TextStyle> _styleStack = [];

  MarkdownRenderer();

  flutter.TextStyle get _currentStyle => _styleStack.isEmpty
  ? const flutter.TextStyle()
  : _styleStack.reduce((a, b) => a.merge(b));

  List<flutter.InlineSpan> render(List<Node> nodes) {
    for (final node in nodes) {
      node.accept(this);
    }
    return spans;
  }

  @override
  void visitText(Text text) {
    final raw = text.textContent;
    spans.add(flutter.TextSpan(text: raw, style: _currentStyle));
  }

  @override
  bool visitElementBefore(Element element) {
    _styleStack.add(_styleForTag(element.tag));
    return true;
  }

  @override
  void visitElementAfter(Element element) {
    _styleStack.removeLast();
    if (element.tag == 'p' || element.tag.startsWith('h')) {
      // No need to add \n for blockquote since it is already composed of tags it applies to
      spans.add(const flutter.TextSpan(text: '\n'));
      // Replace the last space before \n with a non-breaking space to avoid
      // cursor inconsistencies with certain styles (bold, italic, fontSize, ...)
      final last = spans[spans.length - 2];
      if (last is flutter.TextSpan && last.text != null && last.text!.endsWith(' ')) {
        spans[spans.length - 2] = flutter.TextSpan(
          text: '${last.text!.substring(0, last.text!.length - 1)}\u00A0',
          style: last.style,
        );
      }
    }
  }

  flutter.TextStyle _styleForTag(String tag) {
    switch (tag) {
      case 'h1':
      return const flutter.TextStyle(
        fontSize: 28,
        fontWeight: flutter.FontWeight.bold,
      );
      case 'h2':
      return const flutter.TextStyle(
        fontSize: 26,
        fontWeight: flutter.FontWeight.bold,
      );
      case 'h3':
      return const flutter.TextStyle(
        fontSize: 24,
        fontWeight: flutter.FontWeight.bold,
      );
      case 'h4':
      return const flutter.TextStyle(
        fontSize: 22,
        fontWeight: flutter.FontWeight.bold,
      );
      case 'h5':
      return const flutter.TextStyle(
        fontSize: 20,
        fontWeight: flutter.FontWeight.bold,
      );
      case 'h6':
      return const flutter.TextStyle(
        fontSize: 18,
        fontWeight: flutter.FontWeight.bold,
      );
      case 'blockquote':
      return const flutter.TextStyle(
        color: flutter.Colors.grey,
        fontStyle: flutter.FontStyle.italic
      );
      case 'a':
      return const flutter.TextStyle(color: flutter.Colors.orange);
      case 'a-href':
      return const flutter.TextStyle(fontSize: 6, color: flutter.Colors.grey);
      case 'strong':
      return const flutter.TextStyle(fontWeight: flutter.FontWeight.bold);
      case 'em':
      return const flutter.TextStyle(fontStyle: flutter.FontStyle.italic);
      case 'code':
      return const flutter.TextStyle(fontStyle: flutter.FontStyle.italic, color: flutter.Colors.grey);
      default:
      return const flutter.TextStyle();
    }
  }
}
