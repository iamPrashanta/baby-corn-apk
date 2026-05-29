// features/records/data/repositories/firestore_record_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/record_model.dart';

class FirestoreRecordRepository {
  final FirebaseFirestore _firestore;
  
  FirestoreRecordRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _babyId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Fallback to a local UUID if strictly offline, though real app should enforce auth before sync
    return uid ?? 'unauthenticated_local_user';
  }

  CollectionReference get _recordsCollection => 
      _firestore.collection('babies').doc(_babyId).collection('records');

  Future<void> saveRecord(RecordModel record) async {
    // Payload sanitization: Ensure no unexpected massive data is uploaded
    final sanitizedMetadata = <String, dynamic>{};
    record.metadata.forEach((key, value) {
      if (key.length <= 50) {
        if (value is String && value.length > 500) {
          sanitizedMetadata[key] = value.substring(0, 500); // Truncate huge strings
        } else {
          sanitizedMetadata[key] = value;
        }
      }
    });

    final sanitizedRecord = record.copyWith(metadata: sanitizedMetadata);
    
    // Ensure the ID is valid length
    if (sanitizedRecord.id.length > 100) return;

    await _recordsCollection.doc(sanitizedRecord.id).set(sanitizedRecord.toFirestore());
  }
  
  Future<List<RecordModel>> fetchRecords() async {
    // Added limit to prevent massive reads
    final snapshot = await _recordsCollection.orderBy('timestamp', descending: true).limit(200).get();
    return snapshot.docs.map((doc) => 
      RecordModel.fromFirestore(doc.data() as Map<String, dynamic>)
    ).toList();
  }
  
  Future<void> deleteRecord(String id) async {
    await _recordsCollection.doc(id).delete();
  }
}
