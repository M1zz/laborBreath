//
//  ContentView.swift
//  laborBreath
//
//  Created by Leeo on 11/13/24.
//

import SwiftUI

struct Contraction: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
}

struct BreathView: View {
    @State private var isBreathing = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    @State private var breathingText = "시작하기"
    
    @State private var contractions: [Contraction] = []
    @State private var isShowingContractionHistory = false
    @State private var timer: Timer?
    
    private let smallCircleSize: CGFloat = 120
    private let circleWeight: CGFloat = 2.7
    
    private let contractionsFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("contractions.json")
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(opacity))
                        .frame(width: smallCircleSize, height: smallCircleSize)
                        .scaleEffect(scale)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: smallCircleSize, height: smallCircleSize)
                        )
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: smallCircleSize * circleWeight, height: smallCircleSize * circleWeight)
                    
                    Text(breathingText)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .animation(.easeInOut, value: breathingText)
                }
                .onTapGesture {
                    if isBreathing {
                        stopBreathing()
                    } else {
                        startBreathing()
                    }
                }
                Spacer()
                HStack {
                    Button(action: recordContraction) {
                        Text("진통 기록")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { isShowingContractionHistory = true }) {
                        Text("진통 보기")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: deleteContractions) {
                        Text("진통 기록 삭제")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .sheet(isPresented: $isShowingContractionHistory) {
                ContractionHistoryView(contractions: contractions)
            }
            .onAppear(perform: loadContractions)
        }
    }
    
    func startBreathing() {
        isBreathing = true
        breathingText = "들숨"
        
        animateBreathing(inhaleDuration: 4.0, exhaleDuration: 6.0)
    }
    
    func animateBreathing(inhaleDuration: Double, exhaleDuration: Double) {
        let inhaleAnimation = Animation.easeInOut(duration: inhaleDuration)
        let exhaleAnimation = Animation.easeInOut(duration: exhaleDuration)
        
        // Start with inhale
        isBreathing = true
        isTimerRunning(isInhaling: true)
        
        withAnimation(inhaleAnimation) {
            scale = circleWeight
            opacity = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration) {
            // Start exhale after inhale
            breathingText = "날숨"
            isTimerRunning(isInhaling: false)
            
            withAnimation(exhaleAnimation) {
                scale = 1.0
                opacity = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + exhaleDuration) {
                if isBreathing {
                    animateBreathing(inhaleDuration: inhaleDuration, exhaleDuration: exhaleDuration)
                }
            }
        }
    }
    
    func stopBreathing() {
        isBreathing = false
        timer?.invalidate()
        timer = nil
        withAnimation {
            scale = 1.0
            opacity = 0.8
            breathingText = "시작하기"
        }
    }
    
    func isTimerRunning(isInhaling: Bool) {
        let totalDuration = isInhaling ? 4 : 6
        var counter = 1
        
        timer?.invalidate() // Clear any previous timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if counter > totalDuration {
                t.invalidate()
                return
            }
            
            // Update text based on inhale or exhale phase
            breathingText = isInhaling ? "들숨\(counter)" : "날숨\(counter)"
            counter += 1
        }
    }
    
    func recordContraction() {
        let newContraction = Contraction(timestamp: Date())
        contractions.insert(newContraction, at: 0)
        saveContractions()
    }
    
    func saveContractions() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(contractions)
            try data.write(to: contractionsFileURL)
        } catch {
            print("Failed to save contractions: \(error)")
        }
    }
    
    func loadContractions() {
        do {
            let data = try Data(contentsOf: contractionsFileURL)
            let decoder = JSONDecoder()
            let loadedContractions = try decoder.decode([Contraction].self, from: data)
            contractions = loadedContractions.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("No contractions found or failed to load contractions: \(error)")
        }
    }
    
    func deleteContractions() {
        contractions.removeAll()
        do {
            try FileManager.default.removeItem(at: contractionsFileURL)
        } catch {
            print("Failed to delete contractions file: \(error)")
        }
    }
}

struct ContractionHistoryView: View {
    let contractions: [Contraction]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contractions.indices, id: \.self) { index in
                    if index > 0 {
                        let interval = contractions[index].timestamp.timeIntervalSince(contractions[index - 1].timestamp)
                        VStack(alignment: .leading) {
                            Text("Contraction at \(formattedDate(contractions[index].timestamp))")
                            Text("Interval: \(String(format: "%.2f", interval / 60)) minutes")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Contraction at \(formattedDate(contractions[index].timestamp))")
                    }
                }
            }
            .navigationTitle("진통 히스토리")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @Environment(\.dismiss) var dismiss
}

#Preview {
    BreathView()
}



//1. 초기 진통기
//트리거: 규칙적인 자궁 수축, 대개 5~30분 간격, 약한 통증.
// 들숨 코로 4초 날숨 입으로 6초
//호흡 가이딩: 긴장을 풀고 통증을 덜기 위해 깊고 느리게 호흡합니다. "들숨에 4초, 날숨에 6초"와 같은 속도로 천천히 숨을 들이마시고 내쉬며 몸을 준비합니다.
//2. 활발한 진통기
//트리거: 수축이 더 자주 발생하며 3~5분 간격, 통증이 더 강해짐.
// 들숨 코로 4초 날숨 입으로 6초
//호흡 가이딩: 말 입술 호흡법을 사용하여 입술을 떨리게 하며 숨을 내쉽니다. 이완된 상태를 유지하여 수축에 대응하도록 돕습니다.
//3. 이행기
//트리거: 1~2분 간격으로 강한 수축, 압박감과 함께 고통이 극심함.
// 들숨 코로 4초 날숨 입으로 6초
//호흡 가이딩: 통증 완화와 압박 조절을 위해 기침 호흡법을 사용합니다. 짧고 빠르게 숨을 내쉬어 압박을 완화하고 자궁이 확장되는 느낌을 관리합니다.
//각 단계의 호흡법과 함께 천천히 자신의 페이스를 유지하면서 수축과 고통을 수용해나가는 것이 중요합니다.
