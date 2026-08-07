# QuitMate - Google Play Store Publishing Guide

এই গাইডে **QuitMate** অ্যাপটির অ্যান্ডয়েড রিলিজ বিল্ড (AAB Bundle) তৈরি করা এবং প্লে স্টোরে আপলোড করার সম্পূর্ণ প্রক্রিয়া ধাপে ধাপে বর্ণনা করা হয়েছে।

---

## ১. রিলিজ কি-স্টোর (Release Keystore) তৈরি করা

অ্যাপ সাইন করার জন্য আপনার কম্পিউটারে একটি Digital Signing Key তৈরি করতে হবে। 

পাওয়ারশেল (PowerShell) বা টার্মিনালে প্রজেক্টের `android/app/` ডিরেক্টরিতে গিয়ে নিচের কমান্ডটি রান করুন:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> [!IMPORTANT]
> - পাসওয়ার্ড হিসেবে একটি শক্ত পাসওয়ার্ড দিন (মনে রাখুন বা সুরক্ষিত স্থানে লিখে রাখুন)।
> - তৈরি হওয়া `upload-keystore.jks` ফাইলটি নিরাপদ স্থানে গুচ্ছিত রাখুন। এটি হারিয়ে গেলে পরবর্তীতে প্লে স্টোরে অ্যাপ আপডেট দেওয়া যাবে না।

---

## ২. key.properties ফাইল কনফিগার করা

`android/` ফোল্ডারের ভেতরে `key.properties` নামে একটি ফাইল তৈরি করুন এবং নিচের বিষয়গুলো লিখুন:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEYSTORE_PASSWORD
keyAlias=upload
storeFile=../app/upload-keystore.jks
```
*(এখানে `YOUR_KEYSTORE_PASSWORD`-এর জায়গায় আপনার দেয়া পাসওয়ার্ডটি বসান).*

---

## ৩. android/app/build.gradle.kts আপডেট করা

`android/app/build.gradle.kts` ফাইলে রিলিজ সাইনিং কনফিগারেশন যোগ করুন:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## ৪. অ্যান্ডয়েড অ্যাপ বান্ডেল (AAB) বিল্ড করা

টার্মিনালে প্রজেক্ট ডিরেক্টরিতে গিয়ে রান করুন:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

বিল্ড সফল হলে আউটপুট ফাইলটি এই লোকেশনে তৈরি হবে:
`build/app/outputs/bundle/release/app-release.aab`

---

## ৫. গুগল প্লে কন্সোল আপলোড ও সাবমিশন ধাপ

১. **Google Play Console** এ লগইন করে **Create App** বাটনে ক্লিক করুন।
২. App Name দিন: **QuitMate**
৩. Default language: **Bengali - bn** বা **English (United States) - en-US**
৪. App or game: **App** | Free or Paid: **Free**
৫. Declarations মেনে নিয়ে অ্যাপ তৈরি করুন।

### গুরুত্বপূর্ণ ধাপসমূহ:
- **Set up your app**:
  - Privacy Policy URL দিন।
  - App Access: *All functionality is available without special access restrictions* (অথবা ডেমো লগইন ক্রেডেনশিয়াল প্রদান করুন)।
  - Ads: *No, my app does not contain ads*.
  - Content Rating: IARC ফর্ম পুরণ করুন (`app_content_questionnaire_guide.md` অনুযায়ী)।
  - Target Audience: 13+ / 18+।
  - Data Safety: ফর্ম পুরণ করুন (`google_play_data_safety.md` অনুযায়ী)।

- **Main Store Listing**:
  - `metadata/play_store_metadata.md` থেকে Title, Short Description, Full Description কপি করুন।
  - App Icon (512x512): `app_publishing_pack/assets/app_icon.png` আপলোড করুন।
  - Feature Graphic (1024x500): `app_publishing_pack/assets/feature_graphic.png` আপলোড করুন।
  - Phone Screenshots (কমপক্ষে ৪টি স্ক্রিনশট আপলোড করুন)।

- **Publishing Track**:
  - **Testing -> Internal testing** এ প্রথমে `app-release.aab` ফাইল আপলোড করে নিজে ও বন্ধুদের নিয়ে টেস্ট করুন।
  - সবকিছু ঠিক থাকলে **Production -> Create new release** এ `app-release.aab` আপলোড করুন এবং **Send for review** এ ক্লিক করুন।

গুগল সাধারণত ২৪ থেকে ৭২ ঘণ্টার মধ্যে অ্যাপটি রিভিউ করে প্লে স্টোরে লাইভ করে দেয়! 🚀
