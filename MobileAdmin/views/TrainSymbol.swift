//
//  TrainSymbol.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI

enum TrainSymbol: String {
    case front = "train.side.front.car"
    case middle = "train.side.middle.car"
    case rear = "train.side.rear.car"
}

struct TrainCar: View {
    let position :TrainSymbol
    let showFrame :Bool
    
    init(_ position:TrainSymbol,showFrame:Bool=true){
        self.position = position
        self.showFrame = showFrame
    }
    
    
    var body: some View {
        Image(systemName:position.rawValue)
            .background(Color.red)
    }
}

struct TrainTrack : View{
    var body : some View{
        Divider()
            .frame(maxWidth: 200 )
    }
}

struct DefaultSpacing : View {
    
    @ScaledMetric var trainCarSpace = 5
    
    var body:some View{
        Text("Default Spacing")
        HStack(spacing:trainCarSpace){
            TrainCar(.rear)
            ZStack {
                TrainCar(.middle)
                    .font(.largeTitle)
                    .opacity(0)
                    .background(Color.green)
                TrainCar(.middle)
                    .background(Color.green)
                
            }
            TrainCar(.front)
        }
        .padding()
        .background(Color.blue)
        TrainTrack()
    }
}


struct TrainCar_Preview:PreviewProvider{
    static var previews: some View{
        VStack{
            DefaultSpacing()
        }
    }
}

 
