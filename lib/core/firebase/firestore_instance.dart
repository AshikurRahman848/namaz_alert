import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AppFirestore {
  static FirebaseFirestore get instance =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
}
