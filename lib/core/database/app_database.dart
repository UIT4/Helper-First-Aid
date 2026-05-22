import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class Tables {
  static const users = 'users';
  static const categories = 'categories';
  static const guidanceSteps = 'guidance_steps';
  static const patient = 'patient_profile';
  static const contacts = 'emergency_contacts';
  static const incidents = 'incidents';
  static const settings = 'settings';
}

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'rescue_v2.db');

    return openDatabase(
      path,
      version: 8,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuest') ?? false;
  }

  Future<String?> _currentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final guest = prefs.getBool('isGuest') ?? false;
    if (guest) return null;

    final email = prefs.getString('userEmail');
    if (email == null || email.trim().isEmpty) return null;

    return email.trim().toLowerCase();
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${Tables.users}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Tables.categories}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name_en TEXT,
        name_ar TEXT,
        urgency_level TEXT DEFAULT 'medium',
        icon_key TEXT DEFAULT '',
        sort_order INTEGER DEFAULT 1,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Tables.guidanceSteps}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_code TEXT,
        step_no INTEGER,
        title_en TEXT,
        title_ar TEXT,
        body_en TEXT,
        body_ar TEXT,
        warning_en TEXT,
        warning_ar TEXT,
        image_path TEXT,
        image_asset TEXT,
        updated_at TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (category_code) REFERENCES ${Tables.categories}(code)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Tables.patient}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT,
        full_name TEXT,
        age INTEGER,
        sex TEXT,
        blood_type TEXT,
        allergies TEXT,
        conditions TEXT,
        medications TEXT,
        notes TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Tables.contacts}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT,
        name TEXT,
        phone TEXT,
        relation TEXT,
        is_primary INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Tables.incidents}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT,
        created_at TEXT,
        lang TEXT,
        input_text TEXT,
        predicted_category_code TEXT,
        confidence REAL,
        urgency TEXT,
        lat REAL,
        lng REAL,
        location_source TEXT,
        notes TEXT,
        device_id TEXT,
        synced INTEGER DEFAULT 0,
        server_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ${Tables.settings}(
        id INTEGER PRIMARY KEY,
        language TEXT DEFAULT 'en',
        country TEXT DEFAULT 'Jordan',
        emergency_number TEXT DEFAULT '911',
        ambulance_number TEXT DEFAULT '193',
        fire_number TEXT DEFAULT '199',
        country_code TEXT DEFAULT '+962',
        content_version INTEGER DEFAULT 1,
        large_text INTEGER DEFAULT 0
      )
    ''');

    await db.insert(
      Tables.settings,
      {
        'id': 1,
        'language': 'en',
        'country': 'Jordan',
        'emergency_number': '911',
        'ambulance_number': '193',
        'fire_number': '199',
        'country_code': '+962',
        'content_version': 1,
        'large_text': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await _insertDefaultCategories(db);
    await _insertDefaultSteps(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _safeAddColumn(db, Tables.patient, 'sex TEXT');
      await _safeAddColumn(db, Tables.patient, 'conditions TEXT');
      await _safeAddColumn(db, Tables.patient, 'medications TEXT');
      await _safeAddColumn(db, Tables.patient, 'notes TEXT');

      await _safeAddColumn(db, Tables.incidents, 'device_id TEXT');
      await _safeAddColumn(db, Tables.incidents, 'lang TEXT');
      await _safeAddColumn(db, Tables.incidents, 'lat REAL');
      await _safeAddColumn(db, Tables.incidents, 'lng REAL');
      await _safeAddColumn(db, Tables.incidents, 'location_source TEXT');
      await _safeAddColumn(db, Tables.incidents, 'notes TEXT');
      await _safeAddColumn(db, Tables.incidents, 'synced INTEGER DEFAULT 0');
      await _safeAddColumn(db, Tables.incidents, 'server_id INTEGER');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Tables.categories}(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT UNIQUE,
          name_en TEXT,
          name_ar TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Tables.guidanceSteps}(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_code TEXT,
          step_no INTEGER,
          title_en TEXT,
          title_ar TEXT,
          body_en TEXT,
          body_ar TEXT,
          image_asset TEXT,
          updated_at TEXT,
          FOREIGN KEY (category_code) REFERENCES ${Tables.categories}(code)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Tables.settings}(
          id INTEGER PRIMARY KEY,
          language TEXT DEFAULT 'en',
          country TEXT DEFAULT 'Jordan',
          emergency_number TEXT DEFAULT '911',
          ambulance_number TEXT DEFAULT '193',
          fire_number TEXT DEFAULT '199',
          country_code TEXT DEFAULT '+962',
          content_version INTEGER DEFAULT 1,
          large_text INTEGER DEFAULT 0
        )
      ''');

      await db.insert(
        Tables.settings,
        {
          'id': 1,
          'language': 'en',
          'country': 'Jordan',
          'emergency_number': '911',
          'ambulance_number': '193',
          'fire_number': '199',
          'country_code': '+962',
          'content_version': 1,
          'large_text': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await _insertDefaultCategories(db);
      await _insertDefaultSteps(db);
    }

    if (oldVersion < 4) {
      await _safeAddColumn(db, Tables.settings, 'content_version INTEGER DEFAULT 1');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${Tables.users}(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          full_name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 6) {
      await _safeAddColumn(db, Tables.patient, 'user_email TEXT');
      await _safeAddColumn(db, Tables.contacts, 'user_email TEXT');
      await _safeAddColumn(db, Tables.incidents, 'user_email TEXT');
      await _safeAddColumn(db, Tables.settings, 'large_text INTEGER DEFAULT 0');
    }

    if (oldVersion < 7) {
      await _safeAddColumn(
        db,
        Tables.settings,
        "country TEXT DEFAULT 'Jordan'",
      );
    }

    if (oldVersion < 8) {
      await _safeAddColumn(db, Tables.categories, "urgency_level TEXT DEFAULT 'medium'");
      await _safeAddColumn(db, Tables.categories, "icon_key TEXT DEFAULT ''");
      await _safeAddColumn(db, Tables.categories, "sort_order INTEGER DEFAULT 1");
      await _safeAddColumn(db, Tables.categories, "is_active INTEGER DEFAULT 1");

      await _safeAddColumn(db, Tables.guidanceSteps, 'warning_en TEXT');
      await _safeAddColumn(db, Tables.guidanceSteps, 'warning_ar TEXT');
      await _safeAddColumn(db, Tables.guidanceSteps, 'image_path TEXT');
      await _safeAddColumn(db, Tables.guidanceSteps, 'is_active INTEGER DEFAULT 1');
    }
  }

  Future<void> _safeAddColumn(Database db, String table, String columnDefinition) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    } catch (_) {
      // Column already exists.
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {'code': 'adult_choking', 'name_en': 'Adult Choking', 'name_ar': 'اختناق بالغ'},
      {'code': 'child_choking', 'name_en': 'Child Choking', 'name_ar': 'اختناق طفل'},
      {'code': 'asthma', 'name_en': 'Asthma Attack', 'name_ar': 'نوبة ربو'},
      {'code': 'anaphylaxis', 'name_en': 'Severe Allergy', 'name_ar': 'حساسية شديدة'},
      {'code': 'unconscious_breathing', 'name_en': 'Unconscious Breathing', 'name_ar': 'فاقد الوعي ويتنفس'},
      {'code': 'not_breathing_cpr', 'name_en': 'Not Breathing / CPR', 'name_ar': 'لا يتنفس / إنعاش'},
      {'code': 'bleeding', 'name_en': 'Heavy Bleeding', 'name_ar': 'نزيف شديد'},
      {'code': 'burns', 'name_en': 'Burn Injury', 'name_ar': 'حروق'},
      {'code': 'fracture', 'name_en': 'Fracture', 'name_ar': 'كسر'},
      {'code': 'seizure', 'name_en': 'Seizure', 'name_ar': 'تشنج'},
      {'code': 'stroke', 'name_en': 'Stroke', 'name_ar': 'سكتة دماغية'},
    ];

    for (final category in categories) {
      await db.insert(Tables.categories, category, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _insertDefaultSteps(Database db) async {
    final steps = [
      {'category_code': 'adult_choking', 'step_no': 1, 'title_en': 'Ask if they can speak', 'title_ar': 'اسأل إذا كان يستطيع الكلام', 'body_en': 'Ask "Are you choking?" If they cannot speak, cough, or breathe — act immediately.', 'body_ar': 'اسأل "هل تختنق؟" إذا لم يستطع الكلام أو السعال — تصرف فوراً.'},
      {'category_code': 'adult_choking', 'step_no': 2, 'title_en': 'Give 5 back blows', 'title_ar': 'أعطِ 5 ضربات على الظهر', 'body_en': 'Lean them forward. Strike firmly between shoulder blades 5 times with the heel of your hand.', 'body_ar': 'أمله للأمام. اضرب بقوة بين لوحي الكتف 5 مرات براحة يدك.'},
      {'category_code': 'adult_choking', 'step_no': 3, 'title_en': 'Give 5 abdominal thrusts', 'title_ar': 'أعطِ 5 دفعات بطنية', 'body_en': 'Stand behind them, make a fist above the navel, and thrust sharply inward and upward 5 times.', 'body_ar': 'قف خلفه، ضع قبضتك فوق السرة، وادفع بقوة للداخل والأعلى 5 مرات.'},
      {'category_code': 'adult_choking', 'step_no': 4, 'title_en': 'Repeat until clear or unconscious', 'title_ar': 'كرر حتى يتحرر أو يفقد الوعي', 'body_en': 'Alternate 5 back blows and 5 thrusts. If unconscious, call emergency services and start CPR.', 'body_ar': 'بادل بين 5 ضربات ظهر و5 دفعات. إذا فقد الوعي اتصل بالطوارئ وابدأ الإنعاش.'},
      {'category_code': 'child_choking', 'step_no': 1, 'title_en': 'Check if child can cry or cough', 'title_ar': 'تحقق إذا كان الطفل يبكي أو يسعل', 'body_en': 'If the child cannot cry, cough or breathe, begin first aid immediately.', 'body_ar': 'إذا لم يستطع البكاء أو السعال أو التنفس، ابدأ الإسعاف فوراً.'},
      {'category_code': 'child_choking', 'step_no': 2, 'title_en': '5 back blows', 'title_ar': '5 ضربات ظهر', 'body_en': 'Lay child face-down on your forearm. Support head. Give 5 firm back blows.', 'body_ar': 'ضع الطفل وجهه للأسفل على ساعدك. دعم الرأس. أعطِ 5 ضربات ظهر قوية.'},
      {'category_code': 'child_choking', 'step_no': 3, 'title_en': '5 chest thrusts', 'title_ar': '5 دفعات صدرية', 'body_en': 'Turn child face-up. Give 5 chest thrusts with 2 fingers on center of chest.', 'body_ar': 'اقلب الطفل وجهه للأعلى. أعطِ 5 دفعات صدرية بإصبعين على مركز الصدر.'},
      {'category_code': 'asthma', 'step_no': 1, 'title_en': 'Sit them upright', 'title_ar': 'أجلسه في وضع مستقيم', 'body_en': 'Sit the person upright, leaning slightly forward. Do not lay them down.', 'body_ar': 'أجلس الشخص منتصباً مائلاً قليلاً للأمام. لا تضعه مستلقياً.'},
      {'category_code': 'asthma', 'step_no': 2, 'title_en': 'Use their inhaler', 'title_ar': 'استخدم البخاخ', 'body_en': 'Help them use their reliever inhaler. One puff every 30-60 seconds, up to 10 puffs.', 'body_ar': 'ساعده على استخدام بخاخ الإغاثة. نفخة كل 30-60 ثانية، حتى 10 نفخات.'},
      {'category_code': 'anaphylaxis', 'step_no': 1, 'title_en': 'Use EpiPen immediately', 'title_ar': 'استخدم حقنة الأدرينالين فوراً', 'body_en': 'If available, use an epinephrine auto-injector on outer thigh immediately.', 'body_ar': 'إذا كانت متوفرة، استخدم حقنة الأدرينالين على الفخذ الخارجي فوراً.'},
      {'category_code': 'anaphylaxis', 'step_no': 2, 'title_en': 'Call emergency services', 'title_ar': 'اتصل بالطوارئ فوراً', 'body_en': 'Call emergency services immediately even if symptoms improve.', 'body_ar': 'اتصل بالإسعاف فوراً حتى لو تحسنت الأعراض.'},
      {'category_code': 'unconscious_breathing', 'step_no': 1, 'title_en': 'Check responsiveness', 'title_ar': 'تحقق من الاستجابة', 'body_en': 'Tap shoulders and shout "Are you okay?" If no response, call emergency services.', 'body_ar': 'اربت على الكتفين واصرخ "هل أنت بخير؟" إذا لم يستجب، اتصل بالطوارئ.'},
      {'category_code': 'unconscious_breathing', 'step_no': 2, 'title_en': 'Recovery position', 'title_ar': 'وضعية الإفاقة', 'body_en': 'Roll them on their side to keep airway clear and prevent choking.', 'body_ar': 'اقلبه على جانبه للحفاظ على مجرى الهواء ومنع الاختناق.'},
      {'category_code': 'not_breathing_cpr', 'step_no': 1, 'title_en': 'Call emergency services now', 'title_ar': 'اتصل بالطوارئ الآن', 'body_en': 'Call emergency services immediately or ask someone nearby to call while you begin CPR.', 'body_ar': 'اتصل بالطوارئ فوراً أو اطلب من شخص قريب الاتصال بينما تبدأ الإنعاش.'},
      {'category_code': 'not_breathing_cpr', 'step_no': 2, 'title_en': '30 chest compressions', 'title_ar': '30 ضغطة على الصدر', 'body_en': 'Push down hard and fast. At least 5cm deep, 100-120 compressions per minute.', 'body_ar': 'اضغط بقوة وسرعة. عمق 5 سم على الأقل، 100-120 ضغطة في الدقيقة.'},
    ];

    for (final step in steps) {
      await db.insert(
        Tables.guidanceSteps,
        {
          ...step,
          'image_asset': '',
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> insertIncident(Map<String, dynamic> data) async {
    if (await isGuest()) return -1;
    final email = await _currentUserEmail();
    if (email == null) return -1;

    final db = await database;
    return db.insert(Tables.incidents, {
      ...data,
      'user_email': email,
      'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    final email = await _currentUserEmail();
    if (email == null) return [];

    final db = await database;
    return db.query(
      Tables.incidents,
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedIncidents() async {
    final email = await _currentUserEmail();
    if (email == null) return [];

    final db = await database;
    return db.query(
      Tables.incidents,
      where: 'user_email = ? AND synced = ?',
      whereArgs: [email, 0],
    );
  }

  Future<void> markIncidentSynced(int localId, int serverId) async {
    final email = await _currentUserEmail();
    if (email == null) return;

    final db = await database;
    await db.update(
      Tables.incidents,
      {'synced': 1, 'server_id': serverId},
      where: 'id = ? AND user_email = ?',
      whereArgs: [localId, email],
    );
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final email = await _currentUserEmail();
    if (email == null) return null;

    final db = await database;
    final result = await db.query(
      Tables.patient,
      where: 'user_email = ?',
      whereArgs: [email],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    if (await isGuest()) return;
    final email = await _currentUserEmail();
    if (email == null) return;

    final db = await database;
    await db.delete(Tables.patient, where: 'user_email = ?', whereArgs: [email]);
    await db.insert(Tables.patient, {
      ...profile,
      'user_email': email,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final email = await _currentUserEmail();
    if (email == null) return [];

    final db = await database;
    return db.query(
      Tables.contacts,
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'is_primary DESC, id DESC',
    );
  }

  Future<int> insertContact(Map<String, dynamic> contact) async {
    if (await isGuest()) {
      throw Exception('Guest users cannot add contacts');
    }

    final email = await _currentUserEmail();

    if (email == null || email.trim().isEmpty) {
      throw Exception('User session not found');
    }

    final db = await database;

    return db.insert(
      Tables.contacts,
      {
        ...contact,
        'user_email': email,
      },
    );
  }

  Future<void> updateContact(int id, Map<String, dynamic> contact) async {
    if (await isGuest()) return;
    final email = await _currentUserEmail();
    if (email == null) return;

    final db = await database;
    await db.update(
      Tables.contacts,
      contact,
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, email],
    );
  }

  Future<void> deleteContact(int id) async {
    if (await isGuest()) return;
    final email = await _currentUserEmail();
    if (email == null) return;

    final db = await database;
    await db.delete(
      Tables.contacts,
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, email],
    );
  }

  Future<void> setPrimaryContact(int id) async {
    if (await isGuest()) return;
    final email = await _currentUserEmail();
    if (email == null) return;

    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        Tables.contacts,
        {'is_primary': 0},
        where: 'user_email = ?',
        whereArgs: [email],
      );
      await txn.update(
        Tables.contacts,
        {'is_primary': 1},
        where: 'id = ? AND user_email = ?',
        whereArgs: [id, email],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query(
      Tables.categories,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getStepsByCategory(String categoryCode) async {
    final db = await database;
    return db.query(
      Tables.guidanceSteps,
      where: 'category_code = ? AND is_active = ?',
      whereArgs: [categoryCode, 1],
      orderBy: 'step_no ASC',
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final result = await db.query(
      Tables.settings,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isNotEmpty) return result.first;

    return {
      'language': 'en',
      'country': 'Jordan',
      'emergency_number': '911',
      'ambulance_number': '193',
      'fire_number': '199',
      'country_code': '+962',
      'content_version': 1,
      'large_text': 0,
    };
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.insert(
      Tables.settings,
      {'id': 1, ...settings},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getContentVersion() async {
    final settings = await getSettings();
    final value = settings['content_version'];

    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  Future<void> setContentVersion(int version) async {
    final db = await database;
    await db.update(
      Tables.settings,
      {'content_version': version},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<int> insertUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final db = await database;
    return db.insert(
      Tables.users,
      {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      Tables.users,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final result = await db.query(
      Tables.users,
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
