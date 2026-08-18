# Stripe Android SDK ProGuard Rules
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.** { *; }

# Keep all Stripe classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

-dontwarn com.stripe.android.**
-dontwarn com.reactnativestripesdk.**

