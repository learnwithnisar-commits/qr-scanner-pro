/// Central place for ALL AdMob IDs.
///
/// HOW TO GO LIVE:
///   1. Create an AdMob account at https://admob.google.com
///   2. Register the app ("QR Scanner Pro", Android, package
///      com.nisarahmedkatyar.qrscannerpro) to get a real App ID.
///   3. Create real ad units (1 banner + 1 interstitial).
///   4. Replace the TEST values below with the real ones, and put the real
///      App ID in android/app/src/main/AndroidManifest.xml
///      `meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"`
///      tag).
///   5. Rebuild the release AAB/APK.
///
/// Until then the official Google TEST ids below show test ads — safe for
/// development and for the Play closed-testing track.
class AdsConfig {
  AdsConfig._();

  // --- Ad unit IDs (one-line swap to go live) ---
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // TEST banner
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // TEST interstitial

  // --- Policy ---
  /// Show an interstitial after this many scan-result closes.
  static const int interstitialEveryNResults = 3;

  /// Set to true ONLY with real IDs + real App ID in the manifest.
  static const bool useRealAds = false;
}
