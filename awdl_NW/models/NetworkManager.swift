//
//  NetworkAnalyser.swift
//  awdl_NW
//
//  Created by junjiecui on 2026/4/1.
//
import Network
import os.log

class NetworkManager {
    static let shared = NetworkManager()
    
    private let logger = Logger(subsystem: "com.example.NetworkAnalyser", category: "NetworkAnalyser")
    
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
        return addresses
    }
    
    /// Resolve IP address by connecting to the discovered service endpoint
    func resolveEndpoint(_ endpoint: NWEndpoint) {
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
}
