import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({Key? key}) : super(key: key);

  Future<List<dynamic>> _fetchNews() async {
    const apiKey = '5b1df65e9b49441493158d432aa78acd'; // Replace with your NewsAPI key
    final response = await http.get(Uri.parse(
        'https://newsapi.org/v2/everything?q=COVID-19&apiKey=$apiKey'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch news');
    }
    return jsonDecode(response.body)['articles'];
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No news available'));
        }
        final articles = snapshot.data!;
        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return ListTile(
              title: Text(article['title'] ?? 'No title'),
              subtitle: Text(article['source']['name'] ?? 'Unknown source'),
              onTap: () => _launchURL(article['url'] ?? ''),
            );
          },
        );
      },
    );
  }
}