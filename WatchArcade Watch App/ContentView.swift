import SwiftUI

enum GameType {
    case pong, breakout
}

struct ContentView: View {
    @State private var selectedGame: GameType = .pong

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Group {
                    if selectedGame == .pong {
                        PongView()
                    } else {
                        BreakOutView()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { gesture in
                            if gesture.translation.height > 20 {
                                selectedGame = selectedGame == .pong ? .breakout : .pong
                            }
                        }
                )

                Text("Swipe down to switch game")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
        }
    }
}
