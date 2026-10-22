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
        .sheet(item:$chosen) { ExerciseView(module:$0,progress:progress) }
    }
    private var home: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {
                    VStack(alignment:.leading,spacing:5) {
                        Text("IQMAXX").font(.caption.bold()).tracking(3).foregroundStyle(Theme.cyan)
                        Text("Train your mind.").font(.system(size:30,weight:.bold,design:.rounded))
                        Text("Reflexes, imagery and cognitive skills.").font(.subheadline).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName:"brain.head.profile").font(.system(size:28)).foregroundStyle(Theme.violet).frame(width:58,height:58).background(Theme.panel,in:RoundedRectangle(cornerRadius:18))
                }
                HStack(spacing:12) {
                    metric("\(progress.today)","SESSIONS TODAY","checkmark.circle")
                    metric("\(progress.minutes)","MINUTES TRAINED","clock")
                }
                Button { chosen = Module.all[0] } label: {
                    HStack(spacing:15) {
                        Image(systemName:"play.fill").font(.title2).foregroundStyle(Theme.cyan).frame(width:54,height:54).background(Theme.cyan.opacity(0.12),in:Circle())
                        VStack(alignment:.leading,spacing:5) {
                            Text("DAILY STARTER").font(.caption2.bold()).tracking(1.3).foregroundStyle(Theme.cyan)
                            Text("Start a quick session").font(.title3.bold()).foregroundStyle(.white)
                            Text("Begin with a reaction test").font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Image(systemName:"arrow.up.right").foregroundStyle(.white.opacity(0.7))
                    }.padding(17).background(Theme.panel,in:RoundedRectangle(cornerRadius:23)).overlay(RoundedRectangle(cornerRadius:23).stroke(Theme.cyan.opacity(0.25),lineWidth:1))
                }.buttonStyle(.plain)
                HStack { Text("TRAINING SYSTEMS").font(.caption.bold()).tracking(1.4); Spacer(); Text("8 MODULES").font(.system(size:9,weight:.bold)).foregroundStyle(Theme.muted) }
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
                    ForEach(Module.all) { module in
                        Button { chosen = module } label: {
                            VStack(alignment:.leading,spacing:12) {
                                Image(systemName:module.symbol).font(.title2).foregroundStyle(module.tint).frame(width:42,height:42).background(module.tint.opacity(0.12),in:RoundedRectangle(cornerRadius:13))
                                Text(module.title).font(.headline).foregroundStyle(.white)
                                Text(module.subtitle).font(.caption).foregroundStyle(Theme.muted).frame(maxWidth:.infinity,alignment:.leading).lineLimit(2)
                                Spacer(minLength:0)
                                Text("OPEN LAB ↗").font(.system(size:9,weight:.bold)).tracking(1).foregroundStyle(module.tint)
                            }.frame(maxWidth:.infinity,minHeight:137,alignment:.leading).padding(15).background(Theme.panel,in:RoundedRectangle(cornerRadius:19)).overlay(RoundedRectangle(cornerRadius:19).stroke(module.tint.opacity(0.15),lineWidth:1))
                        }.buttonStyle(.plain)
                    }
                }
                Text("Practice scores are not clinical measurements or validated IQ scores.").font(.caption2).foregroundStyle(Theme.muted)
            }.padding(20)
        }.background(Theme.bg.ignoresSafeArea()).toolbar(.hidden,for:.navigationBar)
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
    @Environment(\.dismiss) private var dismiss
    @State private var start = Date()
    @State private var waiting = false
    @State private var lit = false
    @State private var signalAt = Date()
    @State private var taps = [Double]()
    @State private var message = "Start when ready."
    @State private var phase = 0
    @State private var sequence = [Int]()
    @State private var answer = [Int]()
    @State private var target = Int.random(in:1...9)
    @State private var rating = 3
    @State private var input = ""
    @State private var finished = false
    @State private var score = 0
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:20) {
                    HStack { Image(systemName:module.symbol).font(.title).foregroundStyle(module.tint); VStack(alignment:.leading) { Text(module.title).font(.title2.bold()); Text(module.subtitle).foregroundStyle(Theme.muted).font(.subheadline) } }
                    if finished {
                        Image(systemName:"checkmark.seal.fill").font(.system(size:46)).foregroundStyle(Theme.cyan)
                        Text("Session complete").font(.title.bold())
                        Text("Score: \(score)% · saved to your local history").foregroundStyle(Theme.muted)
                        Button("Done") { dismiss() }.buttonStyle(PrimaryStyle())
                    } else if module.id == "reflex" { reflex }
                    else if module.id == "memory" { memory }
                    else if module.id == "focus" || module.id == "search" { focus }
                    else if module.id == "visual" || module.id == "spatial" { imagery }
                    else { reasoning }
                }.padding(22)
            }.background(Theme.bg.ignoresSafeArea()).toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Close") { dismiss() }.foregroundStyle(Theme.cyan) } }
        }.onAppear { start = .now }
    }
    private var reflex: some View {
        VStack(alignment:.leading,spacing:16) {
            Text("Wait for cyan, then tap. Early taps are false starts.").foregroundStyle(Theme.muted)
            Text("TRIAL \(min(taps.count+1,5)) / 5").font(.caption.bold()).tracking(1.4).foregroundStyle(Theme.cyan)
            Button { tapSignal() } label: {
                VStack(spacing:14) {
                    Circle().fill(lit ? Theme.cyan : Color.white.opacity(0.12)).frame(width:100,height:100).overlay(Circle().stroke(lit ? Theme.cyan : .white.opacity(0.2),lineWidth:2)).shadow(color:lit ? Theme.cyan.opacity(0.5):.clear,radius:22)
                    Text(lit ? "TAP NOW" : "WAIT").font(.headline.bold()).tracking(2)
                }.foregroundStyle(lit ? Theme.cyan : .white).frame(maxWidth:.infinity).frame(height:230).background(Theme.panel,in:RoundedRectangle(cornerRadius:24))
            }.buttonStyle(.plain)
            Text(message).foregroundStyle(Theme.muted)
            if !taps.isEmpty { Text("Average: \(Int(taps.reduce(0,+)/Double(taps.count)*1000)) ms").font(.subheadline.monospacedDigit()) }
            Button(phase == 0 ? "Start test" : (taps.count >= 5 ? "Save results" : "Next trial")) {
                if phase == 0 || taps.count < 5 { beginTrial() }
                else { finish(score:max(0,min(100,100-Int(taps.reduce(0,+)/Double(taps.count)*100)))) }
            }.buttonStyle(PrimaryStyle())
        }
    }
    private func beginTrial() {
        phase = 1; lit = false; waiting = true; message = "Stay ready…"
        DispatchQueue.main.asyncAfter(deadline:.now()+Double.random(in:1.4...3.5)) {
            guard !finished, waiting else { return }
            signalAt = .now; lit = true; message = "Signal!"
        }
    }
    private func tapSignal() {
        guard phase > 0 else { message = "Press Start test first."; return }
        if lit { taps.append(Date().timeIntervalSince(signalAt)); lit = false; waiting = false; message = "Recorded. Prepare for the next trial." }
        else { message = "False start or no active signal — wait for cyan."; waiting = false }
    }
    private var memory: some View {
        VStack(alignment:.leading,spacing:16) {
            Text("Memorize the sequence, hide it, then repeat it in order.").foregroundStyle(Theme.muted)
            if sequence.isEmpty {
                Button("Generate sequence") { sequence = (0..<4).map { _ in Int.random(in:1...9) } }.buttonStyle(PrimaryStyle())
            } else {
                Text(sequence.map(String.init).joined(separator:"   ")).font(.system(size:30,weight:.bold,design:.rounded)).foregroundStyle(Theme.cyan).frame(maxWidth:.infinity).padding(24).background(Theme.panel,in:RoundedRectangle(cornerRadius:18))
                Button("Hide sequence") { phase = 1 }.buttonStyle(PrimaryStyle()).disabled(phase == 1)
                if phase == 1 {
                    LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3),spacing:10) {
                        ForEach(1...9,id:\.self) { n in Button("\(n)") { if answer.count < sequence.count { answer.append(n) } }.font(.title2.bold()).frame(maxWidth:.infinity,minHeight:56).background(Theme.panel,in:RoundedRectangle(cornerRadius:13)) }
                    }
                    Text("Your answer: "+answer.map(String.init).joined(separator:" · ")).foregroundStyle(Theme.muted)
                    Button("Check answer") { let correct = answer == sequence; finish(score:correct ? 100 : Int(Double(zip(answer,sequence).filter{$0 == $1}.count)/Double(sequence.count)*100)) }.buttonStyle(PrimaryStyle()).disabled(answer.count != sequence.count)
                }
            }
        }
    }
    private var focus: some View {
        VStack(alignment:.leading,spacing:16) {
            Text("Find the target number. Reset your attention after each attempt.").foregroundStyle(Theme.muted)
            Text("FIND  \(target)").font(.caption.bold()).tracking(2).foregroundStyle(module.tint)
            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3),spacing:12) {
                ForEach(0..<9,id:\.self) { i in
                    let value = i == target-1 ? target : ((i+target)%9)+1
                    Button("\(value)") { if value == target { finish(score:100) } else { message = "Not that one — look again." } }
                        .font(.system(size:28,weight:.bold,design:.rounded)).frame(maxWidth:.infinity,minHeight:74).background(Theme.panel,in:RoundedRectangle(cornerRadius:16))
                }
            }
            Text(message).foregroundStyle(Theme.muted)
            Button("New target") { target = Int.random(in:1...9); message = "Find the new target." }.buttonStyle(PrimaryStyle())
        }
    }
    private var imagery: some View {
        VStack(alignment:.leading,spacing:17) {
            Text(module.id == "spatial" ? "Imagine the cube rotating in 3D. Predict its shape from another viewpoint." : "Imagine a familiar place. Explore it from another viewpoint and recall details without looking at a picture.").foregroundStyle(Theme.muted)
            ZStack {
                RoundedRectangle(cornerRadius:24).fill(Theme.panel).frame(height:205)
                Circle().stroke(Theme.violet.opacity(0.25),lineWidth:1).frame(width:150,height:150)
                RoundedRectangle(cornerRadius:17).fill(LinearGradient(colors:[Theme.violet,Theme.cyan.opacity(0.7)],startPoint:.topLeading,endPoint:.bottomTrailing)).frame(width:86,height:86).rotation3DEffect(.degrees(Double(phase*30)),axis:(x:1,y:1,z:0.3)).shadow(color:Theme.violet.opacity(0.35),radius:20)
            }
            Button("Rotate reference object") { withAnimation(.spring()) { phase += 1 } }.buttonStyle(PrimaryStyle())
            Text("Rate vividness and control").font(.headline)
            HStack { ForEach(1...5,id:\.self) { n in Button("\(n)") { rating = n }.frame(maxWidth:.infinity,minHeight:48).background(rating == n ? Theme.violet.opacity(0.35):Theme.panel,in:RoundedRectangle(cornerRadius:12)) } }
            Text("1 = faint or unstable · 5 = vivid and controllable").font(.caption).foregroundStyle(Theme.muted)
            Button("Complete exercise") { finish(score:rating*20) }.buttonStyle(PrimaryStyle())
        }
    }
    private var reasoning: some View {
        VStack(alignment:.leading,spacing:17) {
            Text("Accuracy first; speed comes later.").foregroundStyle(Theme.muted)
            Text(module.id == "pattern" ? "What comes next?  2, 4, 8, 16, ?" : "Calculate:  17 + 28").font(.title3.bold()).padding(22).frame(maxWidth:.infinity,alignment:.leading).background(Theme.panel,in:RoundedRectangle(cornerRadius:18))
            TextField("Your answer",text:$input).keyboardType(.numberPad).padding(15).background(Theme.panel,in:RoundedRectangle(cornerRadius:14))
            Button("Check answer") { finish(score:input.trimmingCharacters(in:.whitespaces) == (module.id == "pattern" ? "32":"45") ? 100:0) }.buttonStyle(PrimaryStyle())
        }
    }
    private func finish(score:Int) {
        guard !finished else { return }
        self.score = score; finished = true
        progress.add(module,score:score,seconds:max(1,Int(Date().timeIntervalSince(start))))
    }
}
private struct PrimaryStyle: ButtonStyle {
    func makeBody(configuration:Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.black).frame(maxWidth:.infinity,minHeight:52).background(Theme.cyan,in:RoundedRectangle(cornerRadius:16)).opacity(configuration.isPressed ? 0.82:1)
    }
}
