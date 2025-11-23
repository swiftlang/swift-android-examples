pluginManagement {
    repositories {
        mavenLocal()
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        mavenLocal()
        google()
        mavenCentral()
    }
}

rootProject.name = "Swift Android Examples"

// swift-java examples
include(":hello-swift-java-hashing-lib")
project(":hello-swift-java-hashing-lib").projectDir = file("hello-swift-java/hashing-lib")
include(":hello-swift-java-hashing-app")
project(":hello-swift-java-hashing-app").projectDir = file("hello-swift-java/hashing-app")

include(":swift-java-weather-app-weather-lib")
project(":swift-java-weather-app-weather-lib").projectDir = file("swift-java-weather-app/weather-lib")
include(":swift-java-weather-app-weather-app")
project(":swift-java-weather-app-weather-app").projectDir = file("swift-java-weather-app/weather-app")

// raw-jni examples
include(":hello-swift-raw-jni")
include(":hello-swift-raw-jni-callback")
include(":hello-swift-raw-jni-library")

// native-only examples
include(":native-activity")
