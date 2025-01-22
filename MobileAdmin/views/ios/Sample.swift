//
//  Sample.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/20/25.
//

import SwiftUI


struct Sample: View {
    
    @State var showView = false
    var body: some View {
        ScrollView{
            ParallaxBackground()
                .frame(height: 500)
                .clipped()
                                //Spacer().frame(height: 100) // 배경과 내용 간 거리 조정
                                ForEach(1...20, id: \.self) { i in
                                    Text("Item \(i)")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                        .padding(.horizontal)
                                        .padding(.vertical, 5)
                                }
        }
        .edgesIgnoringSafeArea(.all)
        Button("Hello") {
            print("Hello")
            withAnimation {
                showView.toggle()
            }
        }
        VStack(alignment:.leading){
            if showView {
                VStack{
                    Text("Hello, World!")
                    Text("Hello, World!")
                    Text("Hello, World!")
                }
                .transition(.blurAndFade
//                    .combined(with: .slideAndScale)
//                    .combined(with: .blurAndFade)
                )
            }
        }
    }
}
struct ParallaxBackground: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Image("backgroud") // 배경 이미지 이름
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width,
                       height: geometry.size.height + calculateParallax(geometry: geometry))
                .offset(y: calculateParallax(geometry: geometry) / -2) // 패럴랙스 효과
                .blur(radius: 10-geometry.frame(in:.global).minY/10)
                .onAppear {
                    // 초기 offset 계산
                    offset = geometry.frame(in: .global).minY
                }
        }
    }
    
    private func calculateParallax(geometry: GeometryProxy) -> CGFloat {
        let minY = geometry.frame(in: .global).minY
        return -minY / 4 // 이동 속도 조절 (1보다 작은 값으로 느리게 이동)
    }
}
#Preview {
    Sample()
}
