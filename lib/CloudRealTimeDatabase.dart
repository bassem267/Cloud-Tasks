import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/firebase_options.dart';

Future<void> notificationHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
  print('Message Title: ${message.notification!.title}');
  print('Message Body: ${message.notification!.body}');

  await Firebase.initializeApp();

  try {
    if (message.notification != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref('notification');

      await ref.push().set({
        'title': message.notification!.title,
        'body': message.notification!.body,
        'dateTime': message.sentTime.toString(),
      });

      print(
          'notification stored in Realtime Database: ${message.notification!.body}');
    } else {
      print('Notification data is null');
    }
  } catch (e) {
    print('Error storing notification: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(notificationHandler);

  FirebaseMessaging.onMessage.listen((event) {
    print('Handling a foreground message ${event.messageId}');
    print('Message Title: ${event.notification!.title}');
    print('Message Body: ${event.notification!.body}');
    messageHandlerForeground(event);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Cloud Tasks'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No messages found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var message = snapshot.data![index];
                return ListTile(
                  title: Text(message['title']),
                  subtitle: Text(message['body']),
                  trailing: Text(message['dateTime']),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here if needed
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> fetchMessages() async {
  DatabaseReference reference = FirebaseDatabase.instance.reference().child('Messages');
  DataSnapshot snapshot = (await reference.once()).snapshot;

  List<Map<String, dynamic>> messages = [];

  if (snapshot.value != null) {
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      values.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          messages.add({
            'title': value['title'],
            'body': value['body'],
            'dateTime': value['dateTime'],
          });
        }
      });
    }
  }

  return messages;
}

void messageHandlerForeground(RemoteMessage event) async {
  try {
    await Firebase.initializeApp();

    DatabaseReference ref = FirebaseDatabase.instance.ref('Messages');

    await ref.push().set({
      'title': event.notification!.title,
      'body': event.notification!.body,
      'dateTime': event.sentTime.toString(),
    });

    print('Messages stored in Realtime Database: ${event.notification!.body}');
  } catch (e) {
    print('Error initializing Firebase: $e');
    return;
  }
}




// String? token = await FirebaseMessaging.instance.getToken();
  // print('Token: $token');
