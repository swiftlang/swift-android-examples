# Swift-Java UI Showcase — new example app

## Context

Swift Mentorship Program project: add a new example to `swift-android-examples` — a "kitchen sink" showcase app navigating between screens that demo UI component categories (buttons, selection controls, sliders, text inputs, and a form with validation).

**Agreed architecture** (confirmed with user): Swift owns everything conceptual — the declarative component model, all state, event handling, and form validation. Jetpack Compose cannot be invoked from Swift (it's a Kotlin compiler-plugin feature), so "instantiate components in Swift" is realized as Swift declaring per-screen component trees and a **thin generic Kotlin/Compose (Material 3) renderer** interpreting them — a unidirectional data-flow loop with Swift as the single source of truth. Built on the repo's recommended **swift-java/JExtract** pattern, cloned from `hello-swift-java/`.

**Design constraints**: keep it as simple as a reference example demands (tiny diff against the canonical `hello-swift-java` example, minimal dependencies and files), and treat documentation as a per-milestone deliverable, not an afterthought.

## Key decisions

- **Boundary = JSON strings over three top-level Swift functions** (`showcaseScreens()`, `showcaseScreen(id)`, `showcaseDispatch(screenId, componentId, eventJSON)` — all `(String…) -> String`, the exact shape JExtract `mode:"jni"` proves out with `SwiftHashing.hash`). No `enableJavaCallbacks` — avoids the `--disable-sandbox` flag weather-lib needs. Pull-based loop: Kotlin pulls screen JSON → user event → dispatch → new screen JSON → recompose.
- **Exactly one new repo dependency**: `androidx.navigation:navigation-compose` **2.8.9** (compatible with Compose BOM 2024.09.00 / Compose 1.7 — do NOT use 2.9+). No ViewModel: the current screen JSON lives in `remember { mutableStateOf(...) }` (same pattern `hashing-app/MainActivity.kt` already uses); real state lives in Swift, so it survives navigation regardless.
- **Kotlin decodes with `org.json`** (platform built-in; no serialization plugin, no wrapper data classes — render straight from `JSONObject`).
- **Swift model**: `enum Component` with hand-written `Codable` (flat `"kind"`-discriminated JSON, exact wire schema pinned by Swift tests). `FoundationEssentials` JSONEncoder is already in the `swiftRuntimeLibs` allowlist.
- **Minimal component surface, one variant each** (variants are follow-up PRs / good first issues): filled button only (no `enabled` flag), no `steps` on slider, textField keeps `keyboard: text|email|number` (the form demo needs it) but no `secure`.
- **File budget** — Kotlin: `MainActivity.kt` (nav graph + home list + screen scaffold), `ComponentRenderer.kt` (the single `when`), copied `ui/theme/` files; ~250 lines total. Swift: `Component.swift`, `Event.swift`, `ShowcaseStore.swift` (registry + dispatch + JSON), `Screens.swift` (all five screens — they're short), `ShowcaseAPI.swift` (the three entry points, heavily commented — it's *the* boundary readers came to see).
- **Naming**: dir `swift-java-ui-showcase/` with `showcase-lib/` + `showcase-app/`; Gradle `:swift-java-ui-showcase-showcase-lib` / `:swift-java-ui-showcase-showcase-app`; Swift package/target `ShowcaseKit`; `javaPackage` `com.example.showcasekit` (generated class `com.example.showcasekit.ShowcaseKit`); lib namespace `com.example.showcaselib`; app namespace/appId `com.example.showcaseapp`.

## JSON wire schema (contract, pinned by Swift tests)

```jsonc
// showcaseScreens()
{"screens":[{"id":"buttons","title":"Buttons"},{"id":"selection","title":"Selection Controls"},
            {"id":"sliders","title":"Sliders"},{"id":"textInputs","title":"Text Inputs"},
            {"id":"form","title":"Form & Validation"}]}

// showcaseScreen("buttons") — also the return of showcaseDispatch
{"id":"buttons","title":"Buttons","components":[
  {"kind":"sectionHeader","id":"hdr1","text":"Buttons"},
  {"kind":"text","id":"tapCount","text":"Tapped 0 times"},
  {"kind":"button","id":"tapMe","label":"Tap me"},
  {"kind":"toggle","id":"wifi","label":"Wi-Fi","isOn":true},
  {"kind":"checkbox","id":"terms","label":"Accept terms","isChecked":false},
  {"kind":"radioGroup","id":"size","label":"Size","options":["S","M","L"],"selectedIndex":1},
  {"kind":"slider","id":"volume","label":"Volume","value":0.5,"min":0.0,"max":1.0},
  {"kind":"textField","id":"email","label":"Email","text":"","placeholder":"you@example.com",
   "keyboard":"email","error":null}]}

// eventJSON for showcaseDispatch:
{"type":"tap"} | {"type":"setBool","value":true} | {"type":"setString","value":"abc"} |
{"type":"setNumber","value":0.75} | {"type":"select","index":2}
```

## Milestone 0 — Branch + committed plan

- `git switch -c swift-java-ui-showcase-plan` (from `main`).
- Write this plan (merged: decisions + simplicity/docs revision) to `swift-java-ui-showcase/PLAN.md` (`.md` is `.licenseignore`-exempt, no header needed) and commit it: `git add swift-java-ui-showcase/PLAN.md && git commit -m "Add swift-java-ui-showcase example implementation plan"`.

## Milestone 1 — Scaffolding + registration (repo builds again by end of milestone)

**`swift-java-ui-showcase/showcase-lib/`** (clone of `hello-swift-java/hashing-lib/`):
- `Package.swift`: rename package/target to `ShowcaseKit`, drop swift-crypto, keep swift-java `from: "0.1.2"` + `JExtractSwiftPlugin` + `.swiftLanguageMode(.v5)`, add `ShowcaseKitTests` test target.
- `Sources/ShowcaseKit/swift-java.config`: `{"javaPackage": "com.example.showcasekit", "mode": "jni"}`.
- `build.gradle` (Groovy): copy **weather-lib's** version (already `compileSdkVersion 36`; hashing-lib is stuck at 34), then change: `namespace "com.example.showcaselib"`; `inputs.dir(… "Sources/ShowcaseKit")`; the JExtract outputs path segment `…/ShowcaseKit/destination/JExtractSwiftPlugin/src/generated/java`; remove `--disable-sandbox` + its comment (no Java callbacks). Keep `swiftRuntimeLibs` as-is. **These two hardcoded target-name paths are the #1 copy-paste failure** — add "why" comments at both.
- `Sources/ShowcaseKit/ShowcaseAPI.swift` stub with the three public functions; copy `gradle.properties` and `.gitignore` (at `swift-java-ui-showcase/.gitignore`).

**`swift-java-ui-showcase/showcase-app/`** (clone of `hello-swift-java/hashing-app/`, near-verbatim `build.gradle.kts` diff):
- `build.gradle.kts`: namespace/appId `com.example.showcaseapp`; deps `project(":swift-java-ui-showcase-showcase-lib")`, `org.swift.swiftkit:swiftkit-core:+`, `libs.androidx.navigation.compose`.
- Copy manifest, `res/**` (app label in `strings.xml`), `ui/theme/*.kt` → `ShowcaseAppTheme`, stock unit/instrumented tests, `proguard-rules.pro`, `.gitignore`.

**Registration edits:**
- `settings.gradle.kts` — after line 49 (weather-app block), same include+projectDir-remap pattern:
  ```kotlin
  include(":swift-java-ui-showcase-showcase-lib")
  project(":swift-java-ui-showcase-showcase-lib").projectDir = file("swift-java-ui-showcase/showcase-lib")
  include(":swift-java-ui-showcase-showcase-app")
  project(":swift-java-ui-showcase-showcase-app").projectDir = file("swift-java-ui-showcase/showcase-app")
  ```
- `gradle/libs.versions.toml` — add `navigationCompose = "2.8.9"` and the `androidx-navigation-compose` library entry.

Verify: `./gradlew :swift-java-ui-showcase-showcase-app:assembleDebug --stacktrace` (needs swiftly + Android Swift SDK + swiftkit-core published to mavenLocal, per `hello-swift-java/README.md`).

## Milestone 2 — Walking skeleton + first README

Swift `ShowcaseStore` with a single `buttons` screen holding a tap counter; `dispatch` increments and re-renders. Kotlin: minimal `ComponentRenderer` (`text` + `button` only); `MainActivity` shows the screen directly (no nav yet), JSON held in `remember { mutableStateOf(...) }`. On emulator: tap increments label — proves JExtract, JSON, state, recomposition.

Swift shapes (`Sources/ShowcaseKit/`):
```swift
// Component.swift — hand-written Codable, flat keys + "kind" discriminator
public enum Component: Equatable {
  case sectionHeader(id: String, text: String)
  case text(id: String, text: String)
  case button(id: String, label: String)
  case toggle(id: String, label: String, isOn: Bool)
  case checkbox(id: String, label: String, isChecked: Bool)
  case radioGroup(id: String, label: String, options: [String], selectedIndex: Int?)
  case slider(id: String, label: String, value: Double, min: Double, max: Double)
  case textField(id: String, label: String, text: String, placeholder: String,
                 keyboard: Keyboard, error: String?)
}
// Event.swift — "type" discriminator
public enum Event: Codable { case tap, setBool(Bool), setString(String), setNumber(Double), select(Int) }
// ScreenDefinition.swift protocol lives in ShowcaseStore.swift or Screens.swift:
protocol ScreenDefinition: AnyObject {
  var id: String { get }; var title: String { get }
  func handle(_ event: Event, componentId: String)
  func body() -> [Component]
}
// ShowcaseStore.swift — singleton registry + JSON encode, main-thread only (documented invariant)
```

Kotlin renderer core (`ComponentRenderer.kt`): one `when (c.getString("kind"))` → Material 3 composables, emitting event `JSONObject`s back through an `onEvent(id, event)` lambda. Text-field note (inline comment in code): keep in-flight text in local `remember` state keyed on the Swift value; dispatch `setString` per change but don't re-seed from JSON while focused (avoids IME cursor jitter).

**Docs (this milestone)**: create `swift-java-ui-showcase/README.md` modeled on `hello-swift-java/README.md` — what it demonstrates, setup (link to hashing-lib README for swiftly/SDK/`publishToMavenLocal` long-form), and an ASCII sequence diagram of the loop: `Compose tap → showcaseDispatch(screen, id, eventJSON) → Swift mutates state → returns screen JSON → recompose`.

## Milestone 3 — Full model, five screens, validation, Swift tests

- `Screens.swift`: `ButtonsScreen` (tap counter), `SelectionScreen` (switch, checkboxes, radio group whose selection affects another component — cross-component state in Swift), `SlidersScreen` (value readout formatted in Swift), `TextInputsScreen` (text/email/number keyboards), `FormScreen` (name/email/age + submit; `Validation` pure functions → `textField.error`; success replaces form with a success `text`).
- `Tests/ShowcaseKitTests/` (swift-testing `@Test`/`#expect`, mirroring `SwiftHashingTests`): exact-JSON schema lock for a known screen (references the README schema table by name), event decoding, dispatch round-trip, validation rules.
- Verify: `cd swift-java-ui-showcase/showcase-lib && swift test` (pure Swift model — host build, no JNI).
- **Docs**: expand README with the **JSON schema table** (every `kind`, its keys, events it emits) — the contract document; `///` doc comments on every public Swift symbol.

## Milestone 4 — Navigation

`MainActivity.kt`: `NavHost` with `"home"` (Scaffold + TopAppBar + LazyColumn of screens from `showcaseScreens()`) and `"screen/{screenId}"` (load JSON, render components, back nav). Graph is data-driven from Swift's registry — adding a Swift screen requires zero Kotlin changes.

## Milestone 5 — CI + final docs

- `.github/workflows/ci.yml` — add after the weather-app step (~line 263):
  ```yaml
  - name: Build swift-java-ui-showcase APK
    run: ./gradlew :swift-java-ui-showcase-showcase-app:assemble${{ matrix.configuration }} --stacktrace
  ```
- Finish `swift-java-ui-showcase/README.md`: one screenshot per screen in `swift-java-ui-showcase/resources/` (repo convention); **"Add your own screen in ~20 lines"** tutorial (conform to `ScreenDefinition`, append to registry, done — no Kotlin changes) and **"Add your own component kind"** tutorial (four touch points: enum case, Codable case, `when` branch, schema table row).
- Root `README.md`: 5-6 line subsection under "Additional swift-java examples" — Swift-owned declarative UI state over a single JSON/JNI boundary, link to `swift-java-ui-showcase/README.md`.
- License sweep: every new `.swift`, `.kt`, `.gradle`, `.gradle.kts` gets the `//===---…===//` Apache-2.0 Swift.org header, `Copyright (c) 2026` (CI soundness-enforced; `.xml`, `.md`, `.json`, `.config`, `Package.swift` exempt per `.licenseignore`).

## Verification (end-to-end)

1. `cd swift-java-ui-showcase/showcase-lib && swift build && swift test` (host).
2. `./gradlew :swift-java-ui-showcase-showcase-lib:buildSwiftAll` — generated Java appears under `showcase-lib/.build/plugins/outputs/showcase-lib/ShowcaseKit/destination/…`.
3. `./gradlew :swift-java-ui-showcase-showcase-app:assembleDebug --stacktrace`, then `assembleRelease`.
4. Emulator: navigate all five screens; tap counter works, toggle state survives navigation (state lives in Swift), form errors + success path.
5. `./gradlew assembleDebug` — all other examples still build.

## Risks / mitigations

- **JExtract jni-mode limits** → only `(String…) -> String` top-level functions cross the boundary; never structs/enums/optionals.
- **Schema drift** → hand-written Codable + exact-JSON Swift tests; Kotlin uses `opt*` with defaults.
- **navigation-compose clash** → pin 2.8.9; don't bump the Compose BOM.
- **Stale/wrong JExtract paths in build.gradle** → the two `ShowcaseKit` path edits called out in Milestone 1, with inline comments.
- **`swiftkit-core:+` unresolved locally** → README documents `publishToMavenLocal` (CI already does it).
- **IME jitter on per-keystroke JNI dispatch** → local buffered text state in the textField renderer.
- **Singleton concurrency warnings** → language mode v5 keeps them warnings; all entry points are main-thread, documented invariant.
