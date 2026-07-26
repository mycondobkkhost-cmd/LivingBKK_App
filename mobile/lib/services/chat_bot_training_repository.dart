import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_bot_logic_settings.dart';
import '../models/chat_learned_answer.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// Admin — เทรนบอท AI: FAQ · learned memory · logic settings
class ChatBotTrainingRepository {
  ChatBotTrainingRepository._();
  static final ChatBotTrainingRepository instance =
      ChatBotTrainingRepository._();

  static const _faqPrefsKey = 'chat_bot_training_faq_v1';
  static const _learnedPrefsKey = 'chat_bot_training_learned_v1';
  static const _logicPrefsKey = 'chat_bot_training_logic_v1';

  bool get _live =>
      SupabaseService.isReady && !AuthService.instance.trialSimulatesBackend;

  // ── FAQ ──

  Future<List<Map<String, dynamic>>> listFaqRules() async {
    if (_live) {
      try {
        final data = await SupabaseService.client!
            .from('chat_faq_rules')
            .select('id, scope, patterns, reply_text, priority, is_active')
            .order('priority', ascending: true);
        return List<Map<String, dynamic>>.from(data as List);
      } catch (e) {
        debugPrint('listFaqRules: $e');
      }
    }
    return _loadFaqFromPrefs();
  }

  Future<void> updateFaqRule(
    String id, {
    String? replyText,
    List<String>? patterns,
    int? priority,
    bool? isActive,
  }) async {
    final patch = <String, dynamic>{};
    if (replyText != null) patch['reply_text'] = replyText;
    if (patterns != null) patch['patterns'] = patterns;
    if (priority != null) patch['priority'] = priority;
    if (isActive != null) patch['is_active'] = isActive;
    if (patch.isEmpty) return;

    if (_live) {
      await SupabaseService.client!
          .from('chat_faq_rules')
          .update(patch)
          .eq('id', id);
      return;
    }
    final rules = await _loadFaqFromPrefs();
    final i = rules.indexWhere((r) => r['id'] == id);
    if (i < 0) return;
    rules[i] = {...rules[i], ...patch};
    await _saveFaqToPrefs(rules);
  }

  Future<Map<String, dynamic>?> createFaqRule({
    required String scope,
    required List<String> patterns,
    required String replyText,
    int priority = 100,
  }) async {
    if (_live) {
      final row = await SupabaseService.client!
          .from('chat_faq_rules')
          .insert({
            'scope': scope,
            'patterns': patterns,
            'reply_text': replyText,
            'priority': priority,
          })
          .select('id, scope, patterns, reply_text, priority, is_active')
          .single();
      return Map<String, dynamic>.from(row as Map);
    }
    final rules = await _loadFaqFromPrefs();
    final id = 'demo-faq-${DateTime.now().millisecondsSinceEpoch}';
    final rule = {
      'id': id,
      'scope': scope,
      'patterns': patterns,
      'reply_text': replyText,
      'priority': priority,
      'is_active': true,
    };
    rules.add(rule);
    await _saveFaqToPrefs(rules);
    return rule;
  }

  Future<List<Map<String, dynamic>>> _loadFaqFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_faqPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }
    final demo = _demoFaqRules();
    await _saveFaqToPrefs(demo);
    return demo;
  }

  Future<void> _saveFaqToPrefs(List<Map<String, dynamic>> rules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_faqPrefsKey, jsonEncode(rules));
  }

  List<Map<String, dynamic>> _demoFaqRules() => [
        {
          'id': 'demo-faq-1',
          'scope': 'global',
          'patterns': ['ค่าส่วนกลาง', 'common fee', 'cam fee'],
          'reply_text':
              'ราคาที่แสดงเป็นราคา Net สำหรับผู้เช่า/ผู้ซื้อแล้วค่ะ เจ้าหน้าที่จะยืนยันรายละเอียดเพิ่มเมื่อติดต่อกลับ',
          'priority': 10,
          'is_active': true,
        },
        {
          'id': 'demo-faq-2',
          'scope': 'global',
          'patterns': ['net', 'เน็ต', 'รวมค่า'],
          'reply_text':
              'ราคาบนแพลตฟอร์มเป็นราคา Net ที่ผู้เช่า/ผู้ซื้อเห็นแล้วค่ะ',
          'priority': 15,
          'is_active': true,
        },
        {
          'id': 'demo-faq-3',
          'scope': 'property',
          'patterns': ['ราคา', 'เท่าไร', 'เท่าไหร่', 'กี่บาท'],
          'reply_text':
              'ราคาที่แสดงเป็นราคา Net สำหรับทรัพย์นี้แล้วค่ะ หากต้องการรายละเอียดครบถ้วน เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
          'priority': 20,
          'is_active': true,
        },
        {
          'id': 'demo-faq-4',
          'scope': 'property',
          'patterns': ['สัตว', 'เลี้ยง', 'pet'],
          'reply_text':
              'เงื่อนไขสัตว์เลี้ยงขึ้นกับแต่ละห้องค่ะ เจ้าหน้าที่จะยืนยันให้เมื่อติดต่อกลับ',
          'priority': 25,
          'is_active': true,
        },
        {
          'id': 'demo-faq-5',
          'scope': 'global',
          'patterns': ['ลงประกาศฟรี', 'โพสต์ฟรี', 'post property'],
          'reply_text':
              'การลงประกาศบน RealXtate ไม่มีค่าใช้จ่ายเบื้องต้นค่ะ เก็บ Success Fee เมื่อปิดดีลสำเร็จเท่านั้น',
          'priority': 80,
          'is_active': true,
        },
      ];

  // ── Learned answers ──

  Future<List<ChatLearnedAnswer>> listLearnedAnswers() async {
    if (_live) {
      try {
        final data = await SupabaseService.client!
            .from('chat_learned_answers')
            .select()
            .order('updated_at', ascending: false)
            .limit(200);
        return (data as List)
            .whereType<Map>()
            .map((e) => ChatLearnedAnswer.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      } catch (e) {
        debugPrint('listLearnedAnswers: $e');
      }
    }
    return _loadLearnedFromPrefs();
  }

  Future<void> upsertLearnedAnswer(ChatLearnedAnswer answer) async {
    if (_live && !answer.id.startsWith('demo-')) {
      await SupabaseService.client!.from('chat_learned_answers').upsert({
        if (answer.id.isNotEmpty && !answer.id.startsWith('demo-'))
          'id': answer.id,
        'topic_key': answer.topicKey,
        'question_example': answer.questionExample,
        'answer_guidance': answer.answerGuidance,
        'scope': answer.scope,
        if (answer.propertyType != null) 'property_type': answer.propertyType,
        if (answer.listingId != null) 'listing_id': answer.listingId,
        'is_active': answer.isActive,
        'created_by': AuthService.instance.effectiveUserId,
      });
      return;
    }
    final list = await _loadLearnedFromPrefs();
    final i = list.indexWhere((a) => a.id == answer.id);
    if (i >= 0) {
      list[i] = answer;
    } else {
      list.insert(0, answer);
    }
    await _saveLearnedToPrefs(list);
  }

  Future<void> setLearnedActive(String id, bool active) async {
    if (_live && !id.startsWith('demo-')) {
      await SupabaseService.client!
          .from('chat_learned_answers')
          .update({'is_active': active}).eq('id', id);
      return;
    }
    final list = await _loadLearnedFromPrefs();
    final i = list.indexWhere((a) => a.id == id);
    if (i < 0) return;
    list[i] = list[i].copyWith(isActive: active);
    await _saveLearnedToPrefs(list);
  }

  Future<ChatLearnedAnswer> createLearnedAnswer({
    required String topicKey,
    required String questionExample,
    required String answerGuidance,
    String scope = 'global',
    String? propertyType,
  }) async {
    final answer = ChatLearnedAnswer(
      id: 'demo-learned-${DateTime.now().millisecondsSinceEpoch}',
      topicKey: topicKey,
      questionExample: questionExample,
      answerGuidance: answerGuidance,
      scope: scope,
      propertyType: propertyType,
    );
    await upsertLearnedAnswer(answer);
    return answer;
  }

  Future<List<ChatLearnedAnswer>> _loadLearnedFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_learnedPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => ChatLearnedAnswer.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        }
      } catch (_) {}
    }
    final demo = _demoLearned();
    await _saveLearnedToPrefs(demo);
    return demo;
  }

  Future<void> _saveLearnedToPrefs(List<ChatLearnedAnswer> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _learnedPrefsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  List<ChatLearnedAnswer> _demoLearned() => [
        ChatLearnedAnswer(
          id: 'demo-learned-1',
          topicKey: 'viewing_today',
          questionExample: 'อยากนัดดูวันนี้ 6 โมงได้ไหม',
          answerGuidance:
              'ยืนยันความสนใจ ชวนส่งฟอร์มนัดดูหรือให้แอดมินประสานเจ้าของ — ไม่สัญญาเวลาเอง',
          scope: 'global',
          useCount: 3,
        ),
        ChatLearnedAnswer(
          id: 'demo-learned-2',
          topicKey: 'pet_condo',
          questionExample: 'เลี้ยงแมว 2 ตัวได้ไหม',
          answerGuidance:
              'บอกว่าเงื่อนไขสัตว์เลี้ยงขึ้นกับแต่ละห้อง แอดมินจะถามเจ้าของให้',
          scope: 'property_type',
          propertyType: 'condo',
          useCount: 1,
        ),
      ];

  // ── Logic settings ──

  Future<ChatBotLogicSettings> loadLogicSettings() async {
    if (_live) {
      try {
        final row = await SupabaseService.client!
            .from('chat_bot_training_settings')
            .select('settings')
            .eq('id', 'default')
            .maybeSingle();
        if (row != null && row['settings'] is Map) {
          return ChatBotLogicSettings.fromJson(
            Map<String, dynamic>.from(row['settings'] as Map),
          );
        }
      } catch (e) {
        debugPrint('loadLogicSettings: $e');
      }
    }
    return _loadLogicFromPrefs();
  }

  Future<void> saveLogicSettings(ChatBotLogicSettings settings) async {
    if (_live) {
      await SupabaseService.client!.from('chat_bot_training_settings').upsert({
        'id': 'default',
        'settings': settings.toJson(),
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logicPrefsKey, jsonEncode(settings.toJson()));
  }

  Future<ChatBotLogicSettings> _loadLogicFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logicPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return ChatBotLogicSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }
    return ChatBotLogicSettings.defaults();
  }
}
