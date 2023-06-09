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
        .padding()
    }
}
}

struct ContentView: View {
    
    
    @State private var questions: [Question] = [
        Question(text: "What is your sex? \n(Male: 0, Female: 1)"),
        Question(text: "What is your age?"),
        Question(text: "How many hours of sleep do you get on average?"),
        Question(text: "How many hours of exercise do get in an average day?"),
        Question(text: "Rate your level of stress from 1-10? \n(low stress: 1, high stress: 10)"),
        Question(text: "Do you have a sleep disorder? \n(N/A: 0, Sleep Apnea: 1, Insomnia: 2)")
    ]
    
    let sleepRegressor = SleepRegressor_2()
    
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
            if currentQuestionIndex < questions.count && timeToNotSubmit {
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
            makePrediction()
            timeToNotSubmit = false
        }
    }
    
    func makePrediction() {
        // Prepare input features for the model
        guard let genderString = answers[questions[0].id],
              let ageString = answers[questions[1].id],
              let sleepDurationString = answers[questions[2].id],
              let physicalActivityLevelString = answers[questions[3].id],
              let stressLevelString = answers[questions[4].id],
              let sleepDisorderString = answers[questions[5].id],
              let gender = convertGenderToDouble(genderString),
              let age = Double(ageString),
              let sleepDuration = Double(sleepDurationString),
              let physicalActivityLevel = Double(physicalActivityLevelString),
              let stressLevel = Double(stressLevelString),
              let sleepDisorder = Double(sleepDisorderString) else {
            return
        }
        
        // Create an instance of the SleepRegressor_2Input struct
        let input = SleepRegressor_2Input(Gender: gender,
                                          Age: age,
                                          Sleep_Duration: sleepDuration,
                                          Physical_Activity_Level: physicalActivityLevel,
                                          Stress_Level: stressLevel,
                                          Sleep_Disorder: sleepDisorder)
        
        // Make the prediction
        do {
            let prediction = try sleepRegressor.prediction(input: input)
            let qualityOfSleep = prediction.Quality_of_Sleep
            
            // Do something with the qualityOfSleep prediction value
            // For example, show it on the screen or pass it to another view
            // You can use `qualityOfSleep` as needed in your app
            print("Quality of Sleep: \(qualityOfSleep)")
        } catch {
            print("Error making prediction: \(error)")
        }
    }

    func convertGenderToDouble(_ gender: String) -> Double? {
        switch gender {
        case "Male":
            return 0.0
        case "Female":
            return 1.0
        // Handle other gender categories if necessary
        default:
            return nil
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
    @State var selectedMenuItem: String? = nil
    var body: some View {
        NavigationView {
            List {
                //                    NavigationLink(isActive: $isShowingDetailView, destination: SleepRecommendationScreen(title: ""), tag: "Sleep", selection: $selectedMenuItem) {
                //                        Label("Sleep", systemImage: "powersleep")
                //                    }
                NavigationLink(destination: SleepScreen(title: "Recommendation"), tag: "Sleep", selection: $selectedMenuItem) {
                    Label("Sleep", systemImage: "powersleep")
                }
                NavigationLink(destination: ExerciseScreen(title: "Recommendation"), tag: "Exercise", selection: $selectedMenuItem) {
                    Label("Exercise", systemImage: "figure.run")
                }
                NavigationLink(destination: DietScreen(title: "Implementation Coming Soon"), tag: "Diet", selection: $selectedMenuItem) {
                    Label("Diet", systemImage: "fork.knife")
                }
                
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Wellness Options")
            .multilineTextAlignment(.center)
        }
    }
}

func printHello(text: String){
    print(text)
}


struct SleepScreen: View {
let title: String
@State private var isActive: Bool = false
@State private var sleepPrediction: Double?

var body: some View {
    NavigationView {
        VStack {
            ZStack {
                Text("")
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
                Button("Tap me for a recommendation") {
                    isActive = true
                }
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
            
            NavigationLink(destination: SleepRecommendationScreen(title: title, sleepPrediction: sleepPrediction), isActive: $isActive) {
                EmptyView()
            }
            
            Button("Sleep") {
                ContentView().makePrediction()                }
            .font(.headline)
            .padding()
            .background(Color.mint)
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .padding()
        }
    }
}
}

struct SleepRecommendationScreen: View {
let title: String
let sleepPrediction: Double?

var body: some View {
    VStack {
        Text(title)
            .font(Font.system(size: 26, weight: .bold))
            .multilineTextAlignment(.center)
        
        if let sleepPrediction = sleepPrediction {
            Text("Sleep Prediction: \(sleepPrediction)")
        }
    }
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
    @StateObject var healthDataFetcher = HealthDataFetcher()
    @State private var showRecommendation = false
    
    var body: some View {
        ZStack{
            // ... other view code omitted for brevity
            Button("Get Recommendation",
                   action: {
                healthDataFetcher.requestHealthDataAccess()
                showRecommendation = true
            })
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
            .sheet(isPresented: $showRecommendation) {
                ExerciseRecommendationScreen(healthDataFetcher: healthDataFetcher)
            }
        }
    }
}
struct ExerciseRecommendationScreen: View {
    @ObservedObject var healthDataFetcher: HealthDataFetcher
    
    var body: some View {
        VStack {
            Text("Recommendations")
                .font(Font.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            if let predictionOutput = healthDataFetcher.predictionOutput {
                Text("Prediction Output: \(predictionOutput)")
                if predictionOutput < 10 {
                    Text("Exercise 30 minutes a day")
                }
                else {
                    Text("Do 3 sets of 5 reps using 75% of the maximum weight you can for: Squats, Deadlift, and Benchpress. Rest 2-3 minutes between sets.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
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
            
        }
    }
}





//struct DietRecommendationScreen: View {
//    let title: String
//    var body: some View{
//        Text(title)
//            .font(Font.system(size: 26, weight: .bold))
//            .multilineTextAlignment(.center)
//            .frame(
//                maxWidth: .infinity,
//                maxHeight: .infinity)
//            .background(
//                LinearGradient(
//                    gradient: Gradient(colors:
//                        [Color.yellow.opacity(0.7),
//                        Color.green.opacity(0.8)]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing)
//                .edgesIgnoringSafeArea(.all))
//
//    }
//}

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

