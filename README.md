## IQMaxx

A native SwiftUI cognitive-training app by ST. The interface mixes minimal layouts with a dark palette, cyan/violet accents and focused training screens.

### Modules
- Reflex Lab — randomized visual reaction trials and false-start feedback.
- Mind Forge — mental imagery practice and self-rated vividness/control.
- Working Memory — sequence recall.
- Focus Shift and Visual Search — target selection and attention.
- Spatial Lab — 3D rotation and perspective practice.
- Pattern Sense — number sequences.
- Mental Agility — mental arithmetic.

Training history is stored locally with UserDefaults. No account, API key or network connection is needed. Scores are practice indicators, not clinical measurements or validated IQ scores.

### Build
The Xcode project is generated from project.yml using XcodeGen:

    brew install xcodegen
    xcodegen generate
    xcodebuild -project IQMaxx.xcodeproj -scheme IQMaxx -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

GitHub Actions builds a simulator app bundle and uploads it as a ZIP artifact. This is for simulator/testing and is not a signed iPhone IPA. Device installation requires a device-signing workflow and appropriate signing setup.
