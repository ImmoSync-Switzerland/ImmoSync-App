# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep Stripe classes
-keep class com.stripe.android.** { *; }
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Keep Stripe push provisioning classes specifically
-keep class com.stripe.android.pushProvisioning.** { *; }
# Defensive duplicate (case variation safeguard if package name changes casing in future)
-keep class com.stripe.android.pushprovisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep notification classes
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Additional explicit keeps for Stripe Push Provisioning (some may already be covered by wildcards)
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivity { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider { *; }

# Keep model classes (defensive; already partially covered by com.stripe.android.**)
-keep class com.stripe.android.model.** { *; }

# Keep all Parcelable implementations (Args / Error often implement Parcelable)
-keep class * implements android.os.Parcelable { *; }

# Preserve source and line numbers for better stack traces post-minify
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,RuntimeVisibleParameterAnnotations,RuntimeInvisibleParameterAnnotations
 # Preserve inner class & enclosing method metadata so R8 doesn't strip synthetic
 # nested classes referenced by outer classes (e.g., $g, $h suffix classes in warnings)
 -keepattributes InnerClasses,EnclosingMethod

 # Catch any remaining synthetic / anonymous inner classes in pushProvisioning package
 -keep class com.stripe.android.pushProvisioning.**$* { *; }
# Potential nested/sibling namespaces sometimes used internally
-keep class com.stripe.android.paymentsheet.pushProvisioning.** { *; }

 # (Flutter project, not React Native, but if migration occurred these lines would help)
 -keep class com.reactnativestripesdk.pushprovisioning.** { *; }