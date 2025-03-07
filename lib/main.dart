import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'services/api_service.dart';
import 'models/post.dart';
import 'package:translator/translator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REST API Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.grey),
      home: PostListScreen(),
    );
  }
}

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late Future<List<Post>> futurePosts;
  Map<int, bool> likedPosts = {};

  @override
  void initState() {
    super.initState();
    futurePosts = ApiService().fetchPosts();
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Copy!")),
    );
  }

  void sharePost(String title, String body) {
    Share.share('$title\n\n$body');
  }

  void translateText(String title,String body) async {
    String text = title + "\n" + body;
    final translator = GoogleTranslator();
    var translation = await translator.translate(text, from: 'auto', to: 'en');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Translated: ${translation.text}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        elevation: 0,
        leading: Icon(
          Icons.article_outlined,
          color: Colors.white,
          size: 30,
        ),
        title: Text(
          'Posts',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Post>>(
        future: futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            List<Post> posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              padding: EdgeInsets.all(10),
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: capitalize(
                                    posts[index].title)[0],
                                style: GoogleFonts.merriweather(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              TextSpan(
                                text: capitalize(posts[index].title)
                                    .substring(1),
                                style: GoogleFonts.merriweather(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          posts[index].body,
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Divider(color: Colors.grey[300]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(
                                likedPosts[index] == true ? Icons.thumb_up : Icons.thumb_up_off_alt,
                                color: likedPosts[index] == true ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  likedPosts[index] = !(likedPosts[index] ?? false);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, color: Colors.grey),
                              onPressed: () => copyToClipboard(posts[index].body),
                            ),
                            IconButton(
                              icon: Icon(Icons.translate, color: Colors.grey),
                              onPressed: () => translateText(posts[index].title,posts[index].body),
                            ),
                            IconButton(
                              icon: Icon(Icons.share, color: Colors.grey),
                              onPressed: () => sharePost(posts[index].title, posts[index].body),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                'No data found',
                style: TextStyle(color: Colors.indigo, fontSize: 18),
              ),
            );
          }
        },
      ),
    );
  }
}