//
//  collector.swift
//  Sleep-clean
//
//  Created by Iyad Hassan on 5/30/23.
//

import Foundation
import HealthKit
import CoreML

class HealthDataCollector {
    private let healthStore = HKHealthStore()
    private var model: applewatchregression_1?
    
    init() {
        if let modelPath = Bundle.main.url(forResource: "applewatchregression_1", withExtension: "mlmodelc") {
            model = try? applewatchregression_1(contentsOf: modelPath)
        }
    }
    
    func collectDataAndPredict() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { (success, error) in
            guard success else {
                print("HealthKit authorization failed")
                return
            }
            
            do {
                let biologicalSex = try self.healthStore.biologicalSex().biologicalSex.rawValue
                let dateOfBirth = try self.healthStore.dateOfBirthComponents().date
                
                let age = Calendar.current.dateComponents([.year], from: dateOfBirth!, to: Date()).year!
                
                let group = DispatchGroup()
                var height: Double? = nil
                var weight: Double? = nil
                var stepCount: Double? = nil
                var heartRate: Double? = nil
                var distance: Double? = nil
                
                group.enter()
                self.getMostRecentSample(for: .height) { result in
                    height = result
                    group.leave()
                }
                
                group.enter()
                self.getMostRecentSample(for: .bodyMass) { result in
                    weight = result
                    group.leave()
                }
                
                group.enter()
                self.getMostRecentSample(for: .stepCount) { result in
                    stepCount = result
                    group.leave()
                }
                
                group.enter()
                self.getMostRecentSample(for: .heartRate) { result in
                    heartRate = result
                    group.leave()
                }
                
                group.enter()
                self.getMostRecentSample(for: .distanceWalkingRunning) { result in
                    distance = result
                    group.leave()
                }
                
                group.notify(queue: .main) {
                    guard let height = height, let weight = weight, let stepCount = stepCount, let heartRate = heartRate, let distance = distance else {
                        print("Failed to fetch some data")
                        return
                    }
                    
                    let activityTrimmed = 0.0 // Assume you have a way to determine activity_trimmed
                    
                    let stepsXDistance = stepCount * distance
                    
                    let inputData = applewatchregression_1Input(Age: Double(age), Gender: Double(biologicalSex), Height: height, Weight: weight, Applewatch_Steps_LE: stepCount, Applewatch_Heart_LE: heartRate, Applewatch_Distance_LE: distance)
                    
                    if let predictionOutput = try? self.model?.prediction(input: inputData) {
                        print("Prediction Output: \(predictionOutput)")
                    }
                }
            } catch {
                print("Error fetching data or making prediction: \(error)")
            }
        }
    }
    
    private func getMostRecentSample(for type: HKQuantityTypeIdentifier, completion: @escaping (Double?) -> Void) {
        let sampleType = HKQuantityType.quantityType(forIdentifier: type)!
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                print("Failed to fetch samples for \(type)")
                completion(nil)
                return
            }
            let unit: HKUnit
            switch type {
            case .height:
                unit = HKUnit.meter()
            case .bodyMass:
                unit = HKUnit.gramUnit(with: .kilo)
            case .stepCount, .distanceWalkingRunning:
                unit = HKUnit.count()
            case .heartRate:
                unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            default:
                print("Unknown quantity type \(type)")
                return
            }
            let value = mostRecentSample.quantity.doubleValue(for: unit)
            completion(value)
        }
        healthStore.execute(query)
    }
}
