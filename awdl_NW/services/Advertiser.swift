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
    
    init(name: String? = nil) {
        
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
                self?.logAWDLIPv6Addresses()
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
    
    /// Retrieve and log IPv6 addresses of the AWDL interface (awdl0)
    func logAWDLIPv6Addresses() {
        let awdlAddresses = getInterfaceIPv6Addresses(interfaceName: "awdl0")
        if awdlAddresses.isEmpty {
            logger.warning("No IPv6 address found on awdl0 interface")
        } else {
            for addr in awdlAddresses {
                logger.info("AWDL IPv6 address: \(addr)")
            }
        }
    }
    
    /// Enumerate all network interfaces and return IPv6 addresses for the specified interface
    func getInterfaceIPv6Addresses(interfaceName: String) -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            logger.error("getifaddrs failed")
            return addresses
        }
        defer { freeifaddrs(ifaddr) }
        
        var current: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = current {
            let name = String(cString: addr.pointee.ifa_name)
            let family = addr.pointee.ifa_addr.pointee.sa_family
            
            // Filter: match interface name and IPv6 family (AF_INET6 = 30)
            if name == interfaceName && family == UInt8(AF_INET6) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let sockAddr = addr.pointee.ifa_addr
                let sockLen = socklen_t(addr.pointee.ifa_addr.pointee.sa_len)
                
                if getnameinfo(sockAddr, sockLen,
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST) == 0 {
                    let ipv6String = String(cString: hostname)
                    addresses.append(ipv6String)
                }
            }
            current = addr.pointee.ifa_next
        }
        
        // Also log all interfaces for debugging
        current = firstAddr
        while let addr = current {
            let name = String(cString: addr.pointee.ifa_name)
            let family = addr.pointee.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET6) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr.pointee.ifa_addr,
                               socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST) == 0 {
                    logger.debug("Interface: \(name), IPv6: \(String(cString: hostname))")
                }
            }
            current = addr.pointee.ifa_next
        }
        
        return addresses
    }
    
    func stopAdvertising() {
        listener?.cancel()
        listener = nil
        logger.info("Stopped advertising")
    }
}
