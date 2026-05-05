# Keep generated kotlinx serializers
-keepclassmembers @kotlinx.serialization.Serializable class * {
    *** Companion;
}
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
