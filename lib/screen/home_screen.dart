import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:rest_api_demo/models/post.dart';
import 'package:rest_api_demo/services/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> futurePosts;
  Map<int, bool> likedPosts = {};

  @override
  void initState() {
    super.initState();
    futurePosts = ApiService().fetchPosts();
    requestStoragePermission();
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      content: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 48,
                ),
                Text(
                  "Copy!",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
              left: 30,
              child: ClipRRect(
                child: Stack(
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.blue.shade200,
                      size: 17,
                    )
                  ],
                ),
              )),
          Positioned(
              top: -10,
              left: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                  ),
                  const Positioned(
                      top: 3,
                      child: Icon(
                        Icons.done_outlined,
                        color: Colors.white,
                        size: 20,
                      )
                  ),
                ],
              )),
        ],
      ),
    ));
  }

  void sharePost(String title, String body) {
    Share.share('$title\n\n$body');
  }

  void translateText(String title, String body) async {
    String text = title + "\n" + body;
    final translator = GoogleTranslator();
    var translationtitle =
        await translator.translate(title, from: 'auto', to: 'en');
    var translationbody =
        await translator.translate(body, from: 'auto', to: 'en');
    var translation = await translator.translate(text, from: 'auto', to: 'en');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Spacer(),
                  Row(
                    children: [
                      Icon(Icons.translate, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Translated Text",
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: Colors.grey[300]),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: capitalize(translationtitle.text)[0],
                      style: GoogleFonts.merriweather(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    TextSpan(
                      text: capitalize(translationtitle.text).substring(1),
                      style: GoogleFonts.merriweather(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                translationbody.text,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey[300]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up, color: Colors.grey),
                    onPressed: () => speakText(translation.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.grey),
                    onPressed: () => searchOnGoogle(translation.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => showEditDialog(
                        context, translationtitle.text, translationbody.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.save, color: Colors.grey),
                    onPressed: () => saveTextAsPDF(
                        context, translationtitle.text, translationbody.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.grey),
                    onPressed: () => copyToClipboard(translation.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.grey),
                    onPressed: () =>
                        sharePost(translationtitle.text, translationbody.text),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  FlutterTts flutterTts = FlutterTts();

  Future<void> speakText(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  void showEditDialog(BuildContext context, String title, String body) {
    TextEditingController titleController = TextEditingController(text: title);
    TextEditingController bodyController = TextEditingController(text: body);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Text"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(labelText: "Body"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                print("New Title: ${titleController.text}");
                print("New Body: ${bodyController.text}");
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveTextAsPDF(
      BuildContext context, String title, String body) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(body, style: pw.TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            //color: Color(0xff2A303E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10),
                Icon(
                  Icons.sim_card_download_outlined,
                  color: Colors.blueAccent,
                  size: 100,
                ),
                SizedBox(height: 10),
                Text(
                  "Save PDF",
                  style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                SizedBox(height: 5),
                Text(
                  "Do you want to save 'translated_text.pdf' to your device?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w300),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          side:
                              BorderSide(color: Colors.blueAccent, width: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          Permission.manageExternalStorage.request();

                          Directory? downloadsDir;
                          if (Platform.isAndroid) {
                            downloadsDir =
                                Directory("/storage/emulated/0/Download");
                          } else if (Platform.isIOS) {
                            downloadsDir =
                                await getApplicationDocumentsDirectory();
                          }

                          if (downloadsDir != null) {
                            final file = File(
                                "${downloadsDir.path}/translated_text.pdf");
                            await file.writeAsBytes(await pdf.save());

                            Navigator.pop(context);
                            await Future.delayed(Duration(milliseconds: 300));

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.transparent,
                              behavior: SnackBarBehavior.floating,
                              elevation: 0,
                              content: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(15)),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 48,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                "PDF saved successfully!",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                'The document has been downloaded successfully.\n Please open the document in the "Download" folder.',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                      bottom: 25,
                                      left: 20,
                                      child: ClipRRect(
                                        child: Stack(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              color: Colors.blue.shade200,
                                              size: 17,
                                            )
                                          ],
                                        ),
                                      )),
                                  Positioned(
                                      top: -20,
                                      left: 5,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 30,
                                            width: 30,
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(15)),
                                            ),
                                          ),
                                          const Positioned(
                                              top: 5,
                                              child: Icon(
                                                Icons
                                                    .file_download_done_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ))
                                        ],
                                      )),
                                ],
                              ),
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Failed to get storage directory")),
                            );
                          }
                        },
                        child: Text('Save'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey, width: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> searchOnGoogle(String query) async {
    final url = Uri.parse(
        "https://www.google.com/search?q=${Uri.encodeComponent(query)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $url";
    }
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
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
                                text: capitalize(posts[index].title)[0],
                                style: GoogleFonts.merriweather(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              TextSpan(
                                text:
                                    capitalize(posts[index].title).substring(1),
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
                                likedPosts[index] == true
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_off_alt,
                                color: likedPosts[index] == true
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  likedPosts[index] =
                                      !(likedPosts[index] ?? false);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.translate, color: Colors.grey),
                              onPressed: () => translateText(
                                  posts[index].title, posts[index].body),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, color: Colors.grey),
                              onPressed: () =>
                                  copyToClipboard(posts[index].body),
                            ),
                            IconButton(
                              icon: Icon(Icons.share, color: Colors.grey),
                              onPressed: () => sharePost(
                                  posts[index].title, posts[index].body),
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
