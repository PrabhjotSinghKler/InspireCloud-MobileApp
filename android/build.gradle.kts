buildscript {
    val kotlin_version = "2.0.0"  // Update to 2.0.0
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Add the Google services Gradle plugin
        classpath("com.google.gms:google-services:4.4.2")
        
        // Add Kotlin gradle plugin dependency
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        
        // Keep any other existing classpaths
    }
}

// Rest of your existing code...
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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