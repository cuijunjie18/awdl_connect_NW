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
//        let bonjourDescriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: serviceDomain)
        let bonjourDescriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(type: serviceType, domain: serviceDomain)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        // parameters.requiredInterfaceType = .wifi
                
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
                    self.logger.info("Found service - name: \(name), type: \(type), domain: \(domain)")
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
                    let dict = txtRecord.dictionary
                    if let ip = dict["awdl_ipv6"], let interface = dict["awdl_interface"] {
                        self.logger.info("  Peer's awdl_ipv6: \(ip), awdl_interface: \(interface)")
                        DispatchQueue.global(qos: .userInitiated).async {
                            tcp_client_connect(ip, interface, 8888)
                        }
                    } else {
                        self.logger.error("Peer's awdl_ipv6 or awdl_interface not found")
                    }
                }
                
                // 4. Resolve IP address by creating a connection to the endpoint
//                NetworkManager.shared.resolveEndpoint(result.endpoint)
            }
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
