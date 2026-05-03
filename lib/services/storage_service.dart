import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Model representing an upload record (pending or completed).
///
/// [imagePath] is the canonical image reference:
///   • For **pending** uploads: the local file path.
///   • For **uploaded** records: the Cloudinary secure_url.
///
/// [localPath] optionally stores the on-device file path for uploaded
/// records so thumbnails can fall back to a local file before the
/// network image loads.
class PendingUpload {
  final int? id;

  /// Primary image reference.
  /// After a successful Cloudinary upload this is the remote https:// URL.
  final String imagePath;

  /// Optional on-device path kept for offline thumbnail display.
  final String? localPath;

  final String loanId;
  final String loanName;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? phone; // Added phone field
  final String status; // 'pending' or 'uploaded'

  PendingUpload({
    this.id,
    required this.imagePath,
    this.localPath,
    required this.loanId,
    required this.loanName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.phone,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'localPath': localPath,
      'loanId': loanId,
      'loanName': loanName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'phone': phone,
      'status': status,
    };
  }

  factory PendingUpload.fromMap(Map<String, dynamic> map) {
    return PendingUpload(
      id: map['id'],
      imagePath: map['imagePath'] as String,
      localPath: map['localPath'] as String?,
      loanId: map['loanId'] as String,
      loanName: map['loanName'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: map['timestamp'] as String,
      phone: map['phone'] as String?,
      status: map['status'] as String,
    );
  }
}

/// Singleton service for managing upload records in a local SQLite database.
/// Stores image metadata + upload status for offline-first capability.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'loan_uploads.db');
    return await openDatabase(
      path,
      version: 3, // Upgrade to version 3
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_uploads(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            localPath TEXT,
            loanId TEXT,
            loanName TEXT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            phone TEXT,
            status TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE pending_uploads ADD COLUMN localPath TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE pending_uploads ADD COLUMN phone TEXT');
        }
      },
    );
  }

  /// Insert a new upload record (defaults to 'pending' status)
  Future<int> insertUpload(PendingUpload upload) async {
    final db = await database;
    return await db.insert('pending_uploads', upload.toMap());
  }

  /// Get only records with status = 'pending'
  Future<List<PendingUpload>> getPendingUploads() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_uploads',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => PendingUpload.fromMap(maps[i]));
  }

  /// Get ALL records (both pending and uploaded) for history view
  Future<List<PendingUpload>> getAllUploads() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_uploads',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => PendingUpload.fromMap(maps[i]));
  }

  /// Get counts of pending vs uploaded records for dashboard badges
  Future<Map<String, int>> getUploadCounts() async {
    final db = await database;
    final pending = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM pending_uploads WHERE status = 'pending'",
    )) ?? 0;
    final uploaded = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM pending_uploads WHERE status = 'uploaded'",
    )) ?? 0;
    return {'pending': pending, 'uploaded': uploaded};
  }

  /// Mark a record as successfully uploaded (status only).
  /// Prefer [markAsUploadedWithUrl] when you have the Cloudinary URL.
  Future<void> markAsUploaded(int id) async {
    final db = await database;
    await db.update(
      'pending_uploads',
      {'status': 'uploaded'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark a record as uploaded AND replace the local imagePath with the
  /// Cloudinary [imageUrl] so the history screen can display a network image.
  ///
  /// This is the correct method to call after a successful Cloudinary upload.
  Future<void> markAsUploadedWithUrl(int id, String imageUrl) async {
    assert(imageUrl.startsWith('http'), 'imageUrl must be a remote URL');
    final db = await database;
    await db.update(
      'pending_uploads',
      {
        'status':    'uploaded',
        'imagePath': imageUrl,   // ✅ replace local path with Cloudinary URL
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    print('✅ StorageService: record $id marked uploaded with URL: $imageUrl');
  }

  /// Delete a record (e.g. when file is missing or user removes it)
  Future<void> deleteUpload(int id) async {
    final db = await database;
    await db.delete(
      'pending_uploads',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
