//
//  ContentView.swift
//  awdl_NW
//
//  Created by junjiecui on 2026/3/31.
//

import Foundation
import OSLog
import SwiftUI

let logger = Logger(subsystem: "com.awdl.nw", category: "CJJ_ContentView_logger")
let advertiser = Advertiser()
let browser = Browser()

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Advertise start", action: {
                advertiser.startAdvertising()
            })
            
            Button("Advertise stop", action: {
                advertiser.stopAdvertising()
            })
            
            Button("Browser start", action: {
                browser.startScanning()
            })
            
            Button("Browser stop", action: {
                browser.stopScanning()
            })
        }
    }
}

#Preview {
    ContentView()
}
