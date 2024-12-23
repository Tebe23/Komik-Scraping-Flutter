import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/manga_models.dart';

class ScrapingService {
  static const baseUrl = 'https://komikcast.bz';

  Future<List<Manga>> scrapePopularManga() async {
    try {
      final popularUrl = '$baseUrl/daftar-komik/?status=&type=&orderby=popular';
      return _scrapeMangaList(popularUrl);
    } catch (e) {
      throw Exception('Error scraping popular manga: $e');
    }
  }

  Future<List<Manga>> scrapeLatestManga() async {
    try {
      final latestUrl = '$baseUrl/daftar-komik/?status=&type=&orderby=update';
      return _scrapeMangaList(latestUrl);
    } catch (e) {
      throw Exception('Error scraping latest manga: $e');
    }
  }

  Future<List<Manga>> _scrapeMangaList(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var mangaElements = document.querySelectorAll('.list-update_item');

      return mangaElements.map((element) {
        var title = element.querySelector('.title')?.text.trim() ?? '';
        var fullLink = element.querySelector('a')?.attributes['href'] ?? '';
        var image = element.querySelector('img')?.attributes['src'] ?? '';
        var chapter = element.querySelector('.chapter')?.text.trim() ?? 'N/A';
        var score = element.querySelector('.numscore')?.text.trim() ?? 'N/A';
        var type = element.querySelector('.type')?.text.trim() ?? 'N/A';
        var status = element.querySelector('.status')?.text.trim() ?? 'N/A';

        var relativeLink =
            fullLink.replaceAll(baseUrl, '').replaceAll('komik/', '');
        while (relativeLink.contains('//')) {
          relativeLink = relativeLink.replaceAll('//', '/');
        }
        relativeLink = relativeLink.replaceAll(RegExp(r'^/+'), '');

        return Manga(
          title: title,
          link: relativeLink,
          image: image,
          latestChapter: chapter,
          score: score,
          type: type,
          status: status,
        );
      }).toList();
    }
    throw Exception('Failed to load manga list');
  }

  Future<MangaDetail> scrapeMangaDetail(String url) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/komik/$url'));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        var thumbnail = document
                .querySelector('.komik_info-content-thumbnail img')
                ?.attributes['src'] ??
            '';
        var title = document
                .querySelector('.komik_info-content-body-title')
                ?.text
                .trim() ??
            '';
        var synopsis = document
                .querySelector('.komik_info-description-sinopsis')
                ?.text
                .trim() ??
            '';

        var genres = document
            .querySelectorAll('.komik_info-content-genre .genre-item')
            .map((e) => e.text.trim())
            .toList();

        var chapters = document
            .querySelectorAll('.komik_info-chapters-item')
            .map((chapter) {
          var linkElem = chapter.querySelector('.chapter-link-item');
          var fullLink = linkElem?.attributes['href'] ?? '';
          var relativeLink = fullLink.replaceAll(baseUrl, '');

          return ChapterInfo(
            title: linkElem?.text.trim() ?? '',
            link: relativeLink,
            time:
                chapter.querySelector('.chapter-link-time')?.text.trim() ?? '',
          );
        }).toList();

        // Fix author extraction
        var authorText = '';
        var metaElements =
            document.querySelectorAll('.komik_info-content-meta span');
        for (var element in metaElements) {
          if (element.text.contains('Author:')) {
            authorText = element.text.replaceAll('Author:', '').trim();
            break;
          }
        }
        var author = authorText.isNotEmpty ? authorText : 'Unknown';

        return MangaDetail(
          thumbnail: thumbnail,
          title: title,
          synopsis: synopsis,
          genres: genres,
          chapters: chapters,
          author: author,
        );
      }
      throw Exception('Failed to load manga detail');
    } catch (e) {
      throw Exception('Error scraping manga detail: $e');
    }
  }

  Future<ChapterData> scrapeChapter(String url) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$url'));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        var title =
            document.querySelector('.chapter_headpost h1')?.text.trim() ?? '';
        var prevChapter = document
            .querySelector('a[rel="prev"]')
            ?.attributes['href']
            ?.replaceAll(baseUrl, '');
        var nextChapter = document
            .querySelector('a[rel="next"]')
            ?.attributes['href']
            ?.replaceAll(baseUrl, '');

        var images = document
            .querySelectorAll('img.alignnone')
            .map((img) =>
                img.attributes['src'] ?? img.attributes['data-src'] ?? '')
            .where((src) => src.isNotEmpty)
            .toList();

        return ChapterData(
          title: title,
          prevChapter: prevChapter,
          nextChapter: nextChapter,
          images: images,
        );
      }
      throw Exception('Failed to load chapter');
    } catch (e) {
      throw Exception('Error scraping chapter: $e');
    }
  }

  Future<List<Manga>> searchManga(String query) async {
    try {
      final searchUrl = '$baseUrl/?s=$query';
      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var mangaElements = document.querySelectorAll('.list-update_item');

        return mangaElements.map((element) {
          var title = element.querySelector('.title')?.text.trim() ?? '';
          var fullLink = element.querySelector('a')?.attributes['href'] ?? '';
          var image = element.querySelector('img')?.attributes['src'] ?? '';
          var chapter = element.querySelector('.chapter')?.text.trim() ?? 'N/A';
          var score = element.querySelector('.numscore')?.text.trim() ?? 'N/A';
          var type = element.querySelector('.type')?.text.trim() ?? 'N/A';
          var status = element.querySelector('.status')?.text.trim() ?? 'N/A';

          var relativeLink =
              fullLink.replaceAll(baseUrl, '').replaceAll('komik/', '');
          while (relativeLink.contains('//')) {
            relativeLink = relativeLink.replaceAll('//', '/');
          }
          relativeLink = relativeLink.replaceAll(RegExp(r'^/+'), '');

          return Manga(
            title: title,
            link: relativeLink,
            image: image,
            latestChapter: chapter,
            score: score,
            type: type,
            status: status,
          );
        }).toList();
      }
      throw Exception('Failed to load search results');
    } catch (e) {
      throw Exception('Error searching manga: $e');
    }
  }
}
