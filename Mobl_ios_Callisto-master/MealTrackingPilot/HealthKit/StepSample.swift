//
//  StepSample.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/9/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import HealthKit
import Realm
import RealmSwift

protocol StepSample {
    var steps: Int { get }
    var startDate: Date { get }
    var endDate: Date { get }

    var json: [String : Any]? { get }
}

protocol HKStatisticsProtocol {
    var startDate: Date { get }
    var endDate: Date { get }
    func sumQuantity() -> HKQuantity?
}

extension HKStatistics: HKStatisticsProtocol {}

final class RealmStepSample: RealmSwift.Object, StepSample, Codable {

    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var steps: Int = 0
    @objc dynamic var startDate: Date = Date()
    @objc dynamic var endDate: Date = Date()

    enum CodingKeys: String, CodingKey {
        case steps
        case startDate = "started_at"
        case endDate = "ended_at"
    }

    convenience init(sample: HKQuantitySample) {
        self.init()
        localIdentifier = sample.uuid.uuidString
        steps = Int(sample.quantity.doubleValue(for: HKUnit.count()))
        startDate = sample.startDate
        endDate = sample.endDate
    }

    convenience init?(sumStatistics: HKStatisticsProtocol) {
        guard let sumQuantity = sumStatistics.sumQuantity() else { return nil }

        self.init()
        localIdentifier = NSUUID().uuidString
        steps = Int(sumQuantity.doubleValue(for: HKUnit.count()))
        startDate = sumStatistics.startDate
        endDate = sumStatistics.endDate
    }

    override public class func primaryKey() -> String? {
        return "localIdentifier"
    }

    var json: [String : Any]? {
        let jsonEncoder = JSONEncoder.CallistoJSONEncoder()
        do {
            let data = try jsonEncoder.encode(self)
            if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                return ["healthkit_sample" : json]
            }
        } catch {
            print(error)
        }
        return nil
    }
}
