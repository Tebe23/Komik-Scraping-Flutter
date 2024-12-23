import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import '../models/manga.dart';
import '../models/manga_detail.dart';

class MangaService {
  static const String baseUrl = 'https://komikcast.bz';

  Future<List<Manga>> scrapeManga(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load manga list');
      }

      final document = parser.parse(response.body);
      final mangaList = document.querySelectorAll('.list-update_item');

      return mangaList.map((element) {
        final titleElement = element.querySelector('.title');
        final linkElement = element.querySelector('a');
        final imageElement = element.querySelector('img');
        final chapterElement = element.querySelector('.chapter');
        final scoreElement = element.querySelector('.numscore');
        final timeElement = element.querySelector('.timeago');
        final typeElement = element.querySelector('.type');
        final statusElement = element.querySelector('.status');

        String getRelativeLink(String? fullLink) {
          if (fullLink == null) return '';
          return fullLink
              .replaceAll(baseUrl, '')
              .replaceAll('komik/', '')
              .replaceAll('//', '/')
              .replaceAll(RegExp(r'/$'), '');
        }

        return Manga(
          title: titleElement?.text.trim() ?? '',
          link: getRelativeLink(linkElement?.attributes['href']),
          imageUrl: imageElement?.attributes['src'] ?? '',
          chapter: chapterElement?.text.trim() ?? 'N/A',
          score: scoreElement?.text.trim() ?? 'N/A',
          updateTime: timeElement?.attributes['datetime'] ?? '',
          type: typeElement?.text.trim() ?? 'N/A',
          status: statusElement?.text.trim() ?? 'N/A',
        );
      }).toList();
    } catch (e) {
      print('Error scraping manga: $e');
      return [];
    }
  }

  Future<MangaDetail> getMangaDetail(String mangaLink) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$mangaLink'));
      if (response.statusCode != 200) {
        throw Exception('Failed to load manga detail');
      }

      final document = parser.parse(response.body);
      // Extract manga details from the document
      const thumbnail = ''; // Extract from document
      const title = ''; // Extract from document
      const nativeTitle = ''; // Extract from document
      const synopsis = ''; // Extract from document
      final genres = []; // Extract from document
      const release = ''; // Extract from document
      const author = ''; // Extract from document
      const status = ''; // Extract from document
      const type = ''; // Extract from document
      const totalChapter = 0; // Extract from document
      const updatedOn = ''; // Extract from document
      const rating = 0.0; // Extract from document
      final chapters = []; // Extract from document

      return MangaDetail(
        thumbnail: thumbnail,
        title: title,
        nativeTitle: nativeTitle,
        synopsis: synopsis,
        genres: genres,
        release: release,
        author: author,
        status: status,
        type: type,
        totalChapter: totalChapter,
        updatedOn: updatedOn,
        rating: rating,
        chapters: chapters,
      );
    } catch (e) {
      print('Error fetching manga detail: $e');
      return MangaDetail(); // Return an empty or default MangaDetail
    }
  }

  Future<List<Manga>> getLatestManga() async {
    return scrapeManga('$baseUrl/daftar-komik/?orderby=update');
  }

  Future<List<Manga>> getPopularManga() async {
    return scrapeManga('$baseUrl/daftar-komik/?status=&type=&orderby=popular');
  }

  Future<List<Manga>> searchManga(String query) async {
    return scrapeManga('$baseUrl/?s=$query');
  }

  Future<List<String>> getChapterImages(String chapterLink) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$chapterLink'));
      if (response.statusCode != 200) {
        throw Exception('Failed to load chapter images');
      }

      final document = parser.parse(response.body);
      // Extract chapter images from the document
      // Implement the logic to parse the chapter images here

      return []; // Return a list of image URLs
    } catch (e) {
      print('Error fetching chapter images: $e');
      return []; // Return an empty list on error
    }
  }
}
