buildscript {
    // 1. Define Kotlin Version
    val kotlin_version by extra("1.9.0") 

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // 2. Classpath Dependencies - Standardized versions
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        classpath("com.google.gms:google-services:4.4.2") 
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. FIXED BUILD DIRECTORY CONFIGURATION
// This replaces the complex "../../build" logic which causes Error 26
rootProject.layout.buildDirectory.set(file("${project.projectDir}/../build"))

subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 4. Clean Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}