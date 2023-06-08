//
//  ContentView.swift
//  Sleep-clean
//
//  Created by slmrc on 5/22/23.
//

import SwiftUI
import CoreML

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
//                            .stroke(Color.mint, lineWidth: 2)
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
    @State private var predictionOutput: Double?
    @StateObject private var healthDataFetcher = HealthDataFetcher()
    
    
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
                    VStack {
                        SubmitView(isComplete: $isQuestionnaireComplete)
                        if healthDataFetcher.predictionOutput == nil {
                            Button("Fetch Health Data") {
                                healthDataFetcher.requestHealthDataAccess()
                            }
                        } else if let predictionOutput = healthDataFetcher.predictionOutput {
                            Text("Prediction Output: \(predictionOutput)")
                        }
                    }
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
        NavigationView {
            List {
                NavigationLink(destination: SleepScreen(title: "Recommendation"), tag: "Sleep", selection: $selectedMenuItem) {
                    Label("Sleep", systemImage: "powersleep")
                }
                NavigationLink(destination: ExerciseScreen(title: "Recommendation"), tag: "Exercise", selection: $selectedMenuItem) {
                    Label("Exercise", systemImage: "figure.run")
                }
                NavigationLink(destination: DietScreen(title: "Recommendation"), tag: "Diet", selection: $selectedMenuItem) {
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

func printHello(text: String){
    print(text)
}

struct SleepScreen: View {
    let title: String
    
    var body: some View{
        ZStack() {
            Text(title)
                .font(Font.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors:
                            [Color.black.opacity(0.7),
                             Color.mint.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all))
            Button(
                "Get Recommendation",
                action: {printHello(text: title)}
            )
            .frame(width: 300, height: 100)
            .font(.title)
            .foregroundColor(Color.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors:
                        [Color.mint.opacity(0.7),
                         Color.black.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all))
            .cornerRadius(10)
        }
    }
}

struct SleepRecommendationScreen: View {
    let title: String
    var body: some View{
        Text(title)
            .font(Font.system(size: 26, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors:
                        [Color.black.opacity(0.7),
                         Color.mint.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all))
    }
}

struct ExerciseScreen: View {
    let title: String
    let temp = HealthDataFetcher()
    var body: some View{
        ZStack{
            Text(title)
                .font(Font.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors:
                            [Color.red.opacity(0.8),
                             Color.orange.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                )
            Button("Get Recommendation",
                   action: {printHello(text: title)})
            .frame(width: 300, height: 100)
            .font(.title)
            .foregroundColor(Color.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors:
                        [Color.orange.opacity(0.7),
                         Color.red.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all))
            .cornerRadius(10)
        }
    }
}

struct ExerciseRecommendationScreen: View {
    let title: String
    var body: some View{
        Text(title)
            .font(Font.system(size: 26, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors:
                        [Color.red.opacity(0.8),
                         Color.orange.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all))
    }
}

struct DietScreen: View {
    let title: String
    var body: some View{
        ZStack{
            Text(title)
                .font(Font.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors:
                            [Color.yellow.opacity(0.7),
                             Color.green.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all))
            Button("Get Recommendation",
                   action: {printHello(text: title)})
            .frame(width: 300, height: 100)
            .font(.title)
            .foregroundColor(Color.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors:
                        [Color.green.opacity(0.7),
                         Color.yellow.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all))
            .cornerRadius(10)
        }
    }
}

struct DietRecommendationScreen: View {
    let title: String
    var body: some View{
        Text(title)
            .font(Font.system(size: 26, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors:
                        [Color.yellow.opacity(0.7),
                        Color.green.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all))

    }
}
    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SleepScreen_Previews: PreviewProvider {
    static var previews: some View {
        SleepScreen(title: "")
    }
}

struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigation()
    }
}
