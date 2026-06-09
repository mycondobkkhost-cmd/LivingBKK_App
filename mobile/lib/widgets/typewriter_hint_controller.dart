import 'dart:async';

/// พิมพ์ hint ทีละตัวอักษรภายใน [duration] — วนซ้ำได้
class TypewriterHintController {
  TypewriterHintController({
    this.duration = const Duration(seconds: 5),
    this.cacheKey,
    this.loop = true,
    this.pauseBetweenLoops = const Duration(milliseconds: 1200),
  });

  Duration duration;
  final String? cacheKey;
  final bool loop;
  final Duration pauseBetweenLoops;

  Timer? _localTimer;
  Timer? _localPauseTimer;
  String _localFull = '';
  int _localIndex = 0;
  String _localVisible = '';

  static final _sessions = <String, _TypewriterSession>{};

  String get visible {
    final key = cacheKey;
    if (key != null) return _sessions[key]?.visible ?? '';
    return _localVisible;
  }

  void start(String fullText, void Function() onTick) {
    final key = cacheKey;
    if (key != null) {
      _startShared(key, fullText, onTick);
      return;
    }
    _startLocal(fullText, onTick);
  }

  void _startShared(String key, String fullText, void Function() onTick) {
    var session = _sessions[key];
    if (session == null || session.fullText != fullText) {
      session?.dispose();
      session = _TypewriterSession(
        fullText,
        loop: loop,
        pauseBetweenLoops: pauseBetweenLoops,
      );
      _sessions[key] = session;
    }
    session.addListener(onTick);
    session.ensureRunning(duration);
  }

  void _startLocal(String fullText, void Function() onTick) {
    stop();
    _localFull = fullText;
    _localIndex = 0;
    _localVisible = '';
    if (_localFull.isEmpty) return;

    void tick() {
      if (_localIndex >= _localFull.length) {
        _localTimer?.cancel();
        _localTimer = null;
        if (loop) {
          _localPauseTimer = Timer(pauseBetweenLoops, () {
            _localIndex = 0;
            _localVisible = '';
            onTick();
            _scheduleLocal(onTick);
          });
        }
        return;
      }
      _localIndex++;
      _localVisible = _localFull.substring(0, _localIndex);
      onTick();
    }

    _scheduleLocal(onTick);
  }

  void _scheduleLocal(void Function() onTick) {
    final stepMs =
        (duration.inMilliseconds / _localFull.length).ceil().clamp(16, 500);
    _localTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      if (_localIndex >= _localFull.length) {
        t.cancel();
        _localTimer = null;
        if (loop) {
          _localPauseTimer = Timer(pauseBetweenLoops, () {
            _localIndex = 0;
            _localVisible = '';
            onTick();
            _scheduleLocal(onTick);
          });
        }
        return;
      }
      _localIndex++;
      _localVisible = _localFull.substring(0, _localIndex);
      onTick();
    });
  }

  void stop() {
    final key = cacheKey;
    if (key != null) {
      _sessions[key]?.removeListener();
      return;
    }
    _localTimer?.cancel();
    _localPauseTimer?.cancel();
    _localTimer = null;
    _localPauseTimer = null;
  }

  void reset(String key) {
    _sessions.remove(key)?.dispose();
  }

  void dispose() => stop();
}

class _TypewriterSession {
  _TypewriterSession(
    this.fullText, {
    required this.loop,
    required this.pauseBetweenLoops,
  });

  final String fullText;
  final bool loop;
  final Duration pauseBetweenLoops;
  int index = 0;
  Timer? timer;
  Timer? pauseTimer;
  void Function()? listener;

  String get visible =>
      index <= 0 ? '' : fullText.substring(0, index.clamp(0, fullText.length));

  void addListener(void Function() onTick) {
    listener = onTick;
  }

  void removeListener() {
    listener = null;
  }

  void ensureRunning(Duration duration) {
    if (timer != null && timer!.isActive) return;
    if (pauseTimer != null && pauseTimer!.isActive) return;
    if (index >= fullText.length) {
      if (loop) {
        _scheduleRestart(duration);
      } else {
        listener?.call();
      }
      return;
    }
    _run(duration);
  }

  void _run(Duration duration) {
    final stepMs =
        (duration.inMilliseconds / fullText.length).ceil().clamp(16, 500);
    timer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      if (index >= fullText.length) {
        t.cancel();
        timer = null;
        listener?.call();
        if (loop) {
          _scheduleRestart(duration);
        }
        return;
      }
      index++;
      listener?.call();
    });
  }

  void _scheduleRestart(Duration duration) {
    pauseTimer?.cancel();
    pauseTimer = Timer(pauseBetweenLoops, () {
      index = 0;
      listener?.call();
      _run(duration);
    });
  }

  void dispose() {
    timer?.cancel();
    pauseTimer?.cancel();
    timer = null;
    pauseTimer = null;
    listener = null;
  }
}
