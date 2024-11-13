//
//  ContentView.swift
//  laborBreath
//
//  Created by Leeo on 11/13/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isBreathing = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    @State private var breathingText = "시작하기"
    
    var body: some View {
        ZStack {
            // 배경색
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack  {
                    
                    // 호흡 애니메이션 원
                    Circle()
                        .fill(Color.blue.opacity(opacity))
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 200, height: 200)
                        )
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 200*1.5, height: 200*1.5)
                    // 호흡 안내 텍스트
                    Text(breathingText)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .animation(.easeInOut, value: breathingText)
                }
                // 시작/정지 버튼
                Button(action: {
                    if isBreathing {
                        stopBreathing()
                    } else {
                        startBreathing()
                    }
                }) {
                    Text(isBreathing ? "정지" : "시작")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(isBreathing ? Color.red : Color.green)
                        .cornerRadius(25)
                }
            }
        }
    }
    
    func startBreathing() {
        isBreathing = true
        
        // 반복되는 호흡 애니메이션
        withAnimation(Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            scale = 1.5
            opacity = 0.3
        }
        
        // 호흡 텍스트 업데이트를 위한 타이머
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            if isBreathing {
                withAnimation {
                    breathingText = breathingText == "들숨" ? "날숨" : "들숨"
                }
            } else {
                timer.invalidate()
            }
        }
        
        // 초기 텍스트 설정
        breathingText = "들숨"
    }
    
    func stopBreathing() {
        isBreathing = false
        
        withAnimation {
            scale = 1.0
            opacity = 0.8
            breathingText = "시작하기"
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(Color.white, lineWidth: 2)
            .rotationEffect(.degrees(-90))
    }
}

#Preview {
    ContentView()
}
