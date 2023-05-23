import SwiftUI

struct Question: Identifiable {
    let id = UUID()
    let text: String
}

struct HomeView: View {
    @Binding var isQuestionnaireStarted: Bool
    
    var body: some View {
        VStack {
            Text("Welcome to the Wellness Advisor App")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(Color.black)
            Button(action: {
                isQuestionnaireStarted = true
            }) {
                Text("Let's get started")
                    .font(.headline)
                    .padding()
                    .background(Color.mint)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
//                    .overlay(
//                        RoundedRectangle(cornerRadius:10)
//                            .stroke(Color.blue, lineWidth: 2)
//                    )
            }
        }
        .padding()
    }
}

struct ContentView: View {
    @State private var questions: [Question] = [
        Question(text: "What's your name?"),
        Question(text: "How would you rate your sleep on a scale of 1-10?"),
        Question(text: "How many hours of sleep do you get on average?"),
        Question(text: "What time do you usually go to sleep? (please type a number between 1 and 24)"),
        Question(text: "What time do you usually wake up? (Please type a number between 1 and 24)")
    ]
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [UUID: String] = [:]
    @State private var isQuestionnaireComplete = false
    @State private var isQuestionnaireStarted = false
    @State private var timeToNotSubmit = true
    
    var currentQuestion: Question? {
        if currentQuestionIndex < questions.count {
            return questions[currentQuestionIndex]
        }
        return nil
    }
    
    
    
    var body: some View {
        let question = questions[currentQuestionIndex]
            if isQuestionnaireComplete {
                SidebarNavigation()
            } else if isQuestionnaireStarted {
                if currentQuestionIndex < questions.count && timeToNotSubmit{
                    QuestionPromptView(question: question, answer: $answers[question.id], onNextQuestion: moveNextQuestion)
                } else {
                    SubmitView(isComplete: $isQuestionnaireComplete)
                }
            } else {
                HomeView(isQuestionnaireStarted: $isQuestionnaireStarted)
            }
        }

    func moveNextQuestion() {
        guard let question = currentQuestion, let answer = answers[question.id], !answer.isEmpty else {
            return
        }
        
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            timeToNotSubmit = false
        }
    }
        
    
}

struct SubmitView: View{
    @Binding var isComplete: Bool
        
        var body: some View {
            VStack {
                Text("Thank you for your answers!")
                    .font(.title)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    isComplete = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
}

struct QuestionPromptView: View{
    let question: Question
    @Binding var answer: String?
    let onNextQuestion: () -> Void
        
        var body: some View {
            VStack {
                Text(question.text)
                    .font(.title)
                    .padding()
                    
                TextField("Answer", text: Binding(
                    get: { answer ?? "" },
                    set: { answer = $0 }
                ))
                .padding()
                    
                Button(action: onNextQuestion) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

struct AnswerView: View{
    let question: Question
        @Binding var answer: String?
        
        var body: some View {
            VStack {
                Text(question.text)
                TextField("Answer", text: Binding(
                    get: { answer ?? "" },
                    set: { answer = $0 }
                ))
            }
            .padding()
        }
}

struct SidebarNavigation: View {
    enum NavigationItem {
        case SleepScreen, ExerciseScreen, DietScreen
    }
    
    @State private var selectedMenuItem: String? = "Pick A Screen!"
    var body: some View {
        VStack {
            NavigationView {
                if selectedMenuItem == nil {
                    VStack {
                        NavigationLink(destination: SleepScreen(), tag: "sleep", selection: $selectedMenuItem) {
                            Button("Screen 1") {
                                selectedMenuItem = "sleep"
                            }
                        }
                        NavigationLink(destination: ExerciseScreen(), tag: "exercise", selection: $selectedMenuItem) {
                            Button("Screen 2") {
                                selectedMenuItem = "exercise"
                            }
                        }
                        NavigationLink(destination: DietScreen(), tag: "diet", selection: $selectedMenuItem) {
                            Button("Screen 3") {
                                selectedMenuItem = "diet"
                            }
                        }
                    }
                    .padding()
                } else {
                    List {
                        NavigationLink(destination: SleepScreen(), tag: "Sleep", selection: $selectedMenuItem) {
                            Label("Sleep", systemImage: "powersleep")
                        }
                        NavigationLink(destination: ExerciseScreen(), tag: "Exercise", selection: $selectedMenuItem) {
                            Label("Exercise", systemImage: "figure.run")
                        }
                        NavigationLink(destination: DietScreen(), tag: "Diet", selection: $selectedMenuItem) {
                            Label("Diet", systemImage: "fork.knife")
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .navigationTitle("Wellness Options")
                    .multilineTextAlignment(.center)
                    
                    /*
                     Text(selectedMenuItem ?? "Select an item")
                     .frame(maxWidth: .infinity, maxHeight: .infinity) */
                }
            }
        }
    }
}

struct SleepScreen: View {
    var body: some View{
        ZStack{
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.blue.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
            VStack{
                Text("Recommendation 1")
                    .padding()
                
                Text("Recommendation 2")
                    .padding()
            }
        }
        
                
    }
}

struct ExerciseScreen: View {
    var body: some View{
        LinearGradient(
            gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
    }
}

struct DietScreen: View {
    var body: some View{
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow.opacity(0.7), Color.green.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
    }
}
    

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
struct SleepScreen_Previews: PreviewProvider {
    static var previews: some View {
        SleepScreen()
    }
}
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigation()
    }
}
