//
//  ErrorCloudListItem.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct ErrorCloudListItem: View {
    let errorCloudItem: ErrorCloudItem
    
    var body: some View {
        
        VStack {
            Text(errorCloudItem.description!)
                .lineLimit(3)
                .truncationMode(.tail)
            
        }
    }
}
