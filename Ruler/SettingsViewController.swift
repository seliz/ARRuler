//
//  Settings.swift
//  Ruler
//
//  Created by Seliz Kaya on 8/1/17.
//  Copyright © 2017 Seliz Kaya. All rights reserved.
//

import Foundation
import UIKit

enum Setting: String {
    // Bool settings with SettingsViewController switches
    case debugMode
    case ambientLightEstimation
    case dragOnInfinitePlanes
    
    
    // Integer state used in virtual object picker
    case selectedObjectID
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Setting.ambientLightEstimation.rawValue: true,
            Setting.dragOnInfinitePlanes.rawValue: true,
            Setting.selectedObjectID.rawValue: -1
            ])
    }
}
extension UserDefaults {
    func bool(for setting: Setting) -> Bool {
        return bool(forKey: setting.rawValue)
    }
    func set(_ bool: Bool, for setting: Setting) {
        set(bool, forKey: setting.rawValue)
    }
    func integer(for setting: Setting) -> Int {
        return integer(forKey: setting.rawValue)
    }
    func set(_ integer: Int, for setting: Setting) {
        set(integer, forKey: setting.rawValue)
    }
}

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var debugModeSwitch: UISwitch!
    @IBOutlet weak var scaleWithPinchGestureSwitch: UISwitch!
    @IBOutlet weak var ambientLightEstimateSwitch: UISwitch!
    @IBOutlet weak var dragOnInfinitePlanesSwitch: UISwitch!
    @IBOutlet weak var showHitTestAPISwitch: UISwitch!
    @IBOutlet weak var use3DOFTrackingSwitch: UISwitch!
    @IBOutlet weak var useAuto3DOFFallbackSwitch: UISwitch!
    @IBOutlet weak var useOcclusionPlanesSwitch: UISwitch!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateSettings()
    }
    
    @IBAction func didChangeSetting(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        switch sender {
        case debugModeSwitch:
            defaults.set(sender.isOn, for: .debugMode)
        case ambientLightEstimateSwitch:
            defaults.set(sender.isOn, for: .ambientLightEstimation)
        case dragOnInfinitePlanesSwitch:
            defaults.set(sender.isOn, for: .dragOnInfinitePlanes)
        default: break
        }
    }
    
    private func populateSettings() {
        let defaults = UserDefaults.standard
        
        debugModeSwitch.isOn = defaults.bool(for: Setting.debugMode)
        ambientLightEstimateSwitch.isOn = defaults.bool(for: .ambientLightEstimation)
        dragOnInfinitePlanesSwitch.isOn = defaults.bool(for: .dragOnInfinitePlanes)
    }
}
