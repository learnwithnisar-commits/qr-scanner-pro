import com.android.build.api.dsl.ApplicationExtension
import java.util.Properties
import org.gradle.kotlin.dsl.configure

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing key — loaded from key.properties (CI) or ../qr-scanner-release/key.properties (local).
// Kept OUT of version control so secrets never ship with the source.
val keyPropsFile = rootProject.file("key.properties").let {
    if (it.exists()) it else rootProject.file("../qr-scanner-release/key.properties")
}
val keyProps = Properties()
if (keyPropsFile.exists()) {
    keyPropsFile.inputStream().use { stream -> keyProps.load(stream) }
}
val hasReleaseKey = keyPropsFile.exists()

configure<ApplicationExtension> {
    namespace = "com.nisarahmedkatyar.qrscannerpro"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.nisarahmedkatyar.qrscannerpro"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Keep the release build lean.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
