# Stripe push provisioning stubs — referenced from stripe_android's React Native
# bridge but unavailable without the Stripe Issuing paid product. The dependency
# is excluded via configurations.all in build.gradle.kts; these rules suppress
# any residual R8 warnings from compile-time references.
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Flutter engine — keep all public embedding surface.
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# App entry point
-keep class com.earthly.app.** { *; }

# Kotlin stdlib / coroutines
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keep class kotlin.Metadata { *; }

# OkHttp / Okio (used by flutter_inappwebview and plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Conscrypt TLS provider (used for certificate handling on older Android)
-dontwarn org.conscrypt.**

# flutter_secure_storage uses EncryptedSharedPreferences / Android Keystore
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
