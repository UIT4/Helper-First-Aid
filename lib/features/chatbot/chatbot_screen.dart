import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/language/app_language.dart';
import '../../core/network/sync_service.dart';
import '../categories/categories_screen.dart';
import '../result/result_screen.dart';

// =====================================================
// OFFLINE CLASSIFIER
// =====================================================

class Classifier {
  static const Map<String, Map<String, List<String>>> _keywords = {
    'adult_choking': {
      'en': [
        'choking',
        'choke',
        'stuck',
        'throat',
        'cannot breathe',
        "can't breathe",
        'turning blue',
        'heimlich',
        'airway blocked',
        'object in throat',
        'food stuck',
      ],
      'ar': [
        'اختناق',
        'يختنق',
        'عالق',
        'حلق',
        'لا يتنفس',
        'لا يستطيع التنفس',
        'ازرق',
        'انسداد',
        'شيء في الحلق',
        'طعام عالق',
        'مسدود',
      ],
    },
    'child_choking': {
      'en': [
        'baby choking',
        'infant choking',
        'child choking',
        'toddler choking',
        'kid choking',
        'swallowed',
        'baby blue',
        'infant not breathing',
      ],
      'ar': [
        'طفل يختنق',
        'رضيع يختنق',
        'ابتلع',
        'طفل صغير يختنق',
        'طفل عالق',
        'رضيع لا يتنفس',
        'طفل ازرق',
      ],
    },
    'asthma': {
      'en': [
        'asthma',
        'inhaler',
        'wheezing',
        'breathing difficulty',
        'short of breath',
        'tight chest',
        "can't breathe properly",
        'chest tight',
        'wheeze',
        'no inhaler',
      ],
      'ar': [
        'ربو',
        'بخاخ',
        'صفير',
        'ضيق تنفس',
        'صعوبة التنفس',
        'صدر ضيق',
        'لا يتنفس بشكل صحيح',
        'أزمة ربو',
        'نوبة ربو',
      ],
    },
    'anaphylaxis': {
      'en': [
        'allergy',
        'allergic reaction',
        'anaphylaxis',
        'epipen',
        'swollen throat',
        'hives',
        'bee sting',
        'food allergy',
        'swollen face',
        'rash all over',
        'severe reaction',
      ],
      'ar': [
        'حساسية',
        'رد فعل تحسسي',
        'صدمة تأقية',
        'تورم الحلق',
        'طفح',
        'لسعة نحلة',
        'حساسية طعام',
        'تورم الوجه',
        'طفح جلدي',
        'حساسية شديدة',
      ],
    },
    'unconscious_breathing': {
      'en': [
        'unconscious',
        'unresponsive',
        'passed out',
        'fainted',
        'not waking',
        'breathing but unconscious',
        'collapsed',
        'won\'t wake up',
        'eyes rolled',
      ],
      'ar': [
        'فاقد الوعي',
        'لا يستجيب',
        'أغمي عليه',
        'إغماء',
        'لا يصحى',
        'يتنفس لكن فاقد الوعي',
        'انهار',
        'سقط مغشياً',
      ],
    },
    'not_breathing_cpr': {
      'en': [
        'not breathing',
        'no pulse',
        'heart stopped',
        'cardiac arrest',
        'cpr',
        'resuscitation',
        'no heartbeat',
        'heart attack',
        'no breathing at all',
        'stopped breathing',
      ],
      'ar': [
        'لا يتنفس',
        'لا نبض',
        'قلب توقف',
        'سكتة قلبية',
        'إنعاش',
        'انعاش قلبي',
        'لا دقات قلب',
        'أزمة قلبية',
        'نوبة قلبية',
        'توقف التنفس',
      ],
    },
    'bleeding': {
      'en': [
        'bleeding',
        'blood',
        'cut',
        'wound',
        'hemorrhage',
        'won\'t stop bleeding',
        'deep cut',
        'gash',
        'stabbed',
        'laceration',
      ],
      'ar': [
        'نزيف',
        'دم',
        'جرح',
        'قطع',
        'لا يتوقف النزيف',
        'جرح عميق',
        'طعنة',
        'دم كثير',
      ],
    },
    'burns': {
      'en': [
        'burn',
        'burned',
        'fire',
        'scalded',
        'hot water burn',
        'chemical burn',
        'skin burned',
        'blister',
      ],
      'ar': [
        'حرق',
        'محروق',
        'نار',
        'ماء ساخن',
        'حرق كيميائي',
        'بثور',
        'جلد محروق',
      ],
    },
    'fracture': {
      'en': [
        'broken bone',
        'fracture',
        'broken arm',
        'broken leg',
        'broken wrist',
        'bone sticking out',
        'cannot move arm',
        'snapped',
        'deformed limb',
      ],
      'ar': [
        'كسر',
        'عظمة مكسورة',
        'ذراع مكسور',
        'ساق مكسورة',
        'لا يستطيع تحريك يده',
        'عظمة بارزة',
      ],
    },
    'seizure': {
      'en': [
        'seizure',
        'convulsion',
        'epilepsy',
        'shaking uncontrollably',
        'fits',
        'twitching',
        'epileptic',
        'falling shaking',
      ],
      'ar': [
        'نوبة',
        'تشنج',
        'صرع',
        'اهتزاز لا إرادي',
        'نوبة صرع',
        'تشنجات',
        'يرتجف',
      ],
    },
    'stroke': {
      'en': [
        'stroke',
        'face drooping',
        'arm weakness',
        'speech slurred',
        'sudden confusion',
        'fast stroke',
        'brain attack',
        'one side weak',
        'facial drooping',
      ],
      'ar': [
        'سكتة دماغية',
        'وجه مائل',
        'ضعف ذراع',
        'كلام غير واضح',
        'ارتباك مفاجئ',
        'جلطة دماغية',
        'جانب ضعيف',
      ],
    },
  };

  static const Map<String, List<String>> _childMarkers = {
    'en': [
      'baby',
      'infant',
      'child',
      'toddler',
      'kid',
      'boy',
      'girl',
      'son',
      'daughter',
      'years old',
      'months old',
    ],
    'ar': [
      'طفل',
      'رضيع',
      'بيبي',
      'ولد',
      'بنت',
      'ابن',
      'ابنة',
      'سنوات',
      'شهر',
      'طفلة',
    ],
  };

  static Map<String, dynamic> predict(String text, {String? forcedLang}) {
    final lang = forcedLang ?? _detectLang(text);
    final t = text.toLowerCase().trim();
    final hits = <String, int>{};

    for (final cat in _keywords.keys) {
      hits[cat] = 0;
      final kws = _keywords[cat]![lang] ?? [];
      for (final kw in kws) {
        if (t.contains(kw)) {
          hits[cat] = hits[cat]! + 1;
        }
      }
    }

    if ((hits['adult_choking'] ?? 0) > 0 ||
        (hits['child_choking'] ?? 0) > 0) {
      final childKws = _childMarkers[lang] ?? [];
      for (final kw in childKws) {
        if (t.contains(kw)) {
          hits['child_choking'] = (hits['child_choking'] ?? 0) + 2;
          break;
        }
      }
    }

    final totalHits = hits.values.fold(0, (a, b) => a + b);

    if (totalHits == 0) {
      return {
        'category': 'unknown',
        'confidence': 0.0,
        'urgency': 'unknown',
        'lang': lang,
      };
    }

    final topCat = hits.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final topHits = hits[topCat]!;

    if (topHits < 1) {
      return {
        'category': 'unknown',
        'confidence': 0.0,
        'urgency': 'unknown',
        'lang': lang,
      };
    }

    final confidence = (topHits / totalHits).clamp(0.0, 1.0);

    if (confidence < 0.30) {
      return {
        'category': 'unknown',
        'confidence': confidence,
        'urgency': 'unknown',
        'lang': lang,
      };
    }

    final urgency = _urgencyFor(topCat);

    return {
      'category': topCat,
      'confidence': confidence,
      'urgency': urgency,
      'lang': lang,
    };
  }

  static String _urgencyFor(String cat) {
    const high = [
      'not_breathing_cpr',
      'adult_choking',
      'child_choking',
      'anaphylaxis',
      'stroke',
      'seizure',
    ];

    const med = [
      'asthma',
      'unconscious_breathing',
      'bleeding',
      'burns',
    ];

    if (high.contains(cat)) return 'high';
    if (med.contains(cat)) return 'med';
    return 'low';
  }

  static String _detectLang(String text) {
    final arabicChars = RegExp(r'[\u0600-\u06FF]');
    return arabicChars.allMatches(text).length > 2 ? 'ar' : 'en';
  }
}

// =====================================================
// N8N SERVICE
// =====================================================

class N8nChatService {
  static const String webhookUrl =
      'http://10.0.2.2:5678/webhook/rescue-chat';

  static Future<Map<String, dynamic>?> ask({
    required String text,
    required String lang,
    required bool isGuest,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': text,
          'lang': lang,
          'is_guest': isGuest,
          'source': 'flutter_app',
        }),
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

// =====================================================
// CHATBOT SCREEN
// =====================================================

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'bot',
      'text':
      'Hello! I\'m your Rescue Assistant 🚑\n\nDescribe the emergency in English or Arabic — I\'ll guide you immediately.\n\nمرحباً! صف الحالة الطارئة بالعربي أو الإنجليزي.',
      'type': 'text',
    }
  ];

  bool _isTyping = false;
  bool _langIsAr = false;
  bool _isLoading = false;
  String _selectedLang = 'auto';
  bool isGuest = false;
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, String>> _suggestions = [
    {'en': 'Choking adult', 'ar': 'اختناق بالغ'},
    {'en': 'Baby choking', 'ar': 'اختناق طفل'},
    {'en': 'Not breathing', 'ar': 'لا يتنفس'},
    {'en': 'Severe allergy', 'ar': 'حساسية شديدة'},
    {'en': 'Unconscious', 'ar': 'فاقد الوعي'},
    {'en': 'Asthma attack', 'ar': 'نوبة ربو'},
    {'en': 'Heavy bleeding', 'ar': 'نزيف شديد'},
    {'en': 'Seizure / convulsion', 'ar': 'تشنج / نوبة'},
    {'en': 'Stroke symptoms', 'ar': 'أعراض سكتة'},
    {'en': 'Burn injury', 'ar': 'حرق'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGuestStatus();
    _loadAppLanguage();
  }

  Future<void> _loadGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      isGuest = prefs.getBool('isGuest') ?? false;
    });
  }

  Future<void> _loadAppLanguage() async {
    final lang = await AppLanguage.getLanguage();

    if (!mounted) return;

    setState(() {
      _selectedLang = lang == 'ar' || lang == 'en' ? lang : 'auto';
      _langIsAr = lang == 'ar';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? id = prefs.getString('device_id');

    if (id == null) {
      final random = Random();
      id = '${DateTime.now().millisecondsSinceEpoch}${random.nextInt(999999)}';
      await prefs.setString('device_id', id);
    }

    return id;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 320), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showLanguageMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLanguage.text(context, 'Select Language', 'اختر اللغة'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _langOption(
              'auto',
              '',
              _langIsAr ? 'تلقائي' : 'Auto Detect',
              _langIsAr ? 'كشف اللغة تلقائياً' : 'Detect language automatically',
            ),
            _langOption(
              'en',
              '',
              _langIsAr ? 'الإنجليزية' : 'English',
              _langIsAr ? 'لغة إنجليزية' : 'English Language',
            ),
            _langOption(
              'ar',
              '',
              _langIsAr ? 'العربية' : 'Arabic',
              _langIsAr ? 'لغة عربية' : 'Arabic Language',
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    final langToSave = selected == 'auto' ? 'en' : selected;
    await AppLanguage.setLanguage(langToSave);

    if (!mounted) return;

    setState(() {
      _selectedLang = selected;
      if (selected == 'ar') _langIsAr = true;
      if (selected == 'en') _langIsAr = false;
      if (selected == 'auto') {
        _langIsAr = AppLanguage.isArabicContext(context);
      }
    });
  }

  Widget _langOption(String val, String flag, String label, String sub) {
    final selected = _selectedLang == val;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.primary : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(context, val),
    );
  }

  Future<Position?> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () async =>
        (await Geolocator.getLastKnownPosition()) ??
            Future.error('timeout'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null || !mounted) return;

      setState(() {
        _messages.add({
          'sender': 'user',
          'type': 'image',
          'imagePath': photo.path,
        });
        _isTyping = true;
      });

      _scrollToBottom();

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      setState(() {
        _isTyping = false;
        _messages.add({
          'sender': 'bot',
          'type': 'text',
          'text': _langIsAr
              ? '📷 تم استلام الصورة.\nلتحليل الصور يجب الاتصال بالإنترنت.\nهل تريد وصف الحالة كتابياً؟'
              : '📷 Photo received.\nImage analysis requires internet.\nPlease describe the situation in text.',
        });
      });

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      _showSnackbar(
        AppLanguage.text(context, 'Could not open camera', 'تعذر فتح الكاميرا'),
        isError: true,
      );
    }
  }

  Future<void> _handleSend([String? presetText]) async {
    if (_isLoading) return;

    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    _controller.clear();
    _focusNode.unfocus();

    HapticFeedback.lightImpact();

    try {
      setState(() {
        _messages.add({
          'sender': 'user',
          'text': text,
          'type': 'text',
        });
        _isTyping = true;
      });

      _scrollToBottom();

      final selectedLang = _selectedLang == 'auto' ? 'auto' : _selectedLang;

      final n8nResponse = await N8nChatService.ask(
        text: text,
        lang: selectedLang,
        isGuest: isGuest,
      );

      Map<String, dynamic> result;
      String botReply;
      bool usedN8n = false;

      if (n8nResponse != null) {
        usedN8n = true;

        final detectedLang = (n8nResponse['lang'] ??
            n8nResponse['language'] ??
            '')
            .toString();

        final category = (n8nResponse['category'] ??
            n8nResponse['predicted_category_code'] ??
            n8nResponse['case'] ??
            'unknown')
            .toString();

        final confidenceRaw =
            n8nResponse['confidence'] ?? n8nResponse['score'] ?? 0.0;

        final confidence = confidenceRaw is num
            ? confidenceRaw.toDouble()
            : double.tryParse(confidenceRaw.toString()) ?? 0.0;

        final urgency = (n8nResponse['urgency'] ??
            n8nResponse['priority'] ??
            'unknown')
            .toString();

        final reply = (n8nResponse['reply'] ??
            n8nResponse['answer'] ??
            n8nResponse['message'] ??
            n8nResponse['text'] ??
            '')
            .toString();

        final offlineLang = Classifier.predict(
          text,
          forcedLang: _selectedLang == 'auto' ? null : _selectedLang,
        )['lang'];

        result = {
          'category': category.isEmpty ? 'unknown' : category,
          'confidence': confidence.clamp(0.0, 1.0),
          'urgency': urgency.isEmpty ? 'unknown' : urgency,
          'lang': detectedLang == 'ar' || detectedLang == 'en'
              ? detectedLang
              : offlineLang,
        };

        botReply = reply.trim().isNotEmpty
            ? reply
            : result['lang'] == 'ar'
            ? 'تم تحليل الحالة من المساعد الذكي.'
            : 'The case was analyzed by the smart assistant.';
      } else {
        result = Classifier.predict(
          text,
          forcedLang: _selectedLang == 'auto' ? null : _selectedLang,
        );

        botReply = result['category'] == 'unknown'
            ? result['lang'] == 'ar'
            ? '🤔 لم أتمكن من تحديد الحالة بدقة.\n\nيرجى:\n• وصف الحالة بمزيد من التفاصيل\n• أو اختر التصنيف يدوياً من الزر أدناه'
            : '🤔 I couldn\'t identify the exact situation.\n\nPlease:\n• Describe in more detail\n• Or choose a category manually below'
            : result['lang'] == 'ar'
            ? 'تم تحليل الحالة بدون اتصال بالسيرفر.'
            : 'The case was analyzed offline.';
      }

      final category = result['category'] as String;
      final confidence = result['confidence'] as double;
      final urgency = result['urgency'] as String;
      final lang = result['lang'] as String;

      if (mounted) {
        setState(() => _langIsAr = lang == 'ar');
      }

      final deviceId = await getDeviceId();
      final position = await _getLocation();

      await AppDatabase.instance.insertIncident({
        'device_id': deviceId,
        'lang': lang,
        'input_text': text,
        'predicted_category_code': category,
        'confidence': confidence,
        'urgency': urgency,
        'lat': position?.latitude ?? 0.0,
        'lng': position?.longitude ?? 0.0,
        'location_source': position != null ? 'gps_or_last_known' : 'none',
        'notes': usedN8n ? 'source:n8n' : 'source:offline_classifier',
      });

      await SyncService.syncIncidents();

      if (!mounted) return;

      setState(() {
        _isTyping = false;

        if (category == 'unknown') {
          _messages.add({
            'sender': 'bot',
            'type': 'unknown',
            'text': botReply,
            'lang': lang,
          });
        } else {
          _messages.add({
            'sender': 'bot',
            'type': 'text',
            'text': botReply,
          });
        }
      });

      _scrollToBottom();

      if (category != 'unknown' && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              category: category,
              confidence: confidence,
              urgency: urgency,
              lang: lang,
              userText: text,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showSnackbar(
        e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callEmergency() async {
    final settings = await AppDatabase.instance.getSettings();
    final number = settings['emergency_number'] ?? '911';
    final url = Uri(scheme: 'tel', path: number);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }

    if (!mounted) return;

    _showSnackbar(
      AppLanguage.text(context, 'Cannot open dialer', 'تعذر فتح الاتصال'),
      isError: true,
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.isArabicContext(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }

                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';

                  if (msg['type'] == 'unknown') {
                    return _buildUnknownCard(msg);
                  }

                  if (msg['type'] == 'image') {
                    return _buildImageBubble(msg['imagePath'] ?? '', isUser);
                  }

                  return _buildBubble(msg['text'] ?? '', isUser);
                },
              ),
            ),
            if (!_isTyping && _messages.length < 4) _buildSuggestionChips(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  String _currentLanguageLabel() {
    if (_selectedLang == 'ar') return '🇯🇴 العربية';
    if (_selectedLang == 'en') return '🇬🇧 English';
    return AppLanguage.text(context, '🌐 Auto', '🌐 تلقائي');
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        children: [
          Text(
            isGuest
                ? AppLanguage.text(
              context,
              'Rescue Assistant (Guest)',
              'مساعد الإسعاف (ضيف)',
            )
                : AppLanguage.text(
              context,
              'Rescue Assistant',
              'مساعد الإسعاف',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            _currentLanguageLabel(),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.language,
            color: Colors.white,
          ),
          onPressed: _showLanguageMenu,
        ),
        IconButton(
          icon: const Icon(
            Icons.call,
            color: Colors.white,
          ),
          onPressed: _callEmergency,
        ),
      ],
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              AppLanguage.text(
                context,
                'Tap a situation or type:',
                'اختر أو اكتب الحالة:',
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (_, i) {
                final label =
                _langIsAr ? _suggestions[i]['ar']! : _suggestions[i]['en']!;

                return GestureDetector(
                  onTap: () => _handleSend(label),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF0F172A),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildImageBubble(String path, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(path), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypingDot(delay: 0),
            SizedBox(width: 4),
            _TypingDot(delay: 200),
            SizedBox(width: 4),
            _TypingDot(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownCard(Map<String, dynamic> msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Color(0xFFF97316),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLanguage.text(
                    context,
                    'Situation not identified',
                    'لم أتعرف على الحالة',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            msg['text'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoriesScreen(),
                ),
              ),
              icon: const Icon(
                Icons.category,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                AppLanguage.text(
                  context,
                  'Choose Category Manually',
                  'اختر التصنيف يدوياً',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: _pickFromCamera,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                textDirection: _langIsAr ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: AppLanguage.text(
                    context,
                    'Describe the emergency...',
                    'صف الحالة الطارئة...',
                  ),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _isLoading ? null : _handleSend,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// TYPING DOT ANIMATION
// =====================================================

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}