//
//  Broswer.swift
//  awdl_NW
//
//  Created by junjiecui on 2026/3/31.
//

import Network
import os.log

class Browser {
    private let serviceName: String = "awdl_cjj"
    private let serviceType: String = "_wechat-chatlog._tcp"
    private let serviceDomain: String = "local."
    
    private var browser: NWBrowser?
    private let logger = Logger(subsystem: "com.awdl.browser", category: "Browser")
    
    init() {
        
    }
    
    func startScanning() {
        let bonjourDescriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: serviceDomain)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        parameters.requiredInterfaceType = .wifi
                
        // 创建浏览器实例
        browser = NWBrowser(for: bonjourDescriptor, using: parameters)
        
        browser?.stateUpdateHandler = {[weak self] state in
            switch state {
            case .ready:
                self?.logger.info("Browser is ready")
            case .failed:
                self?.logger.error("Browser failed")
            case .cancelled:
                self?.logger.info("Browser cancelled")
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = {[weak self] newResults, changedResults in
            self?.logger.info("Browse results changed")
        }
        
        logger.info("Start scanning")
        browser?.start(queue: .main)
    }
    
    func stopScanning() {
        browser?.cancel()
        browser = nil
        logger.info("Stop scanning")
    }
}
