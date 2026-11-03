import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';

/// Wraps AdMob: banner ads + interstitial shown after every N result closes.
/// Never shows an interstitial on app launch or exit (Play policy).
class AdService extends ChangeNotifier {
  InterstitialAd? _interstitial;
  int _resultsSinceInterstitial = 0;
  bool _loadingInterstitial = false;
  DateTime? _lastInterstitialShown;

  /// Call each time a scan-result sheet is closed.
  /// Returns true if an interstitial was shown.
  /// Policy: natural break (result close) + every-N-results +
  /// minimum-interval cooldown. No timer-triggered ads.
  Future<bool> onResultClosed() async {
    _resultsSinceInterstitial++;
    if (_resultsSinceInterstitial < AdsConfig.interstitialEveryNResults) {
      return false;
    }
    final last = _lastInterstitialShown;
    if (last != null &&
        DateTime.now().difference(last).inSeconds <
            AdsConfig.interstitialMinIntervalSeconds) {
      // Cooldown active: keep the counter at threshold so the NEXT
      // result close (after the cooldown) can show — never force an
      // ad mid-task just because the cooldown expired.
      return false;
    }
    _resultsSinceInterstitial = 0;
    await showInterstitial();
    return true;
  }

  void loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed to load: $err');
          _loadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    _interstitial = null;
    _lastInterstitialShown = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadInterstitial(); // preload the next one
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        debugPrint('Interstitial failed to show: $err');
        a.dispose();
        loadInterstitial();
      },
    );
    await ad.show();
    notifyListeners();
  }

  /// Standard anchored banner widget for the scanner / history screens.
  static Widget banner() => _AdBanner();

  void disposeService() {
    _interstitial?.dispose();
  }
}

class _AdBanner extends StatefulWidget {
  @override
  State<_AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<_AdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _bannerRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Anchored adaptive banner: full-width, Google-optimized height
    // (never taller than 15% of screen height). Falls back to the
    // standard banner size if no adaptive size is available, so a
    // failed size lookup never leaves the slot broken or overlapping
    // scanner controls — the widget stays anchored at the bottom.
    if (_bannerRequested) return;
    _bannerRequested = true;
    final width = MediaQuery.of(context).size.width.truncate();
    AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      MediaQuery.of(context).orientation,
      width,
    ).then((size) {
      if (!mounted) return;
      _bannerAd = BannerAd(
        adUnitId: AdsConfig.bannerAdUnitId,
        size: size ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _loaded = true),
          onAdFailedToLoad: (ad, err) {
            debugPrint('Banner failed to load: $err');
            ad.dispose();
          },
        ),
      )..load();
    }).catchError((_) {
      if (!mounted) return;
      _bannerAd = BannerAd(
        adUnitId: AdsConfig.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _loaded = true),
          onAdFailedToLoad: (ad, err) {
            debugPrint('Banner failed to load: $err');
            ad.dispose();
          },
        ),
      )..load();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
