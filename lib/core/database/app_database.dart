import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Tables {
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
    String path = join(await getDatabasesPath(), 'rescue_v2.db');
    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // =====================================================
  // CREATE TABLES
  // =====================================================

  Future<void> _createDB(Database db, int version) async {
    // CATEGORIES
    await db.execute('''
      CREATE TABLE ${Tables.categories}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name_en TEXT,
        name_ar TEXT
      )
    ''');

    // GUIDANCE STEPS
    await db.execute('''
      CREATE TABLE ${Tables.guidanceSteps}(
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

    // PATIENT PROFILE
    await db.execute('''
      CREATE TABLE ${Tables.patient}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

    // EMERGENCY CONTACTS
    await db.execute('''
      CREATE TABLE ${Tables.contacts}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        relation TEXT,
        is_primary INTEGER DEFAULT 0
      )
    ''');

    // INCIDENTS
    await db.execute('''
      CREATE TABLE ${Tables.incidents}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT,
        lang TEXT,
        input_text TEXT,
        predicted_category TEXT,
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

    // SETTINGS
    await db.execute('''
      CREATE TABLE ${Tables.settings}(
        id INTEGER PRIMARY KEY,
        language TEXT DEFAULT 'en',
        emergency_number TEXT DEFAULT '911',
        ambulance_number TEXT DEFAULT '193',
        fire_number TEXT DEFAULT '199',
        country_code TEXT DEFAULT '+962',
        content_version INTEGER DEFAULT 1,
        large_text INTEGER DEFAULT 0
      )
    ''');

    // Default settings row
    await db.insert(Tables.settings, {
      'id': 1,
      'language': 'en',
      'emergency_number': '911',
      'ambulance_number': '193',
      'fire_number': '199',
      'country_code': '+962',
      'content_version': 1,
    });

    await _insertDefaultCategories(db);
    await _insertDefaultSteps(db);
  }

  // =====================================================
  // MIGRATION
  // =====================================================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add missing columns to patient_profile
      await db.execute('ALTER TABLE ${Tables.patient} ADD COLUMN sex TEXT');
      await db.execute('ALTER TABLE ${Tables.patient} ADD COLUMN conditions TEXT');
      await db.execute('ALTER TABLE ${Tables.patient} ADD COLUMN medications TEXT');
      await db.execute('ALTER TABLE ${Tables.patient} ADD COLUMN notes TEXT');

      // Add missing columns to incidents
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN device_id TEXT');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN lang TEXT');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN lat REAL');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN lng REAL');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN location_source TEXT');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN synced INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ${Tables.incidents} ADD COLUMN server_id INTEGER');

      // Create new tables
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
          emergency_number TEXT DEFAULT '911',
          ambulance_number TEXT DEFAULT '193',
          fire_number TEXT DEFAULT '199',
          country_code TEXT DEFAULT '+962'
        )
      ''');

      await db.insert(Tables.settings, {
        'id': 1,
        'language': 'en',
        'emergency_number': '911',
        'ambulance_number': '193',
        'fire_number': '199',
        'country_code': '+962',
      });

      await _insertDefaultCategories(db);
      await _insertDefaultSteps(db);
    }

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${Tables.settings} ADD COLUMN content_version INTEGER DEFAULT 1',
      );
    }
  }

  // =====================================================
  // DEFAULT DATA
  // =====================================================

  Future<void> _insertDefaultCategories(Database db) async {
    final cats = [
      {'code': 'adult_choking', 'name_en': 'Adult Choking', 'name_ar': 'اختناق بالغ'},
      {'code': 'child_choking', 'name_en': 'Child Choking', 'name_ar': 'اختناق طفل'},
      {'code': 'asthma', 'name_en': 'Asthma Attack', 'name_ar': 'نوبة ربو'},
      {'code': 'anaphylaxis', 'name_en': 'Severe Allergy', 'name_ar': 'حساسية شديدة'},
      {'code': 'unconscious_breathing', 'name_en': 'Unconscious Breathing', 'name_ar': 'فاقد الوعي ويتنفس'},
      {'code': 'not_breathing_cpr', 'name_en': 'Not Breathing / CPR', 'name_ar': 'لا يتنفس / إنعاش'},
    ];

    for (final cat in cats) {
      await db.insert(
        Tables.categories,
        cat,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _insertDefaultSteps(Database db) async {
    final steps = [
      {'category_code': 'adult_choking', 'step_no': 1, 'title_en': 'Ask if they can speak', 'title_ar': 'اسأل إذا كان يستطيع الكلام', 'body_en': 'Ask "Are you choking?" If they cannot speak, cough, or breathe — act immediately.', 'body_ar': 'اسأل "هل تختنق؟" إذا لم يستطع الكلام أو السعال — تصرف فوراً.'},
      {'category_code': 'adult_choking', 'step_no': 2, 'title_en': 'Give 5 back blows', 'title_ar': 'أعطِ 5 ضربات على الظهر', 'body_en': 'Lean them forward. Strike firmly between shoulder blades 5 times with the heel of your hand.', 'body_ar': 'أمله للأمام. اضرب بقوة بين لوحي الكتف 5 مرات براحة يدك.'},
      {'category_code': 'adult_choking', 'step_no': 3, 'title_en': 'Give 5 abdominal thrusts', 'title_ar': 'أعطِ 5 دفعات بطنية', 'body_en': 'Stand behind them, make a fist above the navel, and thrust sharply inward and upward 5 times.', 'body_ar': 'قف خلفه، ضع قبضتك فوق السرة، وادفع بقوة للداخل والأعلى 5 مرات.'},
      {'category_code': 'adult_choking', 'step_no': 4, 'title_en': 'Repeat until clear or unconscious', 'title_ar': 'كرر حتى يتحرر أو يفقد الوعي', 'body_en': 'Alternate 5 back blows and 5 thrusts. If unconscious, call 911 and start CPR.', 'body_ar': 'بادل بين 5 ضربات ظهر و5 دفعات. إذا فقد الوعي اتصل بـ 911 وابدأ الإنعاش.'},

      {'category_code': 'child_choking', 'step_no': 1, 'title_en': 'Check if child can cry or cough', 'title_ar': 'تحقق إذا كان الطفل يبكي أو يسعل', 'body_en': 'If the child cannot cry, cough or breathe, begin first aid immediately.', 'body_ar': 'إذا لم يستطع البكاء أو السعال أو التنفس، ابدأ الإسعاف فوراً.'},
      {'category_code': 'child_choking', 'step_no': 2, 'title_en': '5 back blows (child position)', 'title_ar': '5 ضربات ظهر (وضعية الطفل)', 'body_en': 'Lay child face-down on your forearm. Support head. Give 5 firm back blows.', 'body_ar': 'ضع الطفل وجهه للأسفل على ساعدك. دعم الرأس. أعطِ 5 ضربات ظهر قوية.'},
      {'category_code': 'child_choking', 'step_no': 3, 'title_en': '5 chest thrusts', 'title_ar': '5 دفعات صدرية', 'body_en': 'Turn child face-up. Give 5 chest thrusts with 2 fingers on center of chest.', 'body_ar': 'اقلب الطفل وجهه للأعلى. أعطِ 5 دفعات صدرية بإصبعين على مركز الصدر.'},
      {'category_code': 'child_choking', 'step_no': 4, 'title_en': 'Call 911 if no improvement', 'title_ar': 'اتصل بـ 911 إذا لم يتحسن', 'body_en': 'If the object does not come out after several cycles, call emergency services immediately.', 'body_ar': 'إذا لم يخرج الجسم بعد عدة دورات، اتصل بالإسعاف فوراً.'},

      {'category_code': 'asthma', 'step_no': 1, 'title_en': 'Sit them upright', 'title_ar': 'أجلسه في وضع مستقيم', 'body_en': 'Sit the person upright, leaning slightly forward. Do not lay them down.', 'body_ar': 'أجلس الشخص منتصباً مائلاً قليلاً للأمام. لا تضعه مستلقياً.'},
      {'category_code': 'asthma', 'step_no': 2, 'title_en': 'Use their inhaler', 'title_ar': 'استخدم البخاخ', 'body_en': 'Help them use their reliever inhaler (usually blue). 1 puff every 30-60 seconds, up to 10 puffs.', 'body_ar': 'ساعده على استخدام بخاخ الإغاثة (عادةً أزرق). نفخة كل 30-60 ثانية، حتى 10 نفخات.'},
      {'category_code': 'asthma', 'step_no': 3, 'title_en': 'Call 911 if no improvement', 'title_ar': 'اتصل بـ 911 إذا لم يتحسن', 'body_en': 'If no improvement after 10 minutes or breathing worsens, call 911 immediately.', 'body_ar': 'إذا لم يتحسن بعد 10 دقائق أو ساء التنفس، اتصل بـ 911 فوراً.'},

      {'category_code': 'anaphylaxis', 'step_no': 1, 'title_en': 'Use EpiPen immediately', 'title_ar': 'استخدم حقنة الأدرينالين فوراً', 'body_en': 'If available, use an epinephrine auto-injector (EpiPen) on outer thigh immediately.', 'body_ar': 'إذا كانت متوفرة، استخدم حقنة الأدرينالين على الفخذ الخارجي فوراً.'},
      {'category_code': 'anaphylaxis', 'step_no': 2, 'title_en': 'Call 911 immediately', 'title_ar': 'اتصل بـ 911 فوراً', 'body_en': 'Call emergency services immediately even if symptoms improve after EpiPen.', 'body_ar': 'اتصل بالإسعاف فوراً حتى لو تحسنت الأعراض بعد الحقنة.'},
      {'category_code': 'anaphylaxis', 'step_no': 3, 'title_en': 'Lay them down, legs raised', 'title_ar': 'أضجعه ورفع قدميه', 'body_en': 'Lay the person flat with legs raised (unless breathing is difficult). Keep warm.', 'body_ar': 'أضجع الشخص مع رفع ساقيه (إلا إذا صعب التنفس). أبقه دافئاً.'},
      {'category_code': 'anaphylaxis', 'step_no': 4, 'title_en': 'Second EpiPen if needed', 'title_ar': 'حقنة ثانية عند الحاجة', 'body_en': 'If no improvement after 5-15 minutes and a second EpiPen is available, use it.', 'body_ar': 'إذا لم يتحسن بعد 5-15 دقيقة وتوفرت حقنة ثانية، استخدمها.'},

      {'category_code': 'unconscious_breathing', 'step_no': 1, 'title_en': 'Check responsiveness', 'title_ar': 'تحقق من الاستجابة', 'body_en': 'Tap shoulders and shout "Are you okay?" If no response, call 911.', 'body_ar': 'اربت على الكتفين واصرخ "هل أنت بخير؟" إذا لم يستجب، اتصل بـ 911.'},
      {'category_code': 'unconscious_breathing', 'step_no': 2, 'title_en': 'Recovery position', 'title_ar': 'وضعية الإفاقة', 'body_en': 'Roll them on their side (recovery position) to keep airway clear and prevent choking.', 'body_ar': 'اقلبه على جانبه (وضعية الإفاقة) للحفاظ على مجرى الهواء ومنع الاختناق.'},
      {'category_code': 'unconscious_breathing', 'step_no': 3, 'title_en': 'Monitor breathing', 'title_ar': 'راقب التنفس', 'body_en': 'Keep monitoring breathing. If breathing stops, start CPR immediately.', 'body_ar': 'استمر في مراقبة التنفس. إذا توقف التنفس، ابدأ الإنعاش فوراً.'},

      {'category_code': 'not_breathing_cpr', 'step_no': 1, 'title_en': 'Call 911 now', 'title_ar': 'اتصل بـ 911 الآن', 'body_en': 'Call 911 immediately or ask someone nearby to call while you begin CPR.', 'body_ar': 'اتصل بـ 911 فوراً أو اطلب من شخص قريب الاتصال بينما تبدأ الإنعاش.'},
      {'category_code': 'not_breathing_cpr', 'step_no': 2, 'title_en': 'Position hands on chest', 'title_ar': 'ضع يديك على الصدر', 'body_en': 'Place the heel of your hand on center of chest. Place other hand on top, fingers interlaced.', 'body_ar': 'ضع راحة يدك على مركز الصدر. ضع اليد الأخرى فوقها مع تشبيك الأصابع.'},
      {'category_code': 'not_breathing_cpr', 'step_no': 3, 'title_en': '30 chest compressions', 'title_ar': '30 ضغطة على الصدر', 'body_en': 'Push down hard and fast. At least 5cm deep, 100-120 compressions per minute.', 'body_ar': 'اضغط بقوة وسرعة. عمق 5 سم على الأقل، 100-120 ضغطة في الدقيقة.'},
      {'category_code': 'not_breathing_cpr', 'step_no': 4, 'title_en': '2 rescue breaths', 'title_ar': 'نفسان إنقاذ', 'body_en': 'Tilt head back, lift chin. Pinch nose. Give 2 slow breaths, each over 1 second.', 'body_ar': 'أمل الرأس للخلف، ارفع الذقن. أغلق الأنف. أعطِ نفسين بطيئين، كل منهما لثانية واحدة.'},
      {'category_code': 'not_breathing_cpr', 'step_no': 5, 'title_en': 'Repeat 30:2 cycle', 'title_ar': 'كرر دورة 30:2', 'body_en': 'Continue cycles of 30 compressions and 2 breaths until help arrives or person recovers.', 'body_ar': 'استمر في دورات 30 ضغطة و2 نفس حتى تصل المساعدة أو يتعافى الشخص.'},
    ];

    for (final step in steps) {
      await db.insert(Tables.guidanceSteps, {
        ...step,
        'image_asset': '',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // =====================================================
  // INCIDENTS CRUD
  // =====================================================

  Future<int> insertIncident(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(Tables.incidents, {
      ...data,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    final db = await instance.database;
    return await db.query(Tables.incidents, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedIncidents() async {
    final db = await instance.database;
    return await db.query(
      Tables.incidents,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markIncidentSynced(int localId, int serverId) async {
    final db = await instance.database;
    await db.update(
      Tables.incidents,
      {
        'synced': 1,
        'server_id': serverId,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // =====================================================
  // PATIENT PROFILE CRUD
  // =====================================================

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await instance.database;
    final data = await db.query(Tables.patient);
    return data.isNotEmpty ? data.first : null;
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    await db.delete(Tables.patient);
    await db.insert(Tables.patient, {
      ...profile,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // =====================================================
  // EMERGENCY CONTACTS CRUD
  // =====================================================

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query(Tables.contacts, orderBy: 'is_primary DESC');
  }

  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert(Tables.contacts, contact);
  }

  Future<void> updateContact(int id, Map<String, dynamic> contact) async {
    final db = await instance.database;
    await db.update(
      Tables.contacts,
      contact,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteContact(int id) async {
    final db = await instance.database;
    await db.delete(Tables.contacts, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPrimaryContact(int id) async {
    final db = await instance.database;
    await db.update(Tables.contacts, {'is_primary': 0});
    await db.update(
      Tables.contacts,
      {'is_primary': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // CATEGORIES & STEPS
  // =====================================================

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query(Tables.categories);
  }

  Future<List<Map<String, dynamic>>> getStepsByCategory(String categoryCode) async {
    final db = await instance.database;
    return await db.query(
      Tables.guidanceSteps,
      where: 'category_code = ?',
      whereArgs: [categoryCode],
      orderBy: 'step_no ASC',
    );
  }

  // =====================================================
  // SETTINGS
  // =====================================================

  Future<Map<String, dynamic>> getSettings() async {
    final db = await instance.database;
    final data = await db.query(
      Tables.settings,
      where: 'id = ?',
      whereArgs: [1],
    );

    if (data.isNotEmpty) return data.first;

    return {
      'language': 'en',
      'emergency_number': '911',
      'ambulance_number': '193',
      'fire_number': '199',
      'country_code': '+962',
      'content_version': 1,
    };
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final db = await instance.database;
    await db.update(
      Tables.settings,
      settings,
      where: 'id = ?',
      whereArgs: [1],
    );
  }
  Future<int> getContentVersion() async {
    final db = await instance.database;

    final result = await db.query(
      Tables.settings,
      columns: ['content_version'],
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty) {
      final value = result.first['content_version'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 1;
    }

    return 1;
  }

  Future<void> setContentVersion(int version) async {
    final db = await instance.database;

    await db.update(
      Tables.settings,
      {'content_version': version},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // =====================================================
  // CLOSE
  // =====================================================

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}