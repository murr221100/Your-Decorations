import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

SupabaseClient get _db => Supabase.instance.client;

class AuthRepository {
  Stream<User?> get authStateChanges async* {
    yield _db.auth.currentUser;
    yield* _db.auth.onAuthStateChange.map((s) => s.session?.user);
  }

  Future<void> signIn(String email, String password) async {
    await _db.auth
        .signInWithPassword(email: email.trim(), password: password);
  }

  /// يرجع true لو الحساب دخل مباشرة، و false لو يحتاج تأكيد البريد أولاً
  Future<bool> register(String name, String email, String password) async {
    final res = await _db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    return res.session != null;
  }

  Future<void> signOut() => _db.auth.signOut();

  /// المشرف = صف المستخدم في جدول profiles فيه role = 'admin'
  Stream<bool> watchIsAdmin(String uid) => _db
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', uid)
      .map((rows) => rows.isNotEmpty && rows.first['role'] == 'admin');
}

class ProductRepository {
  static const _bucket = 'products';

  Stream<List<Product>> watchAll() => _db
      .from('products')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Product.fromMap).toList());

  Stream<Product?> watchOne(String id) => _db
      .from('products')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .map((rows) => rows.isEmpty ? null : Product.fromMap(rows.first));

  Future<String> _upload(String productId, XFile f) async {
    final bytes = await f.readAsBytes();
    final safe = f.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$productId/${DateTime.now().microsecondsSinceEpoch}_$safe';
    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: f.mimeType ?? 'image/jpeg'),
        );
    return _db.storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> _tryDeleteImage(String url) async {
    try {
      const marker = '/object/public/$_bucket/';
      final i = url.indexOf(marker);
      if (i == -1) return;
      await _db.storage.from(_bucket).remove([url.substring(i + marker.length)]);
    } catch (_) {}
  }

  Future<void> save({
    Product? existing,
    required String name,
    required String description,
    required double price,
    required int stock,
    required List<String> keptImages,
    required List<XFile> newImages,
  }) async {
    final String id;
    if (existing == null) {
      final row = await _db
          .from('products')
          .insert({
            'name': name,
            'description': description,
            'price': price,
            'stock': stock,
            'images': <String>[],
          })
          .select('id')
          .single();
      id = row['id'] as String;
    } else {
      id = existing.id;
    }

    final urls = <String>[...keptImages];
    for (final f in newImages) {
      urls.add(await _upload(id, f));
    }
    await _db.from('products').update({
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'images': urls,
    }).eq('id', id);

    if (existing != null) {
      for (final old in existing.images.where((u) => !keptImages.contains(u))) {
        await _tryDeleteImage(old);
      }
    }
  }

  Future<void> delete(Product p) async {
    await _db.from('products').delete().eq('id', p.id);
    for (final u in p.images) {
      await _tryDeleteImage(u);
    }
  }
}

class OrderRepository {
  Future<void> placeOrder(OrderModel o) async {
    await _db.from('orders').insert(o.toMap());
  }

  Stream<List<OrderModel>> watchMine(String uid) => _db
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(OrderModel.fromMap).toList());

  Stream<List<OrderModel>> watchAll() => _db
      .from('orders')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(OrderModel.fromMap).toList());

  Future<void> updateStatus(String id, String status) async {
    await _db.from('orders').update({'status': status}).eq('id', id);
  }
}

class InquiryRepository {
  Future<void> send(Inquiry i) async {
    await _db.from('inquiries').insert(i.toMap());
  }

  Stream<List<Inquiry>> watchAll() => _db
      .from('inquiries')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Inquiry.fromMap).toList());
}
