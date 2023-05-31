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
    private var model: MLModel?
    
    init() {
        if let modelPath = Bundle.main.url(forResource: "YourModel", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: modelPath)
        }
    }
    
    func collectDataAndPredict() {
        // Request authorization for the required data types
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { (success, error) in
            guard success else {
                print("HealthKit authorization failed")
                return
            }
            
            // Authorization successful, fetch data and make prediction
            do {
                let biologicalSex = try self.healthStore.biologicalSex().biologicalSex
                let dateOfBirth = try self.healthStore.dateOfBirthComponents().date
                let height = self.getMostRecentSample(for: .height)
                let weight = self.getMostRecentSample(for: .bodyMass)
                let stepCount = self.getMostRecentSample(for: .stepCount)
                let heartRate = self.getMostRecentSample(for: .heartRate)
                let activeEnergy = self.getMostRecentSample(for: .activeEnergyBurned)
                let distance = self.getMostRecentSample(for: .distanceWalkingRunning)
                
                let age = Calendar.current.dateComponents([.year], from: dateOfBirth!, to: Date()).year!
                
                let inputArray = try MLMultiArray(shape: [8], dataType: .double)
                inputArray[0] = NSNumber(value: age)
                inputArray[1] = NSNumber(value: biologicalSex.rawValue)
                inputArray[2] = NSNumber(value: height)
                inputArray[3] = NSNumber(value: weight)
                inputArray[4] = NSNumber(value: stepCount)
                inputArray[5] = NSNumber(value: heartRate)
                inputArray[6] = NSNumber(value: activeEnergy)
                inputArray[7] = NSNumber(value: distance)
                
                if let predictionOutput = try? self.model?.prediction(from: inputArray) {
                    print("Prediction Output: \(predictionOutput)")
                }
            } catch {
                print("Error fetching data or making prediction: \(error)")
            }
        }
    }
    
    private func getMostRecentSample(for type: HKQuantityTypeIdentifier) -> Double {
        let sampleType = HKQuantityType.quantityType(forIdentifier: type)!
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                print("Failed to fetch samples for \(type)")
                return
            }
            return mostRecentSample.quantity.doubleValue(for: HKUnit.count())
        }
        healthStore.execute(query)
    }
}


//Replace "YourModel" with the name of your model, and adjust the MLMultiArray shape and indexing according to the expected input for your model.
