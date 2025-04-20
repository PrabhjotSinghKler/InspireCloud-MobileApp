// lib/services/quote_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_quote_model.dart';

class QuoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'saved_quotes';

  // Save a quote to Firestore
  Future<void> saveQuote(SavedQuoteModel quote) async {
    try {
      await _firestore.collection(_collection).add(quote.toJson());
    } catch (e) {
      throw Exception('Failed to save quote: $e');
    }
  }

  // Get user's saved quotes
  Future<List<SavedQuoteModel>> getSavedQuotes(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('user_id', isEqualTo: userId)
              .orderBy('saved_at', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return SavedQuoteModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch saved quotes: $e');
    }
  }

  // Delete a saved quote
  Future<void> deleteQuote(String quoteId) async {
    try {
      await _firestore.collection(_collection).doc(quoteId).delete();
    } catch (e) {
      throw Exception('Failed to delete quote: $e');
    }
  }
}
