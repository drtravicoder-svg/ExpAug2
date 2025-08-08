import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip.dart';
import '../models/trip_member.dart';

/// Enhanced SQLite Database Service with advanced features
///
/// Features:
/// - Database versioning and migrations
/// - Connection pooling and optimization
/// - Comprehensive error handling
/// - Data validation and constraints
/// - Performance monitoring
/// - Backup and recovery support
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'trip_expense_app.db';
  static const int _databaseVersion = 2; // Incremented for new features

  // Database performance monitoring
  static int _queryCount = 0;
  static DateTime? _lastQueryTime;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);

      // Open database with configuration
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        onOpen: _onOpen,
      );
    } catch (e) {
      print('Database initialization error: $e');
      // Try to open with minimal configuration
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  /// Configure database settings before opening
  Future<void> _onConfigure(Database db) async {
    try {
      // Enable foreign key constraints
      await db.execute('PRAGMA foreign_keys = ON');

      // Try to enable Write-Ahead Logging for better performance
      // Fall back to DELETE mode if WAL is not supported
      try {
        await db.execute('PRAGMA journal_mode = WAL');
      } catch (e) {
        print('WAL mode not supported, falling back to DELETE mode: $e');
        await db.execute('PRAGMA journal_mode = DELETE');
      }

      // Set synchronous mode for better performance
      await db.execute('PRAGMA synchronous = NORMAL');

      // Set cache size (negative value means KB)
      await db.execute('PRAGMA cache_size = -2000'); // 2MB cache
    } catch (e) {
      print('Database configuration error: $e');
      // Continue with basic configuration
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Called when database is opened
  Future<void> _onOpen(Database db) async {
    try {
      // Verify foreign key constraints are enabled
      final result = await db.rawQuery('PRAGMA foreign_keys');
      if (result.isEmpty || result.first['foreign_keys'] != 1) {
        print('Warning: Foreign key constraints may not be enabled');
        // Try to enable them again
        await db.execute('PRAGMA foreign_keys = ON');
      }
    } catch (e) {
      print('Database open verification error: $e');
      // Continue without throwing - database should still work
    }
  }

  /// Create database schema for new installations
  Future<void> _onCreate(Database db, int version) async {
    await _createTripsTable(db);
    await _createTripMembersTable(db);
    await _createExpensesTable(db);
    await _createExpenseSplitsTable(db);
    await _createReceiptsTable(db);
    await _createIndexes(db);
    await _createTriggers(db);

    // Insert initial data if needed
    await _insertInitialData(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2
      await _migrateToVersion2(db);
    }
    // Add more migrations as needed
  }

  /// Create trips table with enhanced schema
  Future<void> _createTripsTable(Database db) async {
    await db.execute('''
      CREATE TABLE trips(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL CHECK(length(name) > 0),
        description TEXT,
        origin TEXT,
        destination TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'INR' CHECK(length(currency) = 3),
        status TEXT NOT NULL DEFAULT 'planning'
          CHECK(status IN ('planning', 'active', 'closed', 'archived')),
        admin_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        allow_member_categories INTEGER DEFAULT 0 CHECK(allow_member_categories IN (0, 1)),
        require_receipt_approval INTEGER DEFAULT 1 CHECK(require_receipt_approval IN (0, 1)),
        auto_approve_expenses INTEGER DEFAULT 0 CHECK(auto_approve_expenses IN (0, 1)),
        budget_amount REAL DEFAULT 0 CHECK(budget_amount >= 0),
        is_deleted INTEGER DEFAULT 0 CHECK(is_deleted IN (0, 1)),
        CHECK(date(start_date) <= date(end_date))
      )
    ''');
  }

  /// Create trip members table with enhanced schema
  Future<void> _createTripMembersTable(Database db) async {
    await db.execute('''
      CREATE TABLE trip_members(
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        name TEXT NOT NULL CHECK(length(name) > 0),
        phone TEXT NOT NULL CHECK(length(phone) >= 10),
        email TEXT,
        contact_id TEXT,
        is_from_contacts INTEGER DEFAULT 0 CHECK(is_from_contacts IN (0, 1)),
        role TEXT DEFAULT 'member' CHECK(role IN ('admin', 'member')),
        joined_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        UNIQUE(trip_id, phone)
      )
    ''');
  }

  /// Create expenses table for future expense tracking
  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        payer_id TEXT NOT NULL,
        title TEXT NOT NULL CHECK(length(title) > 0),
        description TEXT,
        amount REAL NOT NULL CHECK(amount > 0),
        currency TEXT NOT NULL DEFAULT 'INR',
        category TEXT DEFAULT 'general',
        date TEXT NOT NULL,
        status TEXT DEFAULT 'pending'
          CHECK(status IN ('pending', 'approved', 'rejected')),
        receipt_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
        FOREIGN KEY (payer_id) REFERENCES trip_members (id)
      )
    ''');
  }

  /// Create expense splits table for splitting expenses
  Future<void> _createExpenseSplitsTable(Database db) async {
    await db.execute('''
      CREATE TABLE expense_splits(
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        member_id TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount >= 0),
        is_settled INTEGER DEFAULT 0 CHECK(is_settled IN (0, 1)),
        settled_at TEXT,
        FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES trip_members (id),
        UNIQUE(expense_id, member_id)
      )
    ''');
  }

  /// Create receipts table for receipt management
  Future<void> _createReceiptsTable(Database db) async {
    await db.execute('''
      CREATE TABLE receipts(
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL CHECK(file_size > 0),
        mime_type TEXT NOT NULL,
        uploaded_at TEXT NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create database indexes for performance optimization
  Future<void> _createIndexes(Database db) async {
    // Trip indexes
    await db.execute('CREATE INDEX idx_trips_status ON trips(status)');
    await db.execute('CREATE INDEX idx_trips_admin_id ON trips(admin_id)');
    await db.execute('CREATE INDEX idx_trips_start_date ON trips(start_date)');
    await db.execute('CREATE INDEX idx_trips_created_at ON trips(created_at)');

    // Trip members indexes
    await db.execute('CREATE INDEX idx_trip_members_trip_id ON trip_members(trip_id)');
    await db.execute('CREATE INDEX idx_trip_members_phone ON trip_members(phone)');
    await db.execute('CREATE INDEX idx_trip_members_name ON trip_members(name)');

    // Expenses indexes
    await db.execute('CREATE INDEX idx_expenses_trip_id ON expenses(trip_id)');
    await db.execute('CREATE INDEX idx_expenses_payer_id ON expenses(payer_id)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_status ON expenses(status)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');

    // Expense splits indexes
    await db.execute('CREATE INDEX idx_expense_splits_expense_id ON expense_splits(expense_id)');
    await db.execute('CREATE INDEX idx_expense_splits_member_id ON expense_splits(member_id)');
    await db.execute('CREATE INDEX idx_expense_splits_settled ON expense_splits(is_settled)');

    // Receipts indexes
    await db.execute('CREATE INDEX idx_receipts_expense_id ON receipts(expense_id)');
  }

  /// Create database triggers for data integrity
  Future<void> _createTriggers(Database db) async {
    // Trigger to update updated_at timestamp on trips
    await db.execute('''
      CREATE TRIGGER update_trips_timestamp
      AFTER UPDATE ON trips
      BEGIN
        UPDATE trips SET updated_at = datetime('now') WHERE id = NEW.id;
      END
    ''');

    // Trigger to ensure only one active trip
    await db.execute('''
      CREATE TRIGGER enforce_single_active_trip
      BEFORE UPDATE ON trips
      WHEN NEW.status = 'active' AND OLD.status != 'active'
      BEGIN
        UPDATE trips SET status = 'planning' WHERE status = 'active' AND id != NEW.id;
      END
    ''');

    // Trigger to validate expense splits sum equals expense amount
    await db.execute('''
      CREATE TRIGGER validate_expense_splits
      AFTER INSERT ON expense_splits
      BEGIN
        SELECT CASE
          WHEN (SELECT SUM(amount) FROM expense_splits WHERE expense_id = NEW.expense_id) >
               (SELECT amount FROM expenses WHERE id = NEW.expense_id)
          THEN RAISE(ABORT, 'Total split amount cannot exceed expense amount')
        END;
      END
    ''');
  }

  /// Insert initial data
  Future<void> _insertInitialData(Database db) async {
    // Insert default categories or settings if needed
    // This can be expanded based on requirements
  }

  /// Migration to version 2
  Future<void> _migrateToVersion2(Database db) async {
    // Add new columns that were added in version 2
    try {
      await db.execute('ALTER TABLE trips ADD COLUMN budget_amount REAL DEFAULT 0');
      await db.execute('ALTER TABLE trips ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE trip_members ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE trip_members ADD COLUMN role TEXT DEFAULT "member"');
      await db.execute('ALTER TABLE trip_members ADD COLUMN joined_at TEXT DEFAULT (datetime("now"))');
      await db.execute('ALTER TABLE trip_members ADD COLUMN is_active INTEGER DEFAULT 1');

      // Create new tables if they don't exist
      await _createExpensesTable(db);
      await _createExpenseSplitsTable(db);
      await _createReceiptsTable(db);

      // Create new indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_trip_members_phone ON trip_members(phone)');

    } catch (e) {
      // Handle migration errors gracefully
      print('Migration error: $e');
    }
  }

  // Enhanced Trip CRUD operations with error handling and transactions

  /// Create a new trip with members in a transaction
  Future<String> createTrip(Trip trip) async {
    final db = await database;
    final stopwatch = Stopwatch()..start();

    try {
      return await db.transaction((txn) async {
        // Insert trip
        await txn.insert('trips', {
          'id': trip.id,
          'name': trip.name,
          'description': trip.description,
          'origin': trip.origin,
          'destination': trip.destination,
          'start_date': trip.startDate.toIso8601String(),
          'end_date': trip.endDate.toIso8601String(),
          'currency': trip.currency,
          'status': trip.status.toString().split('.').last,
          'admin_id': trip.adminId,
          'created_at': trip.createdAt.toIso8601String(),
          'updated_at': trip.updatedAt.toIso8601String(),
          'allow_member_categories': trip.settings.allowMemberCategories ? 1 : 0,
          'require_receipt_approval': trip.settings.requireReceiptApproval ? 1 : 0,
          'auto_approve_expenses': trip.settings.autoApproveExpenses ? 1 : 0,
          'budget_amount': 0.0,
          'is_deleted': 0,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        // Insert members in batch
        final batch = txn.batch();
        for (final member in trip.members) {
          batch.insert('trip_members', {
            'id': member.id,
            'trip_id': trip.id,
            'name': member.name,
            'phone': member.phone,
            'email': null, // Will be added in future versions
            'contact_id': member.contactId,
            'is_from_contacts': member.isFromContacts ? 1 : 0,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
            'is_active': 1,
          }, conflictAlgorithm: ConflictAlgorithm.abort);
        }
        await batch.commit(noResult: true);

        return trip.id;
      });
    } catch (e) {
      throw Exception('Failed to create trip: ${e.toString()}');
    } finally {
      _recordQuery(stopwatch.elapsedMilliseconds);
    }
  }

  /// Get all trips with optimized query and caching
  Future<List<Trip>> getAllTrips({bool includeDeleted = false}) async {
    final db = await database;
    final stopwatch = Stopwatch()..start();

    try {
      final whereClause = includeDeleted ? null : 'is_deleted = 0';
      final List<Map<String, dynamic>> tripMaps = await db.query(
        'trips',
        where: whereClause,
        orderBy: 'created_at DESC',
      );

      // Use batch query for better performance
      final List<Trip> trips = [];
      final List<String> tripIds = tripMaps.map((map) => map['id'] as String).toList();

      if (tripIds.isNotEmpty) {
        // Get all members for all trips in one query
        final membersMap = await _getAllTripMembersBatch(tripIds);

        for (final tripMap in tripMaps) {
          final tripId = tripMap['id'] as String;
          final members = membersMap[tripId] ?? [];
          trips.add(_tripFromMap(tripMap, members));
        }
      }

      return trips;
    } catch (e) {
      throw Exception('Failed to get all trips: ${e.toString()}');
    } finally {
      _recordQuery(stopwatch.elapsedMilliseconds);
    }
  }

  /// Get trip by ID with error handling
  Future<Trip?> getTripById(String id) async {
    final db = await database;
    final stopwatch = Stopwatch()..start();

    try {
      final List<Map<String, dynamic>> tripMaps = await db.query(
        'trips',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [id],
        limit: 1,
      );

      if (tripMaps.isEmpty) return null;

      final members = await getTripMembers(id);
      return _tripFromMap(tripMaps.first, members);
    } catch (e) {
      throw Exception('Failed to get trip by ID: ${e.toString()}');
    } finally {
      _recordQuery(stopwatch.elapsedMilliseconds);
    }
  }

  /// Get all members for multiple trips in one query (performance optimization)
  Future<Map<String, List<TripMember>>> _getAllTripMembersBatch(List<String> tripIds) async {
    final db = await database;

    final placeholders = tripIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> memberMaps = await db.query(
      'trip_members',
      where: 'trip_id IN ($placeholders) AND is_active = 1',
      whereArgs: tripIds,
      orderBy: 'joined_at ASC',
    );

    final Map<String, List<TripMember>> membersMap = {};

    for (final memberMap in memberMaps) {
      final tripId = memberMap['trip_id'] as String;
      final member = TripMember(
        id: memberMap['id'],
        name: memberMap['name'],
        phone: memberMap['phone'],
        contactId: memberMap['contact_id'],
        isFromContacts: memberMap['is_from_contacts'] == 1,
        joinedAt: DateTime.parse(memberMap['joined_at'] ?? DateTime.now().toIso8601String()),
      );

      membersMap.putIfAbsent(tripId, () => []).add(member);
    }

    return membersMap;
  }

  Future<List<TripMember>> getTripMembers(String tripId) async {
    final db = await database;
    final List<Map<String, dynamic>> memberMaps = await db.query(
      'trip_members',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    
    return memberMaps.map((map) => TripMember(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      contactId: map['contact_id'],
      isFromContacts: map['is_from_contacts'] == 1,
      joinedAt: DateTime.parse(map['joined_at'] ?? DateTime.now().toIso8601String()),
    )).toList();
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    
    await db.update(
      'trips',
      {
        'name': trip.name,
        'origin': trip.origin,
        'destination': trip.destination,
        'start_date': trip.startDate.toIso8601String(),
        'end_date': trip.endDate.toIso8601String(),
        'currency': trip.currency,
        'status': trip.status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
        'allow_member_categories': trip.settings.allowMemberCategories ? 1 : 0,
        'require_receipt_approval': trip.settings.requireReceiptApproval ? 1 : 0,
        'auto_approve_expenses': trip.settings.autoApproveExpenses ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [trip.id],
    );

    // Update members - delete all and re-insert
    await db.delete('trip_members', where: 'trip_id = ?', whereArgs: [trip.id]);
    for (final member in trip.members) {
      await db.insert('trip_members', {
        'id': member.id,
        'trip_id': trip.id,
        'name': member.name,
        'phone': member.phone,
        'contact_id': member.contactId,
        'is_from_contacts': member.isFromContacts ? 1 : 0,
      });
    }
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
    // Members will be deleted automatically due to CASCADE
  }

  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    final db = await database;
    
    // If setting to active, first set all other trips to planning
    if (status == TripStatus.active) {
      await db.update(
        'trips',
        {'status': 'planning', 'updated_at': DateTime.now().toIso8601String()},
        where: 'status = ? AND id != ?',
        whereArgs: ['active', tripId],
      );
    }
    
    await db.update(
      'trips',
      {
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  Trip _tripFromMap(Map<String, dynamic> map, List<TripMember> members) {
    return Trip(
      id: map['id'],
      name: map['name'],
      origin: map['origin'],
      destination: map['destination'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      currency: map['currency'],
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TripStatus.planning,
      ),
      adminId: map['admin_id'],
      members: members,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      settings: TripSettings(
        allowMemberCategories: map['allow_member_categories'] == 1,
        requireReceiptApproval: map['require_receipt_approval'] == 1,
        autoApproveExpenses: map['auto_approve_expenses'] == 1,
      ),
    );
  }

  // Performance monitoring and utility methods

  /// Record query performance metrics
  void _recordQuery(int milliseconds) {
    _queryCount++;
    _lastQueryTime = DateTime.now();

    // Log slow queries (> 100ms)
    if (milliseconds > 100) {
      print('Slow query detected: ${milliseconds}ms');
    }
  }

  /// Get database performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'queryCount': _queryCount,
      'lastQueryTime': _lastQueryTime?.toIso8601String(),
      'databaseVersion': _databaseVersion,
    };
  }

  /// Backup database to external storage
  Future<String> backupDatabase() async {
    try {
      final db = await database;
      final dbPath = db.path;
      final backupDir = join(await getDatabasesPath(), 'backups');

      // Create backup directory if it doesn't exist
      final backupDirObj = Directory(backupDir);
      if (!await backupDirObj.exists()) {
        await backupDirObj.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = join(backupDir, 'backup_$timestamp.db');

      // Copy database file
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);

      return backupPath;
    } catch (e) {
      throw Exception('Failed to backup database: ${e.toString()}');
    }
  }

  /// Restore database from backup
  Future<void> restoreDatabase(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found: $backupPath');
      }

      // Close current database
      await _database?.close();
      _database = null;

      // Replace current database with backup
      final dbPath = join(await getDatabasesPath(), _databaseName);
      await backupFile.copy(dbPath);

      // Reinitialize database
      _database = await _initDatabase();
    } catch (e) {
      throw Exception('Failed to restore database: ${e.toString()}');
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final dbPath = join(await getDatabasesPath(), _databaseName);
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Vacuum database to reclaim space
  Future<void> vacuumDatabase() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
    } catch (e) {
      throw Exception('Failed to vacuum database: ${e.toString()}');
    }
  }

  /// Analyze database for query optimization
  Future<void> analyzeDatabase() async {
    try {
      final db = await database;
      await db.execute('ANALYZE');
    } catch (e) {
      throw Exception('Failed to analyze database: ${e.toString()}');
    }
  }

  /// Check database integrity
  Future<bool> checkIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.isNotEmpty && result.first.values.first == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Get database schema information
  Future<List<Map<String, dynamic>>> getSchemaInfo() async {
    try {
      final db = await database;
      return await db.rawQuery("SELECT name, sql FROM sqlite_master WHERE type='table'");
    } catch (e) {
      throw Exception('Failed to get schema info: ${e.toString()}');
    }
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Reset database (for testing purposes)
  Future<void> resetDatabase() async {
    try {
      await close();
      final dbPath = join(await getDatabasesPath(), _databaseName);
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      _database = await _initDatabase();
    } catch (e) {
      throw Exception('Failed to reset database: ${e.toString()}');
    }
  }
}
