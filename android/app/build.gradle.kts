import com.android.build.gradle.internal.api.ApkVariantOutputImpl

plugins {
	id("com.android.application")
	// The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
	id("dev.flutter.flutter-gradle-plugin")
}

android {
	namespace = "com.technicjelle.simple_audio_converter"
	compileSdk = flutter.compileSdkVersion
	ndkVersion = "28.2.13676358"

	compileOptions {
		sourceCompatibility = JavaVersion.VERSION_17
		targetCompatibility = JavaVersion.VERSION_17
	}

	defaultConfig {
		applicationId = "com.technicjelle.simple_audio_converter.zh"
		// You can update the following values to match your application needs.
		// For more information, see: https://flutter.dev/to/review-gradle-config.
		minSdk = flutter.minSdkVersion
		targetSdk = flutter.targetSdkVersion
		versionCode = flutter.versionCode
		versionName = flutter.versionName
	}

	signingConfigs {
		create("releaseLocal") {
			// Kept out of the repo. Set these env vars before a release build:
			// TIMBRE_KEYSTORE, TIMBRE_STORE_PASSWORD, TIMBRE_KEY_ALIAS,
			// TIMBRE_KEY_PASSWORD.
			storeFile = file(System.getenv("TIMBRE_KEYSTORE") ?: "../sac-release.p12")
			storePassword = System.getenv("TIMBRE_STORE_PASSWORD") ?: ""
			keyAlias = System.getenv("TIMBRE_KEY_ALIAS") ?: "sac"
			keyPassword = System.getenv("TIMBRE_KEY_PASSWORD") ?: ""
		}
	}

	buildTypes {
		release {
			signingConfig = signingConfigs.getByName("releaseLocal")

			isMinifyEnabled = true
			isShrinkResources = true

			proguardFiles(
				// Default file with automatically generated optimization rules.
				getDefaultProguardFile("proguard-android-optimize.txt"),
				"proguard-rules.pro"
			)
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

//Source: https://github.com/saber-notes/saber/blob/c50bdb0fdd0ad02e963171a9cf8b6d2214542832/android/app/build.gradle.kts#L76-L85
val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
	val variant = this
	variant.outputs.forEach { output ->
		val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
		if (abiVersionCode != null) {
			(output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
		}
	}
}
