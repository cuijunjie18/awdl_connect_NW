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
            guard let self = self else { return }
            self.logger.info("Browse results changed, found \(newResults.count) service(s)")
            
            for result in newResults {
                // 1. Get endpoint info (service name, type, domain)
                switch result.endpoint {
                case .service(let name, let type, let domain, let interface):
                    self.logger.info("Found service - name: \(name), type: \(type), domain: \(domain), interface: \(String(describing: interface))")
                default:
                    self.logger.info("Found endpoint: \(result.endpoint.debugDescription)")
                }
                
                // 2. Get network interfaces (e.g. Wi-Fi, AWDL)
                for iface in result.interfaces {
                    self.logger.info("  Interface: \(String(iface.name))")
                }
                
                // 3. Get TXT record metadata (custom key-value pairs from advertiser)
                if case .bonjour(let txtRecord) = result.metadata {
                    self.logger.info("  TXT Record: \(txtRecord.dictionary)")
                }
                
                // 4. Resolve IP address by creating a connection to the endpoint
//                self.resolveEndpoint(result.endpoint)
            }
        }
        
        logger.info("Start scanning")
        browser?.start(queue: .main)
    }
    
    /// Resolve IP address by connecting to the discovered service endpoint
    private func resolveEndpoint(_ endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                // Once connected, we can get the resolved remote endpoint with IP
                if let remotePath = connection.currentPath,
                   let remoteEndpoint = remotePath.remoteEndpoint {
                    self?.logger.info("Resolved IP: \(remoteEndpoint.debugDescription)")
                }
                // Get local address info as well
                if let localEndpoint = connection.currentPath?.localEndpoint {
                    self?.logger.info("Local endpoint: \(localEndpoint.debugDescription)")
                }
                connection.cancel()
            case .failed(let error):
                self?.logger.error("Connection failed: \(error)")
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .main)
    }
    
    func stopScanning() {
        browser?.cancel()
        browser = nil
        logger.info("Stop scanning")
    }
}
