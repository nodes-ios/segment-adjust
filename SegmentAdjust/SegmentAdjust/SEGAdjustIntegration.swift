//
//  SEGAdjustIntegration.swift
//  SegmentAdjust
//
//  Created by Todor Brachkov on 30/09/2016.
//  Copyright © 2016 Nodes. All rights reserved.
//

import UIKit
import Analytics
import AdjustSdk

open class SEGAdjustIntegration: NSObject, SEGIntegration {

    public var settings: [AnyHashable: Any]
    
    static var numberFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }
    
    init(_ settings: [AnyHashable: Any]) {

        self.settings = settings
        
        
        guard let appToken = settings["appToken"] as? String else {
            fatalError("ERROR: No app token provided.")
        }
        
        super.init()
        
        var environment = ADJEnvironmentSandbox
        if isEnvironmentProduction {
            environment = ADJEnvironmentProduction
        }
        
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)
        
        // Event buffering for network control
        if isEventBufferingEnabled {
            adjustConfig?.eventBufferingEnabled = true
        }
        
        Adjust.appDidLaunch(adjustConfig)
    }
    
    public class func extractRevenue(dictionary: [AnyHashable: Any], revenueKey: String) -> Double? {
        for case let key as String in dictionary.keys {
            if key.caseInsensitiveCompare(revenueKey) == .orderedSame {
                if let numberString = dictionary[key] as? String {
                    return numberFormatter.number(from: numberString) as Double?
                } else if let numberString = dictionary[key] as? Double {
                    return numberString
                }
            }
        }
        return nil
    }
    
    public class func extractCurrency(dictionary: [AnyHashable: Any], currencyKey: String) -> String? {
        for case let key as String in dictionary.keys {
            if key.caseInsensitiveCompare(currencyKey) == .orderedSame {
                if let currencyProperty = dictionary[key] as? String {
                    return currencyProperty
                }else {
                    return "USD"
                }
            }
        }
        return "USD"
    }
    
    public class func extractOrderId(dictionary: [AnyHashable: Any], orderIdKey: String) -> String? {
        for case let key as String in dictionary.keys {
            if key.caseInsensitiveCompare(orderIdKey) == .orderedSame {
                if let orderIdProperty = dictionary[key] as? String {
                    return orderIdProperty
                }else {
                    return nil
                }
            }
        }
        return nil
    }
  
    
    public func track(_ payload: SEGTrackPayload!) {
        
        guard  let token = getMappedCustomEventToken(event: payload.event) else {
            return
        }
        
        let event = ADJEvent(eventToken: token)
        
        // Iterate over all the properties and set them.
        for case let key as String in payload.properties.keys {
            let value = String("\(payload.properties[key])")
            event?.addCallbackParameter(key, value: value)
        }
        
        // Track revenue specifically
        let currency = SEGAdjustIntegration.extractCurrency(dictionary: payload.properties, currencyKey: "currency")
        if let revenue = SEGAdjustIntegration.extractRevenue(dictionary: payload.properties, revenueKey: "revenue") {
            event?.setRevenue(revenue, currency: currency)
        }

        // Deduplicate transactions with the orderId
        //    from https://segment.com/docs/spec/ecommerce/#completing-an-order
        
        if let orderId = SEGAdjustIntegration.extractOrderId(dictionary: payload.properties, orderIdKey: "orderId") {
            event?.setTransactionId(orderId)
        }
        
        Adjust.trackEvent(event)
    }
    
    public func registeredForRemoteNotifications(withDeviceToken deviceToken: Data!) {
        Adjust().setDeviceToken(deviceToken)
    }

    func getMappedCustomEventToken(event: String) -> String? {
        guard let tokens: [AnyHashable: Any] = settings["customEvents"] as? [AnyHashable : Any] else {
            return nil
        }
        if let token = tokens[event] as? String {
            return token
        }
        return nil
    }
    
    fileprivate var isEventBufferingEnabled: Bool {
        return settings["setEventBufferingEnabled"] as? Bool ?? false
    }
    
    fileprivate var isEnvironmentProduction: Bool {
        return settings["setEnvironmentProduction"] as? Bool ?? false
    }
}

