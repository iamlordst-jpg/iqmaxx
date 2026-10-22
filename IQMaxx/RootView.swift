import SwiftUI

private enum Theme {
    static let bg = Color(red: 0.035, green: 0.045, blue: 0.075)
    static let panel = Color(red: 0.075, green: 0.09, blue: 0.14)
    static let cyan = Color(red: 0.25, green: 0.88, blue: 0.95)
    static let violet = Color(red: 0.63, green: 0.43, blue: 0.98)
    static let muted = Color.white.opacity(0.58)
}
struct Module: Identifiable {
    let id, title, subtitle, symbol, category: String
    let tint: Color
    static let all: [Module] = [
        .init(id:"reflex",title:"Reflex Lab",subtitle:"Reaction & inhibition",symbol:"bolt.fill",category:"Reflex",tint:Theme.cyan),
        .init(id:"visual",title:"Mind Forge",subtitle:"Imagery & mental control",symbol:"cube.transparent.fill",category:"Visualization",tint:Theme.violet),
        .init(id:"memory",title:"Working Memory",subtitle:"Sequence recall",symbol:"square.grid.3x3.fill",category:"Memory",tint:.cyan),
        .init(id:"focus",title:"Focus Shift",subtitle:"Attention & target search",symbol:"scope",category:"Focus",tint:.orange),
        .init(id:"spatial",title:"Spatial Lab",subtitle:"3D rotation & perspective",symbol:"rotate.3d",category:"Spatial",tint:.pink),
        .init(id:"pattern",title:"Pattern Sense",subtitle:"Sequences & rules",symbol:"point.3.connected.trianglepath.dotted",category:"Reasoning",tint:.green),
        .init(id:"math",title:"Mental Agility",subtitle:"Quick accurate calculations",symbol:"function",category:"Mental agility",tint:.yellow),
        .init(id:"search",title:"Visual Search",subtitle:"Scan and spot targets",symbol:"viewfinder",category:"Attention",tint:.mint)
    ]
}
struct Record: Codable, Identifiable {
    var id = UUID()
    let title, category: String
    let score: Int
    let date: Date
    let seconds: Int
}
@MainActor final class Progress: ObservableObject {
    @Published private(set) var records: [Record] = [] { didSet { save() } }
    private let key = "iqmaxx.records"
    init() {
        if let data = UserDefaults.standard.data(forKey:key),
           let saved = try? JSONDecoder().decode([Record].self,from:data) { records = saved }
    }
    var today: Int { records.filter { Calendar.current.isDateInToday($0.date) }.count }
    var minutes: Int { records.reduce(0) { $0 + $1.seconds } / 60 }
    func add(_ module: Module, score: Int, seconds: Int) {
        records.append(Record(title:module.title,category:module.category,score:score,date:.now,seconds:seconds))
    }
    private func save() {
        if let data = try? JSONEncoder().encode(records) { UserDefaults.standard.set(data,forKey:key) }
    }
}
struct RootView: View {
    @StateObject private var progress = Progress()
    @State private var tab = 0
    @State private var chosen: Module?
    var body: some View {
        TabView(selection:$tab) {
            NavigationStack { home }.tabItem { Label("Home",systemImage:"square.grid.2x2.fill") }.tag(0)
            NavigationStack { library }.tabItem { Label("Train",systemImage:"flame.fill") }.tag(1)
            NavigationStack { stats }.tabItem { Label("Progress",systemImage:"chart.xyaxis.line") }.tag(2)
        }.tint(Theme.cyan)
        .fullScreenCover(item:$chosen) { module in
            if module.id == "reflex" {
                ReflexTestView(progress: progress)
            } else {
                ExerciseView(module: module, progress: progress)
            }
        }
    }
    private var home: some View {
        List {
            Section {
                Button { chosen = Module.all[0] } label: {
                    HStack {
                        Text("Reaction time").font(.body)
                        Spacer()
                        Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            } header: {
                Text("QUICK START")
            }

            Section {
                ForEach(Module.all) { module in
                    Button { chosen = module } label: {
                        HStack(spacing: 12) {
                            Text(module.title).foregroundStyle(.primary)
                            Spacer()
                            Text(module.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("TRAINING")
            }

            Section {
                HStack {
                    Text("Today")
                    Spacer()
                    Text("\(progress.today) sessions").foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total time")
                    Spacer()
                    Text("\(progress.minutes) min").foregroundStyle(.secondary)
                }
            } header: {
                Text("PROGRESS")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .navigationTitle("IQMaxx")
        .toolbar(.hidden, for: .navigationBar)
    }
    private var library: some View {
        List(Module.all) { m in
            Button { chosen = m } label: {
                HStack(spacing:13) {
                    Image(systemName:m.symbol).font(.title2).foregroundStyle(m.tint).frame(width:46,height:46).background(m.tint.opacity(0.12),in:RoundedRectangle(cornerRadius:14))
                    VStack(alignment:.leading,spacing:4) { Text(m.title).foregroundStyle(.white).font(.headline); Text(m.subtitle).foregroundStyle(Theme.muted).font(.subheadline) }
                    Spacer(); Image(systemName:"chevron.right").foregroundStyle(Theme.muted)
                }.padding(.vertical,5)
            }.listRowBackground(Theme.panel)
        }.scrollContentBackground(.hidden).background(Theme.bg).navigationTitle("Training")
    }
    private var stats: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                Text("Progress").font(.largeTitle.bold())
                HStack { metric("\(progress.records.count)","TOTAL SESSIONS","chart.bar.fill"); metric("\(progress.minutes)m","TOTAL TIME","clock") }
                Text("RECENT SESSIONS").font(.caption.bold()).tracking(1.3).padding(.top,8)
                if progress.records.isEmpty { Text("Completed sessions will appear here.").foregroundStyle(Theme.muted).padding().frame(maxWidth:.infinity,alignment:.leading).background(Theme.panel,in:RoundedRectangle(cornerRadius:16)) }
                ForEach(progress.records.reversed().prefix(20)) { r in
                    HStack {
                        VStack(alignment:.leading,spacing:4) { Text(r.title).font(.headline); Text(r.date.formatted(date:.abbreviated,time:.shortened)).font(.caption).foregroundStyle(Theme.muted) }
                        Spacer(); Text("\(r.score)%").font(.headline.monospacedDigit()).foregroundStyle(Theme.cyan)
                    }.padding(14).background(Theme.panel,in:RoundedRectangle(cornerRadius:15))
                }
                Text("Compare scores within the same exercise. Results vary with sleep, alertness and device conditions.").font(.caption).foregroundStyle(Theme.muted)
            }.padding(20)
        }.background(Theme.bg).toolbar(.hidden,for:.navigationBar)
    }
    private func metric(_ value:String,_ label:String,_ icon:String) -> some View {
        VStack(alignment:.leading,spacing:9) {
            Image(systemName:icon).foregroundStyle(Theme.cyan)
            Text(value).font(.system(size:25,weight:.bold,design:.rounded))
            Text(label).font(.system(size:9,weight:.bold)).tracking(0.8).foregroundStyle(Theme.muted)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(15).background(Theme.panel,in:RoundedRectangle(cornerRadius:17))
    }
}
struct ExerciseView: View {
    let module: Module
    @ObservedObject var progress: Progress
    @Environment(\\.dismiss) private var dismiss
    @State private var startedAt = Date()
    @State private var round = 1
    @State private var completed = 0
    @State private var correctCount = 0
    @State private var finished = false
    @State private var sequence = [Int]()
    @State private var answer = [Int]()
    @State private var sequenceHidden = false
    @State private var target = Int.random(in: 1...9)
    @State private var grid = [Int]()
    @State private var message = ""
    @State private var input = ""
    @State private var questionIndex = 0
    @State private var rating = 3
    @State private var imageryStep = 0
    @State private var shapeRotation = Int.random(in: 0...3)
    @State private var spatialChoice: Int?
    @State private var score = 0

    private let questionSet: [(String, String)] = [
        ("What comes next?  2, 4, 8, 16, ?", "32"),
        ("What comes next?  3, 6, 9, 12, ?", "15"),
        ("What comes next?  1, 1, 2, 3, 5, ?", "8"),
        ("What comes next?  10, 8, 6, 4, ?", "2"),
        ("What comes next?  5, 10, 20, 40, ?", "80")
    ]
    private let mathSet: [(String, String)] = [
        ("17 + 28", "45"), ("64 - 27", "37"), ("8 × 7", "56"), ("81 ÷ 9", "9"), ("36 + 47", "83")
    ]
    private var questions: [(String, String)] { module.id == "pattern" ? questionSet : mathSet }
    private var isSearch: Bool { module.id == "search" || module.id == "focus" }

    var body: some View {
        NavigationStack {
            Group {
                if finished {
                    resultView
                } else if module.id == "memory" {
                    memoryView
                } else if isSearch {
                    searchView
                } else if module.id == "visual" {
                    visualizationView
                } else if module.id == "spatial" {
                    spatialView
                } else {
                    reasoningView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.bg.ignoresSafeArea())
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(module.title).font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(Theme.cyan)
                }
            }
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startedAt = .now
            resetRound()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ROUND \\(min(round, 10))").font(.caption.monospaced()).foregroundStyle(Theme.muted)
            ProgressView(value: Double(min(round - 1, 10)), total: 10).tint(Theme.cyan)
        }
    }

    private var memoryView: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Text("Remember the digits in order. Tap Hide when you're ready to recall them.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            Spacer(minLength: 8)
            if !sequenceHidden {
                Text(sequence.map(String.init).joined(separator: "   "))
                    .font(.system(size: 38, weight: .medium, design: .monospaced))
                    .frame(maxWidth: .infinity).padding(.vertical, 34)
                Button("Hide sequence") {
                    sequenceHidden = true
                    answer = []
                }.buttonStyle(PrimaryStyle())
            } else {
                Text(answer.isEmpty ? "Enter the sequence" : answer.map(String.init).joined(separator: "   "))
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(1...9, id: \\.self) { n in
                        Button("\\(n)") {
                            guard answer.count < sequence.count else { return }
                            answer.append(n)
                        }
                        .font(.title2.monospacedDigit())
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button("⌫") { if !answer.isEmpty { answer.removeLast() } }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                    Button("Clear") { answer = [] }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                }
                Button("Check answer") {
                    record(answer == sequence)
                }.buttonStyle(PrimaryStyle()).disabled(answer.count != sequence.count)
            }
            Spacer(minLength: 8)
            if !message.isEmpty { Text(message).font(.subheadline).foregroundStyle(Theme.muted) }
            Button("Finish session") { finishSession() }.foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
        }.padding(22)
    }

    private var searchView: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Text("Find the target number as quickly as you can. Each number appears once.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            HStack {
                Text("FIND").font(.caption.bold()).tracking(2).foregroundStyle(Theme.muted)
                Text("\\(target)").font(.system(size: 32, weight: .semibold, design: .rounded))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(grid.enumerated()), id: \\.offset) { index, value in
                    Button("\\(value)") {
                        guard !grid.isEmpty else { return }
                        if value == target {
                            correctCount += 1
                            completed += 1
                            message = "Correct."
                            grid = []
                        } else {
                            message = "Not that one. Try again."
                        }
                    }
                    .font(.system(size: 29, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 78)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                    .disabled(grid.isEmpty)
                }
            }
            if !message.isEmpty { Text(message).font(.subheadline).foregroundStyle(Theme.muted) }
            if grid.isEmpty {
                Button(completed >= 10 ? "View results" : "Next round") {
                    if completed >= 10 { finishSession() } else { round = completed + 1; resetRound() }
                }.buttonStyle(PrimaryStyle())
            }
            Spacer()
            Button("Finish session") { finishSession() }.foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
        }.padding(22)
    }

    private var visualizationView: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Guided visualization").font(.title2.weight(.semibold))
            Text("Build a scene in your mind. There is no picture to rotate—you're training the ability to create and control mental imagery.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            Text(["1 · Place", "2 · Detail", "3 · Movement", "4 · Change perspective"][imageryStep])
                .font(.system(size: 26, weight: .medium))
            Text([
                "Imagine a familiar room. Picture where the door, window and furniture are.",
                "Add three details: the light, the colors, and one small object. Try to see each clearly.",
                "Imagine walking slowly across the room. Notice how nearby objects move relative to distant ones.",
                "Imagine viewing the room from the doorway, then from above. Keep the layout consistent."
            ][imageryStep])
            .font(.body).lineSpacing(6).foregroundStyle(Theme.muted)
            Spacer()
            if imageryStep < 3 {
                Button("Next step") { imageryStep += 1 }.buttonStyle(PrimaryStyle())
            } else {
                Text("How vivid and controllable was the image?").font(.headline)
                HStack {
                    ForEach(1...5, id: \\.self) { n in
                        Button("\\(n)") { rating = n }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(rating == n ? Theme.violet.opacity(0.5) : Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                Button("Save session") { score = rating * 20; finishSession() }.buttonStyle(PrimaryStyle())
            }
            Button("Finish session") { finishSession() }.foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
        }.padding(22)
    }

    private var spatialView: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Text("Mental rotation").font(.title2.weight(.semibold))
            Text("Imagine turning this arrow clockwise by 90°. Which direction will it point?")
                .font(.subheadline).foregroundStyle(Theme.muted)
            Text(["↑", "→", "↓", "←"][shapeRotation])
                .font(.system(size: 100, weight: .light))
                .frame(maxWidth: .infinity).padding(28)
            Text("Choose the direction after one clockwise quarter-turn.")
                .font(.caption).foregroundStyle(Theme.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \\.self) { choice in
                    Button(["↑", "→", "↓", "←"][choice]) {
                        spatialChoice = choice
                        record(choice == (shapeRotation + 1) % 4)
                    }
                    .font(.system(size: 32))
                    .frame(maxWidth: .infinity, minHeight: 65)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            if !message.isEmpty { Text(message).foregroundStyle(Theme.muted) }
            Spacer()
            Button("Finish session") { finishSession() }.foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
        }.padding(22)
    }

    private var reasoningView: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Text(module.id == "pattern" ? "Pattern recognition" : "Mental calculation")
                .font(.title2.weight(.semibold))
            Text(questions[questionIndex % questions.count].0)
                .font(.system(size: 25, weight: .medium))
                .padding(.vertical, 20)
            TextField("Answer", text: $input)
                .keyboardType(.numberPad)
                .font(.title2.monospacedDigit())
                .padding(15).background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
            if !message.isEmpty { Text(message).foregroundStyle(Theme.muted) }
            Button("Check answer") {
                let right = input.trimmingCharacters(in: .whitespacesAndNewlines) == questions[questionIndex % questions.count].1
                record(right)
            }.buttonStyle(PrimaryStyle())
            if completed > 0 {
                Button(completed >= 5 ? "View results" : "Next question") {
                    if completed >= 5 { finishSession() }
                    else { questionIndex += 1; round = completed + 1; input = ""; message = "" }
                }.buttonStyle(PrimaryStyle())
            }
            Spacer()
            Button("Finish session") { finishSession() }.foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
        }.padding(22)
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("SESSION COMPLETE").font(.caption.monospaced()).tracking(2).foregroundStyle(Theme.muted)
            Text("\\(score)%").font(.system(size: 64, weight: .medium, design: .rounded).monospacedDigit())
            Text("\\(correctCount) correct out of \\(max(completed, 1))").foregroundStyle(Theme.muted)
            Button("Done") { dismiss() }.buttonStyle(PrimaryStyle())
            Spacer()
        }.padding(26)
    }

    private func resetRound() {
        message = ""
        if module.id == "memory" {
            sequence = (0..<4).map { _ in Int.random(in: 1...9) }
            sequenceHidden = false
            answer = []
        } else if isSearch {
            target = Int.random(in: 1...9)
            grid = Array(1...9).shuffled()
        } else if module.id == "spatial" {
            shapeRotation = Int.random(in: 0...3)
            spatialChoice = nil
        }
    }

    private func record(_ correct: Bool) {
        completed += 1
        if correct { correctCount += 1 }
        score = Int((Double(correctCount) / Double(max(completed, 1)) * 100).rounded())
        message = correct ? "Correct." : "Not quite."
        if module.id == "memory" {
            if completed >= 5 { message = "Five rounds complete. Finish the session when ready." }
            else { round = completed + 1; sequence = (0..<4).map { _ in Int.random(in: 1...9) }; sequenceHidden = false; answer = [] }
        } else if module.id == "spatial" {
            if completed < 10 { round = completed + 1; resetRound() }
            else { message = "Ten rounds complete. Finish the session when ready." }
        }
    }

    private func finishSession() {
        guard !finished else { return }
        if module.id == "visual" && completed == 0 { completed = 1; correctCount = rating > 0 ? 1 : 0; score = rating * 20 }
        finished = true
        progress.add(module, score: score, seconds: max(1, Int(Date().timeIntervalSince(startedAt))))
    }
}

private struct ReflexTestView: View {
    @ObservedObject var progress: Progress
    @Environment(\.dismiss) private var dismiss
    @State private var state = "intro"
    @State private var signalTime: UInt64 = 0
    @State private var reactionTimes: [Double] = []
    @State private var falseStarts = 0
    @State private var resultMs: Int?
    @State private var startedAt = Date()
    @State private var scheduledSignal = false
    @State private var trialToken = UUID()
    @State private var touchActive = false
    @State private var didSaveResult = false

    private let green = Color(red: 0.12, green: 0.82, blue: 0.32)
    private let red = Color(red: 0.78, green: 0.12, blue: 0.12)
    private var average: Int {
        guard !reactionTimes.isEmpty else { return 0 }
        return Int((reactionTimes.reduce(0, +) / Double(reactionTimes.count)).rounded())
    }
    private var best: Int { Int((reactionTimes.min() ?? 0).rounded()) }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            if state == "intro" {
                VStack(spacing: 18) {
                    Spacer()
                    Text("REACTION TIME").font(.system(size: 13, weight: .semibold, design: .monospaced)).tracking(3).foregroundStyle(.secondary)
                    Text("Tap when green.").font(.system(size: 30, weight: .semibold))
                    Text("Five rounds · no animations · milliseconds").font(.system(size: 14)).foregroundStyle(.secondary)
                    Spacer()
                    Button("Start test") { startTrial() }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.black)
                    Button("Close") { dismiss() }.foregroundStyle(.secondary).padding(.top, 4)
                }
                .padding(28)
            } else if state == "waiting" || state == "go" {
                VStack(spacing: 18) {
                    if state == "waiting" {
                        Text("WAIT").font(.system(size: 18, weight: .bold, design: .monospaced)).tracking(4)
                        Text("Don't tap yet").font(.system(size: 15)).opacity(0.8)
                    } else {
                        Text("TAP NOW").font(.system(size: 28, weight: .bold, design: .monospaced)).tracking(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .accessibilityElement()
                .accessibilityLabel(state == "go" ? "Green signal. Tap now." : "Wait for green signal")
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !touchActive else { return }
                            touchActive = true
                            tappedScreen()
                        }
                        .onEnded { _ in touchActive = false }
                )
            } else if state == "result" {
                VStack(spacing: 18) {
                    Spacer()
                    Text("\(resultMs ?? 0)").font(.system(size: 76, weight: .medium, design: .rounded).monospacedDigit())
                    Text("milliseconds").font(.system(size: 16)).foregroundStyle(.secondary)
                    Text(reactionTimes.count < 5 ? "Round \(reactionTimes.count) of 5 complete" : "Test complete")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                    Spacer()
                    Button(reactionTimes.count < 5 ? "Next round" : "View results") {
                        if reactionTimes.count < 5 { startTrial() } else { state = "summary" }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.black)
                }.padding(28)
            } else if state == "early" {
                VStack(spacing: 18) {
                    Spacer()
                    Text("Too soon").font(.system(size: 34, weight: .semibold))
                    Text("Wait for the green screen, then tap anywhere.")
                        .font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Spacer()
                    Button("Try this round again") { startTrial() }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.black)
                }.padding(28)
            } else {
                VStack(spacing: 18) {
                    Spacer()
                    Text("RESULT").font(.system(size: 13, weight: .semibold, design: .monospaced)).tracking(3).foregroundStyle(.secondary)
                    Text("\(average) ms").font(.system(size: 60, weight: .medium, design: .rounded).monospacedDigit())
                    Text("Average reaction time").foregroundStyle(.secondary)
                    HStack(spacing: 32) {
                        VStack(spacing: 5) { Text("\(best) ms").font(.title2.monospacedDigit()); Text("Best").font(.caption).foregroundStyle(.secondary) }
                        VStack(spacing: 5) { Text("\(falseStarts)").font(.title2.monospacedDigit()); Text("False starts").font(.caption).foregroundStyle(.secondary) }
                    }.padding(.top, 8)
                    Spacer()
                    Button("Test again") {
                        reactionTimes = []; falseStarts = 0; startedAt = .now; didSaveResult = false; state = "intro"
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.black)
                    Button("Done") { dismiss() }.foregroundStyle(.secondary)
                }.padding(28)
                .onAppear {
                    if !didSaveResult {
                        progress.add(Module.all[0], score: max(0, 100 - average / 5), seconds: max(1, Int(Date().timeIntervalSince(startedAt))))
                        didSaveResult = true
                    }
                }
            }
        }
        .foregroundStyle(state == "go" ? .black : .white)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .transaction { $0.animation = nil }
    }

    private var background: Color {
        switch state {
        case "waiting": return Color(red: 0.10, green: 0.10, blue: 0.11)
        case "go": return green
        case "early": return red
        default: return Color.black
        }
    }

    private func startTrial() {
        trialToken = UUID()
        let token = trialToken
        state = "waiting"
        resultMs = nil
        scheduledSignal = true
        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard scheduledSignal, token == trialToken, state == "waiting" else { return }
            signalTime = DispatchTime.now().uptimeNanoseconds
            state = "go"
        }
    }

    private func tappedScreen() {
        if state == "waiting" {
            scheduledSignal = false
            trialToken = UUID()
            falseStarts += 1
            state = "early"
        } else if state == "go" {
            let now = DispatchTime.now().uptimeNanoseconds
            let elapsedMs = Double(now &- signalTime) / 1_000_000
            resultMs = Int(elapsedMs.rounded())
            reactionTimes.append(elapsedMs)
            scheduledSignal = false
            state = "result"
        }
    }
}

private struct PrimaryStyle: ButtonStyle {
    func makeBody(configuration:Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.black).frame(maxWidth:.infinity,minHeight:52).background(Theme.cyan,in:RoundedRectangle(cornerRadius:16)).opacity(configuration.isPressed ? 0.82:1)
    }
}
