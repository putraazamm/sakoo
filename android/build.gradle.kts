// android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix compileSdk for plugins like nfc_manager that use outdated android-31
subprojects {
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android")
            as? com.android.build.gradle.BaseExtension
        androidExtension?.apply {
            compileSdkVersion(34)
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}