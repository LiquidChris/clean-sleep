//
//  dietPredictor.swift
//  Sleep-clean
//
//  Created by slmrc on 6/9/23.
//

import Foundation
import CoreML


// Step 2: Load the ML model
func makeRecipePrediction(userSelection: String) {
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
}
    // Once recipe id is found, cross reference with RAW_recipe.csv to display recipe_name + ingredients.


// Example usage
//makeRecipePrediction(userSelection: "medium")
