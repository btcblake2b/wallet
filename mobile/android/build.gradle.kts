allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
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

// WORKAROUND (AGP 8+ / Kotlin 2.x): plugin Flutter legacy il cui
// android/build.gradle non è compatibile con AGP 8.11.1 + Kotlin 2.2.20.
// - flutter_jailbreak_detection 1.10.0: manca `namespace` e il target Java/Kotlin
//   di default (1.8) è incoerente col target Java del progetto (17) → "Inconsistent
//   JVM-target compatibility" (Java 17 vs Kotlin 1.8). Inietta namespace e allinea
//   Java E Kotlin a 17.
// - sentry_flutter 8.14.2: `kotlinOptions.languageVersion = "1.6"` non è più
//   supportato da Kotlin 2.x → alza a 1.8 (jvmTarget 1.8 resta coerente con Java 1.8).
// Da rimuovere quando si migra ai fork/versioni aggiornati dei plugin.
subprojects {
    when (name) {
        "flutter_jailbreak_detection" -> {
            afterEvaluate {
                extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { ext ->
                    if (ext.namespace.isNullOrBlank()) {
                        ext.namespace = "appmire.be.flutterjailbreakdetection"
                    }
                    ext.compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
                // Il plugin fissa kotlinOptions.jvmTarget = "1.8"; in Kotlin 2.x
                // `kotlinOptions` è un wrapper deprecato su `compilerOptions`, quindi
                // sovrascrivere qui (dopo la valutazione del progetto) allinea il
                // target a 17 ed elimina il mismatch con compileDebugJavaWithJavac.
                val kotlinExt = extensions.findByName("kotlin")
                if (kotlinExt is org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension) {
                    kotlinExt.compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    }
                }
            }
        }
        "sentry_flutter" -> {
            afterEvaluate {
                val kotlinExt = extensions.findByName("kotlin")
                if (kotlinExt is org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension) {
                    kotlinExt.compilerOptions {
                        languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
