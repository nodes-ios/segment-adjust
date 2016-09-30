//
//  SEGAdjustIntegrationFactory.swift
//  SegmentAdjust
//
//  Created by Todor Brachkov on 30/09/2016.
//  Copyright © 2016 Nodes. All rights reserved.
//

import UIKit
import Analytics

open class SEGAdjustIntegrationFactory: NSObject, SEGIntegrationFactory {
    
    static let sharedInstance = SEGAdjustIntegrationFactory()
    
    private override init() {}
    
    public func create(withSettings settings: [AnyHashable : Any]!, for analytics: SEGAnalytics!) -> SEGIntegration! {
        return SEGAdjustIntegration(settings)
    }

    public func key() -> String {
        return "Adjust"
    }
}
