import os
import re

def configure():
    print("Running Android Platform Configuration...")

    # 1. Update Gradle wrapper to 9.3.1
    wrapper_path = "android/gradle/wrapper/gradle-wrapper.properties"
    if os.path.exists(wrapper_path):
        with open(wrapper_path, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r"distributionUrl=.*", r"distributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-bin.zip", content)
        with open(wrapper_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Updated gradle-wrapper.properties to Gradle 9.3.1")

    # 2. Update local.properties
    local_path = "android/local.properties"
    sdk_dir = os.environ.get("ANDROID_HOME", "/usr/local/lib/android/sdk")
    flutter_root = os.environ.get("FLUTTER_ROOT", "")
    with open(local_path, "w", encoding="utf-8") as f:
        f.write(f"sdk.dir={sdk_dir}\n")
        if flutter_root:
            f.write(f"flutter.sdk={flutter_root}\n")
        f.write("flutter.minSdkVersion=24\n")
        f.write("flutter.targetSdkVersion=36\n")
        f.write("flutter.compileSdkVersion=36\n")
        f.write("flutter.versionCode=1\n")
        f.write("flutter.versionName=1.0.0\n")
    print("Created android/local.properties")

    # 3. Update android/app/build.gradle.kts
    app_gradle = "android/app/build.gradle.kts"
    if os.path.exists(app_gradle):
        with open(app_gradle, "r", encoding="utf-8") as f:
            c = f.read()
        c = c.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
        c = c.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
        c = c.replace("targetSdk = flutter.targetSdkVersion", "targetSdk = 36")
        c = c.replace("versionCode = flutter.versionCode", "versionCode = 10")
        c = c.replace("versionName = flutter.versionName", 'versionName = "1.0.9"')
        c = c.replace("ndkVersion = flutter.ndkVersion", "// ndkVersion")
        with open(app_gradle, "w", encoding="utf-8") as f:
            f.write(c)
        print("Updated android/app/build.gradle.kts")

    # 4. Update android/app/src/main/AndroidManifest.xml
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            c = f.read()
        target = 'android:name="${applicationName}"'
        c = c.replace(target, "")
        permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
"""
        if "READ_MEDIA_VIDEO" not in c:
            c = c.replace("<application", permissions + "\n    <application", 1)
        if 'android:requestLegacyExternalStorage="true"' not in c:
            c = c.replace("<application", '<application\n        android:requestLegacyExternalStorage="true"', 1)
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(c)
        print("Updated AndroidManifest.xml with storage & media permissions")

    # 5. Append subprojects hook to android/build.gradle.kts
    root_gradle = "android/build.gradle.kts"
    if os.path.exists(root_gradle):
        with open(root_gradle, "r", encoding="utf-8") as f:
            c = f.read()
        if "setCompileSdk" not in c:
            hook = """
subprojects {
    if (project.name != "app") {
        val setCompileSdk = {
            val a = extensions.findByName("android")
            if (a != null) {
                try {
                    a.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType).invoke(a, 36)
                } catch (e: Exception) {}
            }
        }
        if (state.executed) {
            setCompileSdk()
        } else {
            afterEvaluate {
                setCompileSdk()
            }
        }
    }
}
"""
            with open(root_gradle, "a", encoding="utf-8") as f:
                f.write(hook)
            print("Appended subprojects hook to android/build.gradle.kts")

    # 6. Update gradle.properties
    gradle_props = "android/gradle.properties"
    with open(gradle_props, "a", encoding="utf-8") as f:
        f.write("\nandroid.useAndroidX=true\n")
        f.write("android.enableJetifier=true\n")
        f.write("android.nonTransitiveRClass=false\n")
        f.write("org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G\n")
    print("Updated android/gradle.properties")

if __name__ == "__main__":
    configure()
