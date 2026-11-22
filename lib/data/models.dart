class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> images;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
  });

  bool get inStock => stock > 0;

  factory Product.fromMap(Map<String, dynamic> d) => Product(
        id: d['id'] as String,
        name: (d['name'] ?? '') as String,
        description: (d['description'] ?? '') as String,
        price: ((d['price'] ?? 0) as num).toDouble(),
        stock: ((d['stock'] ?? 0) as num).toInt(),
        images: List<String>.from(d['images'] ?? const <String>[]),
      );
}

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? image;
  final int qty;
  final int maxStock;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.qty,
    required this.maxStock,
  });

  double get subtotal => price * qty;

  CartItem copyWith({int? qty}) => CartItem(
        productId: productId,
        name: name,
        price: price,
        image: image,
        qty: qty ?? this.qty,
        maxStock: maxStock,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'image': image,
        'qty': qty,
      };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
        productId: (m['productId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        price: ((m['price'] ?? 0) as num).toDouble(),
        image: m['image'] as String?,
        qty: ((m['qty'] ?? 1) as num).toInt(),
        maxStock: 0,
      );
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v as String)?.toLocal();

class OrderModel {
  final String id;
  final String userId;
  final String userEmail;
  final String customerName;
  final String phone;
  final String address;
  final String notes;
  final String paymentMethod;
  final String status;
  final List<CartItem> items;
  final double total;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.notes,
    required this.paymentMethod,
    required this.status,
    required this.items,
    required this.total,
    this.createdAt,
  });

  /// للإدخال في قاعدة البيانات (id و created_at يتولدان تلقائياً)
  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'user_email': userEmail,
        'customer_name': customerName,
        'phone': phone,
        'address': address,
        'notes': notes,
        'payment_method': paymentMethod,
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
      };

  factory OrderModel.fromMap(Map<String, dynamic> d) => OrderModel(
        id: d['id'] as String,
        userId: (d['user_id'] ?? '') as String,
        userEmail: (d['user_email'] ?? '') as String,
        customerName: (d['customer_name'] ?? '') as String,
        phone: (d['phone'] ?? '') as String,
        address: (d['address'] ?? '') as String,
        notes: (d['notes'] ?? '') as String,
        paymentMethod: (d['payment_method'] ?? 'cod') as String,
        status: (d['status'] ?? 'pending') as String,
        items: ((d['items'] ?? const []) as List)
            .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: ((d['total'] ?? 0) as num).toDouble(),
        createdAt: _date(d['created_at']),
      );
}

class Inquiry {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String message;
  final String? productId;
  final String? productName;
  final DateTime? createdAt;

  const Inquiry({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    this.productId,
    this.productName,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'product_id': productId,
        'product_name': productName,
      };

  factory Inquiry.fromMap(Map<String, dynamic> d) => Inquiry(
        id: d['id'] as String,
        userId: (d['user_id'] ?? '') as String,
        name: (d['name'] ?? '') as String,
        email: (d['email'] ?? '') as String,
        phone: (d['phone'] ?? '') as String,
        message: (d['message'] ?? '') as String,
        productId: d['product_id'] as String?,
        productName: d['product_name'] as String?,
        createdAt: _date(d['created_at']),
      );
}
