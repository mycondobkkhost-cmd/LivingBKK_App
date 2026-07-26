import 'package:flutter/foundation.dart';

import '../models/chat_bot_logic_settings.dart';
import '../models/chat_bot_sandbox_message.dart';
import '../models/chat_learned_answer.dart';
import 'chat_bot_training_repository.dart';

/// จำลองบอทในแชทเดียว — สลับบทบาทลูกค้า/โค้ช · ผ่าน-ไม่ผ่าน · บันทึก FAQ/ความจำทันที
class ChatBotTrainingSandboxService extends ChangeNotifier {
  ChatBotTrainingSandboxService({ChatBotTrainingRepository? repo})
      : _repo = repo ?? ChatBotTrainingRepository.instance;

  final ChatBotTrainingRepository _repo;

  final List<ChatBotSandboxMessage> messages = [];
  ChatBotSandboxRole role = ChatBotSandboxRole.customer;
  ChatBotSandboxPersona customerPersona = ChatBotSandboxPersona.seeker;
  bool loading = false;

  List<Map<String, dynamic>> _faq = [];
  List<ChatLearnedAnswer> _learned = [];
  ChatBotLogicSettings _logic = ChatBotLogicSettings.defaults();

  Future<void> init({bool isEnglish = false}) async {
    loading = true;
    notifyListeners();
    _faq = await _repo.listFaqRules();
    _learned = await _repo.listLearnedAnswers();
    _logic = await _repo.loadLogicSettings();
    messages.clear();
    _welcome(isEnglish);
    loading = false;
    notifyListeners();
  }

  void setRole(ChatBotSandboxRole next) {
    if (role == next) return;
    role = next;
    notifyListeners();
  }

  void setCustomerPersona(ChatBotSandboxPersona next) {
    if (customerPersona == next) return;
    customerPersona = next;
    notifyListeners();
  }

  static String personaLabel(ChatBotSandboxPersona p, {required bool isEnglish}) {
    switch (p) {
      case ChatBotSandboxPersona.seeker:
        return isEnglish ? 'Seeker' : 'ผู้หาห้อง';
      case ChatBotSandboxPersona.coAgent:
        return isEnglish ? 'Co-agent' : 'โคเอเจนต์';
      case ChatBotSandboxPersona.owner:
        return isEnglish ? 'Owner' : 'เจ้าของทรัพย์';
    }
  }

  static String personaSampleQuestion(ChatBotSandboxPersona p) {
    switch (p) {
      case ChatBotSandboxPersona.seeker:
        return 'ค่าเช่ารวมส่วนกลางไหมคะ';
      case ChatBotSandboxPersona.coAgent:
        return 'พาลูกค้าดูห้องนี้ได้ไหม ค่าคอมเท่าไร';
      case ChatBotSandboxPersona.owner:
        return 'ลงประกาศฟรีจริงไหม เก็บ success fee ยังไง';
    }
  }

  void reset({bool isEnglish = false}) {
    messages.clear();
    _welcome(isEnglish);
    notifyListeners();
  }

  Future<void> reloadTrainingData() async {
    _faq = await _repo.listFaqRules();
    _learned = await _repo.listLearnedAnswers();
    _logic = await _repo.loadLogicSettings();
    notifyListeners();
  }

  Future<void> send(String text, {required bool isEnglish}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (role == ChatBotSandboxRole.customer) {
      final persona = customerPersona;
      _push(
        ChatBotSandboxMessage(
          id: _id(),
          kind: ChatBotSandboxMessageKind.customer,
          text: trimmed,
          at: DateTime.now(),
          persona: persona,
        ),
      );
      final bot = _simulateBot(
        trimmed,
        persona: persona,
        isEnglish: isEnglish,
      );
      _push(
        ChatBotSandboxMessage(
          id: _id(),
          kind: ChatBotSandboxMessageKind.bot,
          text: bot.text,
          at: DateTime.now(),
          source: bot.source,
          sourceLabel: bot.sourceLabel,
          customerQuestion: trimmed,
        ),
      );
      notifyListeners();
      return;
    }

    await _handleCoach(trimmed, isEnglish: isEnglish);
    notifyListeners();
  }

  Future<void> reviewBot({
    required String botMessageId,
    required bool passed,
    String? suggestedReply,
    required bool isEnglish,
  }) async {
    final i = messages.indexWhere((m) => m.id == botMessageId);
    if (i < 0 || messages[i].kind != ChatBotSandboxMessageKind.bot) return;

    if (passed) {
      messages[i] = messages[i].copyWith(reviewPassed: true);
      _pushSystem(
        isEnglish
            ? 'Marked pass — bot reply kept as reference.'
            : 'บันทึกว่า「ผ่าน」 — เก็บคำตอบนี้เป็นตัวอย่างที่ดี',
      );
      notifyListeners();
      return;
    }

    if (suggestedReply == null || suggestedReply.trim().isEmpty) {
      setRole(ChatBotSandboxRole.coach);
      _pushSystem(
        isEnglish
            ? 'Not passed — switch to Coach and type e.g. 「ควรตอบ: …」'
            : 'ไม่ผ่าน — สลับเป็นโค้ชแล้วพิมพ์ เช่น 「ควรตอบ: …」',
      );
      notifyListeners();
      return;
    }

    await _applyTrainingFromQuestion(
      question: messages[i].customerQuestion ?? _lastCustomerText() ?? '',
      suggestedReply: suggestedReply.trim(),
      isEnglish: isEnglish,
      replaceBotMessageId: botMessageId,
    );
    notifyListeners();
  }

  void _welcome(bool isEnglish) {
    _pushSystem(
      isEnglish
          ? '① Pick customer type (seeker / co-agent / owner) → type a question → bot replies.\n'
              '② Tap Pass/Fail under the bot bubble (no need to switch to Coach).\n'
              '③ Or switch to Coach → type 「pass」, 「fail」, or 「should reply: …」 to save FAQ.'
          : '① เลือกประเภทลูกค้า (ผู้หาห้อง / โคเอเจนต์ / เจ้าของ) → พิมถาม → บอทตอบ\n'
              '② กด「ผ่าน/ไม่ผ่าน」ใต้ฟองบอทได้เลย (ไม่ต้องสลับโค้ช)\n'
              '③ หรือสลับ「โค้ช」→ พิมพ์ 「ผ่าน」「ไม่ผ่าน」「ควรตอบ: …」เพื่อบันทึก FAQ',
    );
  }

  Future<void> _handleCoach(String text, {required bool isEnglish}) async {
    _push(
      ChatBotSandboxMessage(
        id: _id(),
        kind: ChatBotSandboxMessageKind.coach,
        text: text,
        at: DateTime.now(),
      ),
    );

    final lower = text.toLowerCase().trim();

    if (RegExp(r'^(ผ่าน|pass|ok|โอเค|👍|✅)$', caseSensitive: false)
        .hasMatch(lower)) {
      final lastBot = _lastBotMessage();
      if (lastBot == null) {
        _pushSystem(isEnglish ? 'No bot reply to review yet.' : 'ยังไม่มีคำตอบบอทให้ประเมิน');
        return;
      }
      await reviewBot(
        botMessageId: lastBot.id,
        passed: true,
        isEnglish: isEnglish,
      );
      return;
    }

    if (RegExp(r'^(ไม่ผ่าน|fail|❌)', caseSensitive: false).hasMatch(lower)) {
      final rest = text.replaceFirst(
        RegExp(r'^(ไม่ผ่าน|fail|❌)\s*', caseSensitive: false),
        '',
      );
      final lastBot = _lastBotMessage();
      if (lastBot == null) {
        _pushSystem(isEnglish ? 'No bot reply to review yet.' : 'ยังไม่มีคำตอบบอทให้ประเมิน');
        return;
      }
      if (rest.trim().isNotEmpty) {
        await reviewBot(
          botMessageId: lastBot.id,
          passed: false,
          suggestedReply: rest.trim(),
          isEnglish: isEnglish,
        );
        return;
      }
      await reviewBot(
        botMessageId: lastBot.id,
        passed: false,
        isEnglish: isEnglish,
      );
      return;
    }

    if (RegExp(r'^(ล้าง|reset|เริ่มใหม่)$', caseSensitive: false).hasMatch(lower)) {
      reset(isEnglish: isEnglish);
      return;
    }

    final suggest = RegExp(
      r'^(ควรตอบ|แก้เป็น|ตอบว่า|ตอบแบบนี้|should reply|fix to)[：:\s]+(.+)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(text);
    if (suggest != null) {
      final reply = suggest.group(2)!.trim();
      final question = _lastCustomerText() ?? '';
      if (question.isEmpty) {
        _pushSystem(
          isEnglish
              ? 'Send a customer message first.'
              : 'พิมพ์ในบทลูกค้าก่อน แล้วค่อยสั่งแก้คำตอบ',
        );
        return;
      }
      await _applyTrainingFromQuestion(
        question: question,
        suggestedReply: reply,
        isEnglish: isEnglish,
        replaceBotMessageId: _lastBotMessage()?.id,
      );
      return;
    }

    if (RegExp(r'^(โทน|voice)[：:\s]+', caseSensitive: false).hasMatch(text)) {
      final rule = text.replaceFirst(
        RegExp(r'^(โทน|voice)[：:\s]+', caseSensitive: false),
        '',
      );
      await _appendVoiceRule(rule.trim(), isEnglish: isEnglish);
      return;
    }

    final lastBot = _lastBotMessage();
    final lastQ = _lastCustomerText();
    if (lastBot != null &&
        lastBot.reviewPassed == null &&
        lastQ != null &&
        text.length >= 6) {
      await _applyTrainingFromQuestion(
        question: lastQ,
        suggestedReply: text,
        isEnglish: isEnglish,
        replaceBotMessageId: lastBot.id,
      );
      return;
    }

    _pushSystem(
      isEnglish
          ? 'Commands: 「pass」, 「fail」, 「should reply: …」, 「reset」'
          : 'คำสั่ง: 「ผ่าน」, 「ไม่ผ่าน」, 「ควรตอบ: …」, 「ล้าง」',
    );
  }

  Future<void> _applyTrainingFromQuestion({
    required String question,
    required String suggestedReply,
    required bool isEnglish,
    String? replaceBotMessageId,
  }) async {
    if (question.trim().isEmpty) {
      _pushSystem(isEnglish ? 'Missing customer question.' : 'ไม่พบคำถามลูกค้าที่จะผูกกับคำตอบ');
      return;
    }

    final patterns = _patternsFromQuestion(question);
    await _repo.createFaqRule(
      scope: 'global',
      patterns: patterns,
      replyText: suggestedReply,
      priority: 5,
    );

    final topic = _topicFromQuestion(question);
    await _repo.createLearnedAnswer(
      topicKey: topic,
      questionExample: question.trim(),
      answerGuidance: suggestedReply,
      scope: 'global',
    );

    await reloadTrainingData();

    final note = isEnglish
        ? 'Saved FAQ + memory · regenerated bot reply.'
        : 'บันทึก FAQ + ความจำแล้ว · สร้างคำตอบบอทใหม่';
    _pushSystem(note, appliedTraining: suggestedReply);

    final persona = _personaForQuestion(question) ?? customerPersona;
    final regen = _simulateBot(question, persona: persona, isEnglish: isEnglish);
    if (replaceBotMessageId != null) {
      final i = messages.indexWhere((m) => m.id == replaceBotMessageId);
      if (i >= 0) {
        messages[i] = messages[i].copyWith(
          reviewPassed: false,
          appliedTraining: suggestedReply,
        );
      }
    }

    _push(
      ChatBotSandboxMessage(
        id: _id(),
        kind: ChatBotSandboxMessageKind.bot,
        text: regen.text,
        at: DateTime.now(),
        source: regen.source,
        sourceLabel: regen.sourceLabel,
        customerQuestion: question.trim(),
        reviewPassed: true,
        appliedTraining: suggestedReply,
      ),
    );
  }

  Future<void> _appendVoiceRule(String rule, {required bool isEnglish}) async {
    if (rule.isEmpty) return;
    final merged = _logic.voiceExtraRules.trim().isEmpty
        ? rule
        : '${_logic.voiceExtraRules.trim()}\n$rule';
    _logic = _logic.copyWith(voiceExtraRules: merged);
    await _repo.saveLogicSettings(_logic);
    _pushSystem(
      isEnglish
          ? 'Added to voice / communication rules.'
          : 'เพิ่มในกฎโทน/การสื่อสารแล้ว',
      appliedTraining: rule,
    );
  }

  ChatBotSandboxPersona? _personaForQuestion(String question) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.kind == ChatBotSandboxMessageKind.customer &&
          m.text.trim() == question.trim()) {
        return m.persona;
      }
    }
    return null;
  }

  _BotSimResult _simulateBot(
    String customerText, {
    required ChatBotSandboxPersona persona,
    required bool isEnglish,
  }) {
    var scopes = ['global', 'property', 'discovery'];
    if (persona == ChatBotSandboxPersona.owner) {
      scopes = ['global', 'property'];
    }
    final activeFaq = _faq
        .where((r) => r['is_active'] != false)
        .toList()
      ..sort(
        (a, b) =>
            ((a['priority'] as num?)?.toInt() ?? 100)
                .compareTo((b['priority'] as num?)?.toInt() ?? 100),
      );

    for (final rule in activeFaq) {
      final scope = rule['scope']?.toString() ?? 'global';
      if (!scopes.contains(scope)) continue;
      final patterns = (rule['patterns'] as List?)?.cast<String>() ?? [];
      if (patterns.any((p) => _fuzzyIncludes(customerText, p))) {
        return _BotSimResult(
          text: rule['reply_text']?.toString() ?? '',
          source: 'faq',
          sourceLabel: isEnglish ? 'FAQ match' : 'จับ FAQ',
        );
      }
    }

    for (final la in _learned.where((a) => a.isActive)) {
      if (_similarQuestion(customerText, la.questionExample)) {
        return _BotSimResult(
          text: _guidanceToReply(la.answerGuidance, isEnglish: isEnglish),
          source: 'learned',
          sourceLabel: isEnglish ? 'Coach memory' : 'ความจำ coach',
        );
      }
    }

    return _BotSimResult(
      text: _fallbackReply(
        customerText,
        persona: persona,
        isEnglish: isEnglish,
      ),
      source: 'fallback',
      sourceLabel: isEnglish ? 'Default logic' : 'ตรรกะเริ่มต้น',
    );
  }

  String _fallbackReply(
    String customerText, {
    required ChatBotSandboxPersona persona,
    required bool isEnglish,
  }) {
    if (_logic.voiceExtraRules.trim().isNotEmpty && customerText.length < 8) {
      return isEnglish
          ? 'Could you share a bit more detail?'
          : 'ช่วยเล่าเพิ่มอีกนิดได้ไหมคะ';
    }
    final hint = _logic.strategyHints['answer_question'] ??
        ChatBotLogicSettings.defaults().strategyHints['answer_question'];
    switch (persona) {
      case ChatBotSandboxPersona.owner:
        if (isEnglish) {
          return 'Thanks — posting on RealXtate is free at listing stage; '
              'success fee applies only when a deal closes. Team will confirm.';
        }
        return 'รับทราบค่ะ ลงประกาศไม่มีค่าใช้จ่ายเบื้องต้น '
            'เก็บ Success Fee เมื่อปิดดีลสำเร็จ — ทีมจะยืนยันรายละเอียดให้';
      case ChatBotSandboxPersona.coAgent:
        if (isEnglish) {
          return 'Thanks — co-agent terms depend on the listing; '
              'our team will confirm commission after you share the case.';
        }
        return 'รับทราบค่ะ เงื่อนไขโคเอเจนต์ขึ้นกับประกาศนั้นๆ '
            'ทีมจะยืนยันค่าคอมหลังรับรายละเอียดเคส';
      case ChatBotSandboxPersona.seeker:
        if (isEnglish) {
          return 'Thanks for your message. Our team will confirm details shortly.'
              '${hint != null ? ' ($hint)' : ''}';
        }
        return 'รับทราบค่ะ เจ้าหน้าที่จะยืนยันรายละเอียดให้อีกครั้งนะคะ'
            '${hint != null ? ' ($hint)' : ''}';
    }
  }

  String _guidanceToReply(String guidance, {required bool isEnglish}) {
    final g = guidance.trim();
    if (g.isEmpty) {
      return isEnglish
          ? 'Let me check with the team and get back to you.'
          : 'ขอตรวจสอบกับทีมแล้วแจ้งกลับนะคะ';
    }
    return g;
  }

  bool _fuzzyIncludes(String text, String pattern) {
    final t = _norm(text);
    final p = _norm(pattern);
    if (p.isEmpty) return false;
    return t.contains(p);
  }

  bool _similarQuestion(String a, String b) {
    final na = _norm(a);
    final nb = _norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na.contains(nb) || nb.contains(na)) return true;
    final tokens = nb.split(RegExp(r'\s+')).where((w) => w.length >= 3);
    var hits = 0;
    for (final w in tokens) {
      if (na.contains(w)) hits++;
    }
    return hits >= 2;
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  List<String> _patternsFromQuestion(String question) {
    final q = question.trim();
    final out = <String>[q];
    final tokens = q
        .split(RegExp(r'[\s,?.!]+'))
        .map((e) => e.trim())
        .where((e) => e.length >= 3)
        .take(4);
    out.addAll(tokens);
    return out.toSet().toList();
  }

  String _topicFromQuestion(String question) {
    final words = question
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(4)
        .join('_');
    return words.isEmpty
        ? 'coach_${DateTime.now().millisecondsSinceEpoch}'
        : words.replaceAll(RegExp(r'[^\wก-๙]+'), '_');
  }

  ChatBotSandboxMessage? _lastBotMessage() {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].kind == ChatBotSandboxMessageKind.bot) return messages[i];
    }
    return null;
  }

  String? _lastCustomerText() {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].kind == ChatBotSandboxMessageKind.customer) {
        return messages[i].text;
      }
    }
    return null;
  }

  void _push(ChatBotSandboxMessage m) => messages.add(m);

  void _pushSystem(String text, {String? appliedTraining}) {
    _push(
      ChatBotSandboxMessage(
        id: _id(),
        kind: ChatBotSandboxMessageKind.system,
        text: text,
        at: DateTime.now(),
        appliedTraining: appliedTraining,
      ),
    );
  }

  String _id() => 'sb-${DateTime.now().microsecondsSinceEpoch}';
}

class _BotSimResult {
  const _BotSimResult({
    required this.text,
    required this.source,
    required this.sourceLabel,
  });

  final String text;
  final String source;
  final String sourceLabel;
}
