//
//  ViewController.swift
//  mac_vpn_test2
//
//  Created by Citizen Star on 06.11.2019.
//  Copyright © 2019 256devs. All rights reserved.
//


import Cocoa
import NetworkExtension

class ViewController: NSViewController {
    
    @IBOutlet weak var progressParConection: NSProgressIndicator!
    @IBOutlet weak var statusConection: NSTextField!
    var fileURL: URL? = nil;
    var manager: NETunnelProviderManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager?.connection, queue: OperationQueue.main, using: { notification in
            self.statusConection.stringValue = self.manager?.connection.status.description ?? "..."
            self.statusConection.textColor = self.manager?.connection.status.color ?? NSColor.white
            self.progressParConection.startAnimation(self.manager?.connection.status.isConected ?? false)
            self.progressParConection.isHidden = self.manager?.connection.status.isConected ?? false
        })
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func selectFile(_ sender: Any) {
        let fileChooser: NSOpenPanel = NSOpenPanel()
        fileChooser.canChooseFiles = true
        fileChooser.runModal()
        fileURL = fileChooser.url
    }
    
    @IBAction func disconect(_ sender: Any) {
        self.manager?.connection.stopVPNTunnel()
    }
    
    @IBAction func establishVPNConnection(_ sender: Any) {
        let callback = { (error: Error?) -> Void in
            self.manager?.loadFromPreferences(completionHandler: { (error) in
                guard error == nil else {
                    print("\(error!.localizedDescription)")
                    return
                }
                
                /*let options: [String : NSObject] = [
                 "username": "freeopenvpn" as NSString,
                 "password": "819646439" as NSString
                 ]
                 */
                do {
                    //try self.manager?.connection.startVPNTunnel(options: options)
                    try self.manager?.connection.startVPNTunnel()
                } catch {
                    print("\(error.localizedDescription)")
                }
            })
        }
        if self.fileURL != nil{
            configureVPN(callback: callback)
        }else{
            statusConection.stringValue = "NO FILE SELECTED"
            statusConection.textColor = .white
        }
    }
    
}

extension ViewController {
    
    func configureVPN(callback: @escaping (Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            guard error == nil else {
                print("\(error!.localizedDescription)")
                callback(error)
                return
            }
            
            self.manager = managers?.first ?? NETunnelProviderManager()
            self.manager?.loadFromPreferences(completionHandler: { (error) in
                guard error == nil else {
                    print("\(error!.localizedDescription)")
                    callback(error)
                    return
                }
            
                let configurationContent = try! Data(contentsOf: self.fileURL!)
                
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.serverAddress = ""
                tunnelProtocol.providerBundleIdentifier = Bundle.main.bundleIdentifier
                tunnelProtocol.providerConfiguration = ["configuration": configurationContent]
                tunnelProtocol.disconnectOnSleep = false
                self.manager?.protocolConfiguration = tunnelProtocol
                self.manager?.localizedDescription = "OpenVPN macOS Client"
                
                self.manager?.isEnabled = true
                
                self.manager?.saveToPreferences(completionHandler: { (error) in
                    guard error == nil else {
                        print("\(error!.localizedDescription)")
                        callback(error)
                        return
                    }
                    
                    callback(nil)
                })
            })
        }
    }
    
}


extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            
        }
    }
    
}


extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .invalid: return "Invalid"
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnecting: return "Disconnecting"
        case .reasserting: return "Reconnecting"
        @unknown default:
            return "..."
        }
    }
    
    public var color: NSColor {
        switch self {
        case .disconnected: return .red
        case .invalid: return .red
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnecting: return .yellow
        case .reasserting: return .yellow
        @unknown default:
            return .white
        }
    }
    
    public var isConected: Bool {
        switch self {
        case .disconnected: return true
        case .invalid: return true
        case .connected: return true
        case .connecting: return false
        case .disconnecting: return false
        case .reasserting: return false
        @unknown default:
            return true
        }
    }
}
