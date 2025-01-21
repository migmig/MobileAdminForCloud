//
//  Sample.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/20/25.
//

import SwiftUI

extension AnyTransition {
    static var colorAndFade: AnyTransition {
            .modifier(
                active: ColorFadeModifier(color: .red, opacity: 0),
                identity: ColorFadeModifier(color: .blue, opacity: 1)
            )
        }
    static var rotateAndMove: AnyTransition {
        .modifier(
            active: RotateMoveModifier(angle: 180, offset: CGSize(width: 0, height: 300)),
            identity: RotateMoveModifier(angle: 0, offset: .zero)
        )
    }
    static var blurAndFade: AnyTransition {
        .modifier(
            active: BlurModifier(radius: 10, opacity: 0),
            identity: BlurModifier(radius: 0, opacity: 1)
        )
    }
    static var threeDRotate: AnyTransition {
        .modifier(
            active: ThreeDRotateModifier(angle: 90, axis: (x: 0, y: 1, z: 0)),
            identity: ThreeDRotateModifier(angle: 0, axis: (x: 0, y: 1, z: 0))
        )
    }
    static var slideAndScale: AnyTransition {
        .modifier(
            active: SlideScaleModifier(offset: CGSize(width: -300, height: 0), scale: 1),
            identity: SlideScaleModifier(offset: .zero, scale: 1)
        )
    }
    static var rotateAndFade: AnyTransition {
        .modifier(
            active: RotateModifier(angle: 360, opacity: 0),
            identity: RotateModifier(angle: 0, opacity: 1)
        )
    }
}

struct Sample: View {
    
    @State var showView = false
    var body: some View {
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


struct RotateModifier: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .opacity(opacity)
    }
}
struct SlideScaleModifier: ViewModifier {
    let offset: CGSize
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .scaleEffect(scale)
    }
}
struct ThreeDRotateModifier: ViewModifier {
    let angle: Double
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)

    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: axis)
    }
}
struct BlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

struct RotateMoveModifier: ViewModifier {
    let angle: Double
    let offset: CGSize

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .offset(offset)
    }
}
struct ColorFadeModifier: ViewModifier {
    let color: Color
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .background(color)
            .opacity(opacity)
    }
}
#Preview {
    Sample()
}
