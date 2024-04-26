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
  final Reference userStorageReference =
      FirebaseStorage.instance.ref().child('images/'); // Constant folder path

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
      // Create a unique filename for the image
      String fileName = '${DateTime.now()}.png';

      // Upload the image to the constant folder path
      UploadTask uploadTask =
          userStorageReference.child(fileName).putFile(_imageFile!);
      await uploadTask.whenComplete(() {
        print('Image uploaded');
        // Clear the image file after successful upload
        setState(() {
          _imageFile = null;
        });
      });
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


  Future<List<String>> _getUserImages() async {
    List<String> imageURLs = [];

    try {
      // List all items in the constant folder path
      ListResult result = await userStorageReference.listAll();

      // Iterate through each item and get the download URL
      for (Reference ref in result.items) {
        String downloadURL = await ref.getDownloadURL();
        imageURLs.add(downloadURL);
      }
    } catch (e) {
      print('Error fetching user images: $e');
    }

    return imageURLs;
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
      body: FutureBuilder<List<String>>(
        future: _getUserImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While data is loading, display a loading indicator
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If there's an error, display an error message
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // If data is successfully fetched, display the GalleryView
            List<String> userImages = snapshot.data!;
            return GalleryView(images: userImages);
          }
        },
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
