import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_ids.dart';

/// Banner on Home / How to play / Play, a rewarded +5s boost before a run,
/// and an interstitial after every 5th finished play.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool get rewardedReady => _rewardedAd != null;

  bool get _useTestAds => kDebugMode;

  String get _interstitialUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? AdIds.googleTestAndroidInterstitial
          : AdIds.googleTestIosInterstitial;
    }
    return Platform.isAndroid ? AdIds.androidInterstitial : AdIds.iosInterstitial;
  }

  String get _rewardedUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? AdIds.googleTestAndroidRewarded
          : AdIds.googleTestIosRewarded;
    }
    return Platform.isAndroid ? AdIds.androidRewarded : AdIds.iosRewarded;
  }

  String get bannerUnitId {
    if (_useTestAds) {
      return Platform.isAndroid ? AdIds.googleTestAndroidBanner : AdIds.googleTestIosBanner;
    }
    return Platform.isAndroid ? AdIds.androidBanner : AdIds.iosBanner;
  }

  bool get _canLoadInterstitial => _interstitialUnitId.isNotEmpty;
  bool get _canLoadRewarded => _rewardedUnitId.isNotEmpty;

  Future<bool>? _initFuture;
  bool _sdkReady = false;

  Future<bool> ensureInitialized() => init();

  Future<bool> init() => _initFuture ??= _initSdk();

  Future<bool> _initSdk() async {
    if (kIsWeb) return false;
    try {
      await MobileAds.instance.initialize();
      _sdkReady = true;
      _loadInterstitial();
      loadRewarded();
    } catch (_) {
      _sdkReady = false;
    }
    return _sdkReady;
  }

  void _loadInterstitial() {
    if (!_canLoadInterstitial) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// Hiển thị xong (hoặc lỗi / chưa có quảng cáo) mới hoàn thành Future.
  Future<void> showInterstitial() async {
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitialAd = null;
    final done = Completer<void>();
    void finish(Ad a) {
      a.dispose();
      _loadInterstitial();
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, _) => finish(a),
    );
    ad.show();
    return done.future;
  }

  void loadRewarded() {
    if (!_canLoadRewarded) return;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  /// Trả về true nếu người chơi xem đủ để nhận thưởng.
  Future<bool> showRewarded() async {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewarded();
      return false;
    }
    _rewardedAd = null;
    var earned = false;
    final done = Completer<bool>();
    void finish(Ad a) {
      a.dispose();
      loadRewarded();
      if (!done.isCompleted) done.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, _) => finish(a),
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> with WidgetsBindingObserver {
  BannerAd? _ad;
  bool _loaded = false;

  bool get _inWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_ad == null) unawaited(_load());
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _tearDownAd();
    }
  }

  void _tearDownAd() {
    final ad = _ad;
    if (ad == null) return;
    _ad = null;
    _loaded = false;
    ad.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (!AdIds.showBanner || kIsWeb || _inWidgetTest || _ad != null) return;
    if (AdService.instance.bannerUnitId.isEmpty) return;
    final ready = await AdService.instance.ensureInitialized();
    if (!ready || !mounted) return;
    try {
      final ad = BannerAd(
        adUnitId: AdService.instance.bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (!mounted || _ad != loaded) {
              loaded.dispose();
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (_ad == ad) _ad = null;
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      _ad?.dispose();
      _ad = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdIds.showBanner || kIsWeb) return const SizedBox.shrink();
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox(height: 50);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: AdWidget(ad: ad),
    );
  }
}
