import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/services/session_manager.dart';
import 'wallet_model.dart';
import 'saved_card_model.dart';

/// خدمة المحفظة - Supabase Integration
class WalletService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SessionManager _sessionManager = SessionManager();

  /// Get current user's wallet
  Future<Wallet?> getWallet() async {
    try {
      // Ensure valid session before API call
      final isValid = await _sessionManager.ensureValidSession();
      if (!isValid) return null;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create wallet if doesn't exist
        return await _createWallet(userId);
      }

      return Wallet.fromJson(response);
    } catch (e) {
      // Handle JWT errors gracefully - try refresh first
      await _sessionManager.handleSupabaseError(e);
      print('Error getting wallet: $e');
      return null;
    }
  }

  /// Create wallet for user (uses upsert to handle race conditions)
  Future<Wallet?> _createWallet(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .upsert(
            {'user_id': userId, 'balance': 0.0},
            onConflict: 'user_id',
            ignoreDuplicates: true,
          )
          .select()
          .maybeSingle();

      // If upsert returned nothing (ignoreDuplicates), fetch existing
      if (response == null) {
        final existing = await _supabase
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (existing != null) {
          return Wallet.fromJson(existing);
        }
        return null;
      }

      return Wallet.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Duplicate - fetch existing wallet
        final existing = await _supabase
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (existing != null) {
          return Wallet.fromJson(existing);
        }
      }
      print('Error creating wallet: $e');
      return null;
    } catch (e) {
      print('Error creating wallet: $e');
      return null;
    }
  }

  /// Get wallet transactions
  Future<List<WalletTransaction>> getTransactions({int limit = 20}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // First get wallet id
      final wallet = await getWallet();
      if (wallet == null || wallet.id.isEmpty) return [];

      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', wallet.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Add balance to wallet (will be called after PayMob success)
  Future<bool> addBalance(double amount, {String? description}) async {
    try {
      final wallet = await getWallet();
      if (wallet == null) return false;

      final newBalance = wallet.balance + amount;

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('id', wallet.id);

      // Record transaction
      await _supabase.from('wallet_transactions').insert({
        'wallet_id': wallet.id,
        'type': 'deposit',
        'amount': amount,
        'balance_after': newBalance,
        'description': description ?? 'إضافة رصيد',
      });

      return true;
    } catch (e) {
      print('Error adding balance: $e');
      return false;
    }
  }

  /// Deduct balance for order payment
  Future<bool> payFromWallet(double amount, String orderId) async {
    try {
      final wallet = await getWallet();
      if (wallet == null) return false;
      if (wallet.balance < amount) return false; // Insufficient balance

      final newBalance = wallet.balance - amount;

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('id', wallet.id);

      // Record transaction
      await _supabase.from('wallet_transactions').insert({
        'wallet_id': wallet.id,
        'type': 'payment',
        'amount': amount,
        'balance_after': newBalance,
        'order_id': orderId,
        'description': 'دفع طلب',
      });

      return true;
    } catch (e) {
      print('Error paying from wallet: $e');
      return false;
    }
  }

  /// Refund to wallet
  Future<bool> refundToWallet(double amount, String orderId) async {
    try {
      final wallet = await getWallet();
      if (wallet == null) return false;

      final newBalance = wallet.balance + amount;

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('id', wallet.id);

      // Record transaction
      await _supabase.from('wallet_transactions').insert({
        'wallet_id': wallet.id,
        'type': 'refund',
        'amount': amount,
        'balance_after': newBalance,
        'order_id': orderId,
        'description': 'استرداد رصيد',
      });

      return true;
    } catch (e) {
      print('Error refunding to wallet: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Saved Cards
  // ══════════════════════════════════════════════════════════════

  /// Get saved cards
  Future<List<SavedCard>> getSavedCards() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('saved_cards')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedCard.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting saved cards: $e');
      return [];
    }
  }

  /// Save card (after PayMob tokenization)
  Future<SavedCard?> saveCard({
    required String cardToken,
    required String lastFourDigits,
    required String cardBrand,
    String? cardLabel,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('saved_cards')
          .insert({
            'user_id': userId,
            'card_token': cardToken,
            'last_four_digits': lastFourDigits,
            'card_brand': cardBrand,
            'card_label': cardLabel,
          })
          .select()
          .single();

      return SavedCard.fromJson(response);
    } catch (e) {
      print('Error saving card: $e');
      return null;
    }
  }

  /// Delete saved card
  Future<bool> deleteCard(String cardId) async {
    try {
      await _supabase.from('saved_cards').delete().eq('id', cardId);
      return true;
    } catch (e) {
      print('Error deleting card: $e');
      return false;
    }
  }

  /// Set card as default
  Future<bool> setDefaultCard(String cardId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Remove default from all cards
      await _supabase
          .from('saved_cards')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Set new default
      await _supabase
          .from('saved_cards')
          .update({'is_default': true})
          .eq('id', cardId);

      return true;
    } catch (e) {
      print('Error setting default card: $e');
      return false;
    }
  }
}
