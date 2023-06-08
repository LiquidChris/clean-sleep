//
//  collector.swift
//  Sleep-clean
//
//  Created by Iyad Hassan on 5/30/23.
//

import Foundation
import HealthKit
import CoreML

class HealthDataFetcher : ObservableObject {
    @Published var predictionOutput: Double?
    let healthStore = HKHealthStore()
    var model: applewatchregression_1?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            // Load the CoreML Model
            if let modelURL = Bundle.main.url(forResource: "applewatchregression_1", withExtension: "mlmodelc") {
                do {
                    let model = try applewatchregression_1(contentsOf: modelURL)
                    self.model = model
                } catch {
                    print("Error loading model: \(error)")
                }
            }
        }
    }

    func requestHealthDataAccess() {
        let healthKitTypes: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (success, error) in
            if success {
                self.fetchHealthDataAndMakePrediction()
            } else if let error = error {
                print("Error requesting health data access: \(error)")
            }
        }
    }

    func fetchHealthDataAndMakePrediction() {
        do {
            let ageComponents = try healthStore.dateOfBirthComponents()
            let biologicalSex = try healthStore.biologicalSex().biologicalSex.rawValue

            let age = Calendar.current.dateComponents([.year], from: ageComponents.date!, to: Date()).year!
            
            var height: Double?
            var weight: Double?
            var stepCount: Double?
            var heartRate: Double?
            var distance: Double?
            
            let group = DispatchGroup()

            group.enter()
            self.getMostRecentSample(for: .height) { result in
                if let result = result {
                    height = result
                } else {
                    print("Failed to fetch height data")
                }
                group.leave()
            }

            group.enter()
            self.getMostRecentSample(for: .bodyMass) { result in
                if let result = result {
                    weight = result
                } else {
                    print("Failed to fetch weight data")
                }
                group.leave()
            }
            
            group.enter()
            self.getMostRecentSample(for: .stepCount) { result in
                if let result = result {
                    stepCount = result
                } else {
                    print("Failed to fetch step count data")
                }
                group.leave()
            }
            
            group.enter()
            self.getMostRecentSample(for: .heartRate) { result in
                if let result = result {
                    heartRate = result
                } else {
                    print("Failed to fetch heart rate data")
                }
                group.leave()
            }
            
            group.enter()
            self.getMostRecentSample(for: .distanceWalkingRunning) { result in
                if let result = result {
                    distance = result
                } else {
                    print("Failed to fetch distance data")
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                if let height = height, let weight = weight, let stepCount = stepCount, let heartRate = heartRate, let distance = distance {
                    let stepsXDistance = stepCount * distance
                    
                    let inputData = applewatchregression_1Input(age: Double(age), gender: Double(biologicalSex), height: height, weight: weight, Applewatch_Steps_LE: stepCount, Applewatch_Heart_LE: heartRate, Applewatch_Distance_LE: distance, ApplewatchStepsXDistance_LE: stepsXDistance)
                    
                    if let predictionOutput = try? self.model?.prediction(input: inputData) {
                        DispatchQueue.main.async {
                            self.predictionOutput = predictionOutput.Applewatch_Calories_LE
                        }
                    }
                }
            }
        } catch {
            print("Error fetching health data: \(error)")
        }
    }


    private func getMostRecentSample(for sampleType: HKQuantityTypeIdentifier, completion: @escaping (Double?) -> Void) {
        let sampleType = HKQuantityType.quantityType(forIdentifier: sampleType)!
        
        // Remove the predicate that limits the date range
        let predicate: NSPredicate? = nil
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (_, results, error) in
            if let error = error {
                print("Error fetching samples for \(sampleType): \(error)")
                completion(nil)
                return
            }
            
            guard let results = results, let mostRecentSample = results.first as? HKQuantitySample else {
                print("No data available for \(sampleType)")
                completion(nil)
                return
            }
            
            let value = mostRecentSample.quantity.doubleValue(for: self.unitForType(sampleType))
            completion(value)
        }
        
        healthStore.execute(query)
    }

    private func unitForType(_ type: HKQuantityType) -> HKUnit {
        switch type {
        case HKObjectType.quantityType(forIdentifier: .height)!:
            return HKUnit.meter()
        case HKObjectType.quantityType(forIdentifier: .bodyMass)!:
            return HKUnit.gramUnit(with: .kilo) // correct usage for kilograms
        case HKObjectType.quantityType(forIdentifier: .stepCount)!:
            return HKUnit.count()
        case HKObjectType.quantityType(forIdentifier: .heartRate)!:
            return HKUnit.count().unitDivided(by: HKUnit.minute()) // correct usage for heart rate in beats per minute
        case HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!:
            return HKUnit.meter()
        default:
            fatalError("Unsupported type")
        }
    }

}
