import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Uploader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageUploader(),
    );
  }
}

class ImageUploader extends StatefulWidget {
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  final TextEditingController _idController = TextEditingController();
  final Reference storageReference =
      FirebaseStorage.instance.ref(); // Root storage reference
  final ValueNotifier<String> _idNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _idNotifier.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  Future<void> _uploadImage() async {
    setState(() {
      _uploading = true;
    });

    try {
      if (_imageFile != null) {
        String id = _idController.text.trim();
        if (id.isNotEmpty) {
          // Create a unique filename for the image
          String fileName = '${DateTime.now()}.png';

          // Construct the path based on the entered ID
          String path = 'images/$id/$fileName';

          // Upload the image to the specified folder
          UploadTask uploadTask =
              storageReference.child(path).putFile(_imageFile!);
          await uploadTask.whenComplete(() {
            print('Image uploaded');
            setState(() {
              _imageFile = null;
            });
          });
        } else {
          if (kDebugMode) {
            print('ID cannot be empty');
          }
        }
      } else {
        if (kDebugMode) {
          print('No image selected');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<List<String>> _getUserImages(String id) async {
    if (id.isNotEmpty) {
      List<String> imageURLs = [];
      try {
        // Construct the path based on the entered ID
        String path = 'images/$id/';

        // List all items in the specified folder
        ListResult result = await storageReference.child(path).listAll();

        // Iterate through each item and get the download URL
        for (Reference ref in result.items) {
          String downloadURL = await ref.getDownloadURL();
          imageURLs.add(downloadURL);
        }
      } catch (e) {
        print('Error fetching user images: $e');
      }
      return imageURLs;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Image Uploader',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0), // Adjust the padding as needed
            child: TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Enter ID',
              ),
              onChanged: (value) {
                _idNotifier.value = value;
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _idNotifier,
              builder: (context, id, _) {
                return FutureBuilder<List<String>>(
                  future: _getUserImages(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      List<String> userImages = snapshot.data ?? [];
                      return GalleryView(images: userImages);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getImage,
            tooltip: 'Pick Image',
            child: const Icon(Icons.image),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _uploading ? null : _uploadImage,
            tooltip: 'Upload Image',
            child: _uploading
                ? const CircularProgressIndicator()
                : const Icon(Icons.cloud_upload),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// GalleryView widget to display user's images
class GalleryView extends StatelessWidget {
  final List<String> images;

  const GalleryView({required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Number of images in each row
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              // Handle image tap event
            },
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
