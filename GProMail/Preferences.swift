//
//  Util.swift
//  gInbox
//
//  Created by Chen Asraf on 11/11/14.
//  Copyright (c) 2014 Chen Asraf. All rights reserved.
//

import Foundation

class Preferences {
    
    class func getDefaults() -> UserDefaults {
        return UserDefaults.standard
    }
    
    class func clearDefaults() -> Void {
        guard let path = Bundle.main.path(forResource: "Defaults", ofType: "plist"),
              let dic = NSDictionary(contentsOfFile: path) as? [String: Any],
              let productIdentifier = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String else {
            return
        }
        
        getDefaults().removePersistentDomain(forName: productIdentifier)
        getDefaults().register(defaults: dic)
    }
    
    class func getInt(key: String) -> Int {
        return getDefaults().integer(forKey: key)
    }
    
    class func getString(key: String) -> String? {
        return getDefaults().string(forKey: key)
    }
    
    class func getFloat(key: String) -> Float {
        return getDefaults().float(forKey: key)
    }
    
    class func getBool(key: String) -> Bool {
        return getDefaults().bool(forKey: key)
    }
    
    class func setString(key: String, value: String) {
        getDefaults().set(value, forKey: key)
        getDefaults().synchronize()
    }
    
}