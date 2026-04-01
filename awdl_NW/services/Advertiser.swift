//
//  Advertiser.swift
//  awdl_NW
//
//  Created by junjiecui on 2026/3/31.
//

import Network
import os.log
import Darwin

class Advertiser {
    private let serviceName: String = "awdl_cjj"
    private let serviceType: String = "_wechat-chatlog._tcp"
    private let serviceDomain: String = "local."
    
    private var listener: NWListener? = nil
    
    private let logger = Logger(subsystem: "com.awdl.advertiser", category: "Advertiser")
    
    init() {
        
    }
    
    func startAdvertising() {
        guard let port = NWEndpoint.Port(rawValue: 50001) else {
            logger.error("Failed to create port")
            return
        }
        
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        parameters.requiredInterfaceType = .wifi
        
        do {
            listener = try NWListener(using: parameters, on: port)
        } catch {
            logger.error("Failed to create listener")
        }
        listener?.service = NWListener.Service(
            name: self.serviceName,
            type: self.serviceType,
            domain: self.serviceDomain
        )
        
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger.info("Listener state: ready")
                // AWDL interface is now active, retrieve its IPv6 address
                NetworkManager.shared.logAWDLIPv6Addresses()
            case .failed:
                self?.logger.error("Listener state: failed")
            case .cancelled:
                self?.logger.error("Listener state: cancelled")
            default:
                self?.logger.error("Listener state: none")
            }
        }
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.logger.info("New connection comming")
        }
        
        listener?.start(queue: .main)
        logger.info("Started advertising")
    }
    
    func stopAdvertising() {
        listener?.cancel()
        listener = nil
        logger.info("Stopped advertising")
    }
}
