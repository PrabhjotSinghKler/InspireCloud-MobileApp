// lib/controllers/quote_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_quote_model.dart';
import '../services/openai_service.dart';
import '../services/quote_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class QuoteController with ChangeNotifier {
  final OpenAIService _openAIService;
  final QuoteService _quoteService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _generatedQuotesCount = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SavedQuoteModel> _savedQuotes = [];
  bool _isLoading = false;

  QuoteController({
    required OpenAIService openAIService,
    required QuoteService quoteService,
  }) : _openAIService = openAIService,
       _quoteService = quoteService {
    _initializeCounters();
  }

  // Getters
  List<SavedQuoteModel> get savedQuotes => _savedQuotes;
  bool get isLoading => _isLoading;
  String get userId => _auth.currentUser?.uid ?? '';
  int get generatedQuotesCount => _generatedQuotesCount;

  Future<void> _initializeCounters() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await fetchSavedQuotes(); // Load saved quotes count
      await _loadGeneratedQuotesCount(); // Load generated quotes count
    }
  }

  Future<void> _loadGeneratedQuotesCount() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore.collection('user_stats').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('generatedQuotesCount')) {
        _generatedQuotesCount = doc.data()!['generatedQuotesCount'];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading generated quotes count: $e');
      // Just continue with whatever count we have
    }
  }

  Future<void> shareQuote(String quote, String category) async {
    try {
      final String text =
          '"$quote"\n\nCategory: $category\n\nShared via InspireCloud';
      await Share.share(text);
    } catch (e) {
      print('Error sharing quote: $e');
      throw Exception('Failed to share quote: $e');
    }
  }

  // Generate a quote using OpenAI
  Future<String> generateQuote({
    required String prompt,
    required String category,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to generate quotes');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final quote = await _openAIService.generateQuote(
        prompt: prompt,
        category: category,
      );
      _generatedQuotesCount++;
      await _saveGeneratedQuotesCount();

      _isLoading = false;
      notifyListeners();
      return quote;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveGeneratedQuotesCount() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('user_stats').doc(userId).set({
        'generatedQuotesCount': _generatedQuotesCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving generated quotes count: $e');
    }
  }

  Future<void> refreshStatistics() async {
    await fetchSavedQuotes();
    await _loadGeneratedQuotesCount();
  }

  // Save a quote to Firestore
  Future<void> saveQuote({
    required String content,
    required String category,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to save quotes');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedQuote = SavedQuoteModel(
        content: content,
        userId: userId,
        category: category,
      );

      await _quoteService.saveQuote(savedQuote);
      await fetchSavedQuotes(); // Refresh the list
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Fetch saved quotes from Firestore
  Future<void> fetchSavedQuotes() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _savedQuotes = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _savedQuotes = await _quoteService.getSavedQuotes(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching saved quotes: $e');
      // Don't throw the error, just set empty list and continue ##
      _savedQuotes = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a saved quote
  Future<void> deleteQuote(String quoteId) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to delete quotes');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _quoteService.deleteQuote(quoteId);
      _savedQuotes.removeWhere((quote) => quote.id == quoteId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
