import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WatchViewModel = WatchViewModel()
    
    @State private var moveTimer: Timer?
    @State private var isLeftPressed = false
    @State private var isRightPressed = false
    @State private var currentDirection: String?
    
    var body: some View {
        ZStack {
            if viewModel.isGameRunning {
                VStack {
                    Text("\(viewModel.score)")
                        .font(.system(size: 26, weight: .bold))
                        .animation(.easeIn(duration: 1))
                    
                    HStack {
                        // Bouton Gauche
                        Button(action: {}) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20))
                                .foregroundColor(isLeftPressed ? .gray : .white)
                        }
                        .onLongPressGesture(minimumDuration: 0.0,
                                          pressing: { pressing in
                            if pressing {
                                if !isLeftPressed && currentDirection == nil {
                                    isLeftPressed = true
                                    currentDirection = "left"
                                    startMoving(direction: "left")
                                }
                            } else {
                                isLeftPressed = false
                                if currentDirection == "left" {
                                    currentDirection = nil
                                    stopMoving()
                                }
                            }
                        }, perform: {})
                        
                        // Bouton Droite
                        Button(action: {}) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(isRightPressed ? .gray : .white)
                        }
                        .onLongPressGesture(minimumDuration: 0.0,
                                          pressing: { pressing in
                            if pressing {
                                if !isRightPressed && currentDirection == nil {
                                    isRightPressed = true
                                    currentDirection = "right"
                                    startMoving(direction: "right")
                                }
                            } else {
                                isRightPressed = false
                                if currentDirection == "right" {
                                    currentDirection = nil
                                    stopMoving()
                                }
                            }
                        }, perform: {})
                    }
                }
            } else {
                VStack {
                    Text("Tapez sur le téléphone pour commencer le jeu")
                        .multilineTextAlignment(.center)
                        .animation(.snappy())
                }
            }
        }
        .onDisappear {
            stopMoving()
            currentDirection = nil
            isLeftPressed = false
            isRightPressed = false
        }
    }
    
    private func startMoving(direction: String) {
        stopMoving()
        
        guard currentDirection == direction else { return }
        
        viewModel.sendDataMessage(
            for: .movePaddle,
            data: ["direction": direction]
        )
        
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard currentDirection == direction else {
                stopMoving()
                return
            }
            
            viewModel.sendDataMessage(
                for: .movePaddle,
                data: ["direction": direction]
            )
        }
    }
    
    private func stopMoving() {
        moveTimer?.invalidate()
        moveTimer = nil
    }
}

#Preview {
    ContentView()
}
