plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.norlex.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.norlex.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // لا يوجد release keystore حقيقي بعد.
        // release build يُوقّع مؤقتًا بمفتاح debug فقط لإنتاج APK قابل للتثبيت للاختبار،
        // وهذا غير صالح للنشر على Google Play. لإعداد توقيع نشر حقيقي أضف
        // android/key.properties + keystore حقيقي، ثم عدّل signingConfigs.getByName("release").
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}
