import Foundation
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
            }
            .padding()
        }
    }
}
public var sleepQuality = -1.0
struct ContentView: View {
    @State private var questions: [Question] = [
        Question(text: "What's your gender? (0 for Male, 1 for Female)"),
        Question(text: "What's your age?"),
        Question(text: "How many hours of sleep do you get on average?"),
        Question(text: "On a scale of 1-10, how would you rate your physical activity level?"),
        Question(text: "On a scale of 1-10, how would you rate your stress level?"),
        Question(text: "Do you have any sleep disorders? (0 for No, 1 for Yes)")
    ]
    
    let sleepRegressor = SleepRegressor_2()
    
    private let answersKey = "answers"
    @State private var selectedMenuItem: String?
    @State private var currentQuestionIndex = 0
    @State private var answers: [UUID: String] = UserDefaults.standard.dictionary(forKey: "answers") as? [UUID: String] ?? [:]
    @State private var isQuestionnaireComplete = false
    @State private var isQuestionnaireStarted = false
    @State private var timeToNotSubmit = true
    @State private var predictionOutput: Double?
    @StateObject private var healthDataFetcher = HealthDataFetcher()
    
    // Load answers from UserDefaults
    init() {
        if let storedAnswers = UserDefaults.standard.dictionary(forKey: answersKey) as? [String: String] {
            self._answers = State(initialValue: convertToUUIDKeys(dictionary: storedAnswers))
        }
    }
    private func convertToUUIDKeys(dictionary: [String: String]) -> [UUID: String] {
        var convertedDictionary: [UUID: String] = [:]
        for (key, value) in dictionary {
            if let uuidKey = UUID(uuidString: key) {
                convertedDictionary[uuidKey] = value
            }
        }
        return convertedDictionary
    }
    var currentQuestion: Question? {
        if currentQuestionIndex < questions.count {
            return questions[currentQuestionIndex]
        }
        return nil
    }
    
    var body: some View {
        let question = questions[currentQuestionIndex]
        if isQuestionnaireComplete {
            SidebarNavigation(selectedMenuItem: $selectedMenuItem, answers: $answers, sleepScreenAnswers: $answers)
        } else if isQuestionnaireStarted {
            if currentQuestionIndex < questions.count && timeToNotSubmit {
                QuestionPromptView(question: question, answer: $answers[question.id], onNextQuestion: moveNextQuestion)
            } else {
                SubmitView(isComplete: $isQuestionnaireComplete, onCompletion: {
                    sleepQuality = makePrediction() ?? -1.0
                })
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
            
            // Convert UUID keys to strings before storing in UserDefaults
            var answersStringKeys: [String: String] = [:]
            for (key, value) in answers {
                answersStringKeys[key.uuidString] = value
            }
            
            // Save answers to UserDefaults
            UserDefaults.standard.set(answersStringKeys, forKey: answersKey)
        }
    }
    
    func makePrediction() -> Double? {
        print("makePrediction() called")
        for i in 0..<questions.count {
            if let answer = answers[questions[i].id] {
                print("Question: \(questions[i].id), Answer: \(answer)")
            }
//                else {
//                print("No answer for question \(questions[i].id)")
//            }
        }
        
        guard let gender = Double(answers[questions[0].id] ?? ""),
              let age = Double(answers[questions[1].id] ?? ""),
              let sleepDuration = Double(answers[questions[2].id] ?? ""),
              let physicalActivityLevel = Double(answers[questions[3].id] ?? ""),
              let stressLevel = Double(answers[questions[4].id] ?? ""),
              let sleepDisorder = Double(answers[questions[5].id] ?? "") else {
            print("Failed to convert data to Double")
            return nil
        }
        
        print("Data converted to Double successfully")
        
        let input = SleepRegressor_2Input(Gender: gender,
                                          Age: age,
                                          Sleep_Duration: sleepDuration,
                                          Physical_Activity_Level: physicalActivityLevel,
                                          Stress_Level: stressLevel,
                                          Sleep_Disorder: sleepDisorder)
        
        print("Input instance created successfully")
        
        do {
            let prediction = try sleepRegressor.prediction(input: input)
            let qualityOfSleep = prediction.Quality_of_Sleep
            
            print("Prediction made successfully")
            print("Quality of Sleep prediction: \(qualityOfSleep)")
            return qualityOfSleep
        } catch {
            print("Error making prediction: \(error)")
            return nil
        }
    }
}
struct SubmitView: View {
    @Binding var isComplete: Bool
    let onCompletion: () -> Void
    
    var body: some View {
        VStack {
            Text("Thank you for your answers!")
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
            
            Button(action: {
                isComplete = true
                onCompletion()
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
struct QuestionPromptView: View {
    let question: Question
    @Binding var answer: String?
    let onNextQuestion: () -> Void
    
    var body: some View {
        VStack {
            Text(question.text)
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
            
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
struct SidebarNavigation: View {
    @Binding var selectedMenuItem: String?
    @Binding var answers: [UUID: String]
    @Binding var sleepScreenAnswers: [UUID: String]
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SleepScreen(title: "Recommendation", answers: $sleepScreenAnswers), tag: "Sleep", selection: $selectedMenuItem) {
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
struct SleepScreen: View {
    let title: String
    @Binding var answers: [UUID: String]
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
//                        sleepPrediction = ContentView().makePrediction() // Updated line
                        print(sleepQuality)
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
                
                NavigationLink(destination: SleepRecommendationScreen(title: "Sleep quality: ", prediction: sleepQuality), isActive: $isActive) {
                    EmptyView()
                }
            }
        }
    }
}
struct SleepRecommendationScreen: View {
    let title: String
    let prediction: Double
//    let sleepPrediction: Double?
    
    var body: some View {
        VStack {
            Text(title)
                .font(Font.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            
            if (prediction < 1){
                
            }
            else if (prediction < 3){
                Text("Set a time to go to bed and wake up and stick to it for the next week.\n Avoid electronic screens for 30 minutes prior to sleep.\n Avoid napping throughout the day.")
            }
            else if (prediction < 6){
                Text("Try going to sleep 30 minutes earlier and waking up 30 minutes earlier. Set alarms and schedule your sleep to get 7 hours a day.")
            }
            else if (prediction < 9) {
                Text("Listen to slow, relaxing music while lying down above blanket before bed. Make sure your sleep posture is not crooked or bent in any way.")
            }
            else {
                Text("Your current sleep habits are amazing! Make sure to stay hydrated throughout the day.")
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
        ZStack {
            Button("Get Recommendation", action: {
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
                //                Text("Prediction Output: \(predictionOutput)")
                if predictionOutput < 5 {
                    Text("Exercise 30 minutes a day.")
                }
                else {
                    Text("Your're already getting a great workout, so checkout this website for more information!\nhttps://time.com/4237126/13-ways-to-get-the-most-out-of-your-workout-according-to-research/")
                        .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .edgesIgnoringSafeArea(.all))
                }
            }
        }
    }
}
struct DietScreen: View {
    let title: String
    @State private var isActive: Bool = false
    @State private var dietPrediction: Double?
    
    var body: some View {
        ZStack {
            VStack{
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
                Button("Tap me for a recommendation") {
                    isActive = true
                    dietPrediction = makeRecipePrediction(userSelection: "medium") // Updated line
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
            
            NavigationLink(destination: DietRecommendationScreen(title: title, dietPrediction: dietPrediction), isActive: $isActive) {
                EmptyView()
            }
            
        }
    }
    
    func makeRecipePrediction(userSelection: String) -> Double {
        guard let model = try? dietregression_1(configuration: MLModelConfiguration()) else {
            fatalError("Failed to load the ML model.")
        }
        
        // Step 3: Preprocess user selection
        func preprocessUserSelection(_ selection: String) -> Int {
            switch selection {
            case "easy":
                return 4
            case "medium":
                return 8
            case "hard":
                return 11
            default:
                return 0
            }
        }
        
        let steps = preprocessUserSelection(userSelection)
        let ingredients = preprocessUserSelection(userSelection)
        let minutes = 30
        
        // Step 4: Perform the prediction
        let input = dietregression_1Input(minutes: Double(minutes), n_steps: Double(steps), n_ingredients: Double(ingredients))
        
        guard let prediction = try? model.prediction(input: input) else {
            fatalError("Failed to make a prediction.")
        }
        
        // Step 5: Postprocess and display the result
        let predictedRecipeID = prediction.recipe_id
        print("Predicted Recipe ID: \(predictedRecipeID)")
        return predictedRecipeID
    }
}
struct DietRecommendationScreen: View {
    let title: String
    let dietPrediction: Double?
    
    var body: some View {
        VStack {
            Text(title)
                .font(Font.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center).frame(
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
            if let dietPrediction = dietPrediction {
                Text("Diet Prediction: \(dietPrediction)")
            }
                
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
struct SleepScreen_Previews: PreviewProvider {
    static var previews: some View {
        SleepScreen(title: "Recommendation", answers: .constant([:]))
    }
}
struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
        SidebarNavigation(selectedMenuItem: .constant(nil), answers: .constant([:]), sleepScreenAnswers: .constant([:]))
    }
}
//struct DietScreen: View {
//    let title: String
//    var body: some View {
//        ZStack {
 //           Text(title)
   //             .font(Font.system(size: 26, weight: .bold))
   //             .multilineTextAlignment(.center)
  //              .frame(
     //               maxWidth: .infinity,
     //               maxHeight: .infinity)
      //          .background(
       //             LinearGradient(
       //                 gradient: Gradient(colors:
       //                                     [Color.yellow.opacity(0.7),
        //                                     Color.green.opacity(0.8)]),
        //                startPoint: .topLeading,
       //                 endPoint: .bottomTrailing)
       //             .edgesIgnoringSafeArea(.all))
        //        else {
       //             Text("Do 3 sets of 5 reps using 75% of the maximum weight you can for: Squats, Deadlift, and Benchpress. Rest 2-3 minutes between sets.")
       //         }
       //     }
      //  }
      //  .frame(maxWidth: .infinity, maxHeight: .infinity)
      //  .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)]), startPoint: .topLeading, endPoint: //.bottomTrailing)
     //       .edgesIgnoringSafeArea(.all))
   // }
//}

