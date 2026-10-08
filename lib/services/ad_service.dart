import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';

/// Wraps AdMob: banner ads + interstitial shown after every N result closes.
/// Never shows an interstitial on app launch or exit (Play policy).
class AdService extends ChangeNotifier {
  InterstitialAd? _interstitial;
  int _resultsSinceInterstitial = 0;
  bool _loadingInterstitial = false;

  /// Call each time a scan-result sheet is closed.
  /// Returns true if an interstitial was shown.
  Future<bool> onResultClosed() async {
    _resultsSinceInterstitial++;
    if (_resultsSinceInterstitial >= AdsConfig.interstitialEveryNResults) {
      _resultsSinceInterstitial = 0;
      await showInterstitial();
      return true;
    }
    return false;
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

  @override
  void initState() {
    super.initState();
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
