//
//  UserDefaults+Orangered.swift
//  Orangered
//
//  Created by Alan Westbrook on 6/13/16.
//  Copyright © 2016 Voidref Software. All rights reserved.
//

import Foundation
import Cocoa

private let kUserNameKey = "username"
private let kServiceName = "Orangered!"

extension UserDefaults {
    var username:String? { 
        get {
            return string(forKey: kUserNameKey)
        }
        set {
            set(newValue, forKey: kUserNameKey)
        }
    }
    
    var password:String? {
        get {
            let pass = getPassword()
            UserDefaults.keychainItem = nil
            return pass
        }
        set {
            setPassword(newValue!)
        }
    }
    
    // C APIs are *the worst*
    static private var keychainItem:SecKeychainItem? = nil
    
    private func getPassword() -> String? {
        
        guard let uname = username else {
            print("no user name set")
            return nil
        }
        
        var passwordLength:UInt32 = 0
        var passwordData:UnsafeMutablePointer<Void>? = nil
        
        let err = SecKeychainFindGenericPassword(nil, 
                                                 UInt32(kServiceName.characters.count), 
                                                 kServiceName, 
                                                 UInt32(uname.characters.count), 
                                                 uname, 
                                                 &passwordLength, 
                                                 &passwordData, 
                                                 &UserDefaults.keychainItem)
        if let pass = passwordData where err == errSecSuccess {
            let password = String(bytesNoCopy: pass, length: Int(passwordLength), encoding: String.Encoding.utf8, freeWhenDone: true)
            return password
        }
        else {
            print("Error grabbing password: \(err)")
        }
        
        return nil
    }
    
    private func setPassword(_ pass:String) {
        guard let uname = username else {
            print("No username")
            return
        }
        
        if let _ = getPassword() {
            // have to update instead of setting
            updatePassword(pass)
            return
        }
        
        let result =  SecKeychainAddGenericPassword(nil, 
                                                    UInt32(kServiceName.characters.count), 
                                                    kServiceName, 
                                                    UInt32(uname.characters.count), 
                                                    uname, 
                                                    UInt32(pass.characters.count), 
                                                    pass, 
                                                    nil)
        
        if result != errSecSuccess {
            print("error setting key: \(result)")
        }
    }
    
    private func updatePassword(_ password:String) {
        guard let itemActual = UserDefaults.keychainItem else {
            print("Must grab a password to init the item before updatint it, bleah")
            return
        }
        
        let result = SecKeychainItemModifyAttributesAndData(itemActual, 
                                                            nil, 
                                                            UInt32(password.characters.count), 
                                                            password)
        
        if result != errSecSuccess {
            print("error updating the keychain: \(result)")
        }
        
        UserDefaults.keychainItem = nil
    }
}
