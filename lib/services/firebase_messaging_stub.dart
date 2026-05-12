// Firebase Messaging stub for web platform.
// Web'de Firebase Messaging çalışmaz, bu stub dosyası import hatalarını önler.

class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging._();
  FirebaseMessaging._();

  Future<String?> getToken() async => null;
  Future<void> deleteToken() async {}
  Future<void> requestPermission() async {}

  static Stream<RemoteMessage> get onMessage => const Stream.empty();
  static Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();
  Future<RemoteMessage?> getInitialMessage() async => null;
  static void onBackgroundMessage(Function(RemoteMessage) handler) {}
}

class RemoteMessage {
  final Map<String, dynamic>? data;
  final Notification? notification;
  final String? messageId;

  const RemoteMessage({this.data, this.notification, this.messageId});

  String? get getMessageId => messageId;
}

class Notification {
  final String? title;
  final String? body;

  const Notification({this.title, this.body});
}
