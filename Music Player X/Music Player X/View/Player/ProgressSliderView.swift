//
//  ProgressSliderView.swift
//  Music Player X
//
//  Created by Richard Pacheco on 7/5/23.
//

import SwiftUI

struct ProgressSliderView: View {
    @State var widthOfProgressByGesture: CGFloat = 0
    @State var isDragging: Bool = false {
        willSet {
            if newValue != isDragging {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
    @State var SLIDER_PADDING: CGFloat = 0
    @State var effectivePaddingParent: CGFloat = 0
    @State var lastPercentageValue: Double = 0
    @Binding var allowDragGesture: Bool
    @Binding var progressValue: Double
    var paddingParentComponent: CGFloat = 0
    var widthOfParent: CGFloat = UIScreen.main.bounds.width
    var maxWidhtOfComponent: CGFloat {
        get {
            return widthOfParent - ((SLIDER_PADDING + effectivePaddingParent) * 2)
        }
    }

    var updateCurrentTimeWithSlider: ((Double) -> Void)?
    var sliderDidSlider: ((Double) -> Void)?

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
            GeometryReader { proxy in
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(height: 3)
                    Rectangle()
                        .foregroundColor(Color.white)
                        .frame(width: isDragging ? max(0.0, widthOfProgressByGesture) : max(0.0, (lastPercentageValue * proxy.size.width)), height: 3)
                }
                .frame(height: allowDragGesture ? 30 : 3)
                .overlay(alignment: .leading, content: {
                    Circle()
                        .fill(.white)
                        .frame(width: allowDragGesture ? 20 : 0, height: allowDragGesture ? 20 : 0)
                        .background(Circle().stroke(.white, lineWidth: 0))
                        .background {
                            if allowDragGesture {
                                Circle()
                                    .fill(.white.opacity(0.4))
                                    .frame(width: isDragging ? 40 : 20, height: isDragging ? 40 : 20)
                            }
                        }
                        .offset(x: (isDragging ? widthOfProgressByGesture :  (lastPercentageValue * proxy.size.width)) - 10)
                })
            }
        }
        .frame(height: allowDragGesture ? 20 : 3)
        .frame(maxWidth: maxWidhtOfComponent)
        .padding(.horizontal, SLIDER_PADDING)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard allowDragGesture else {return}
                    updateIsDragging(true)
                    if value.location.x > (SLIDER_PADDING + effectivePaddingParent) && value.location.x <= (widthOfParent - (SLIDER_PADDING + effectivePaddingParent)) {
                        widthOfProgressByGesture = value.location.x - (SLIDER_PADDING)
                        let newValue = transformWidthToPercentage(widthValue: widthOfProgressByGesture)
                        updateCurrentTimeWithSlider?(newValue)
                    }
                }
                .onEnded { value in
                    widthOfProgressByGesture = value.location.x - (SLIDER_PADDING)
                    lastPercentageValue = transformWidthToPercentage(widthValue: widthOfProgressByGesture)
                    goToTime(lastPercentageValue)
                    updateIsDragging(false)
                }
        )
        .onChange(of: allowDragGesture) { newValue in
            SLIDER_PADDING = allowDragGesture ? 17 : 0
            effectivePaddingParent = allowDragGesture ? paddingParentComponent : 0
        }
        .onChange(of: progressValue, perform: { newValue in
            guard !isDragging else {return}
            lastPercentageValue = newValue
        })
        .onTapGesture { location in
            guard allowDragGesture else {return}
            if location.x > (SLIDER_PADDING + effectivePaddingParent) && location.x <= (UIScreen.main.bounds.width - (SLIDER_PADDING + effectivePaddingParent)) {
                widthOfProgressByGesture = location.x - (SLIDER_PADDING)
                lastPercentageValue = transformWidthToPercentage(widthValue: widthOfProgressByGesture)
                goToTime(lastPercentageValue)
            }
        }
    }

    private func updateIsDragging(_ value: Bool = false) {
        withAnimation {
            isDragging = value
        }
    }

    private func transformWidthToPercentage(widthValue: Double) -> Double {
        var value: Double = ((widthValue * 100) / maxWidhtOfComponent) / 100.0
        if value <= 0 {
            value = 0
        } else if value >= 1.0 {
            value = 1.0
        }
        return value
    }

    private func goToTime(_ value: Double) {
        sliderDidSlider?(value)
    }
}

#if DEBUG
struct ProgressSliderView_Previews: PreviewProvider {

    static var previews: some View {
        ProgressSliderView(allowDragGesture: .constant(true), progressValue: .constant(0.5))
    }
}
#endif

