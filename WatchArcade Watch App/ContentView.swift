import SwiftUI

// MARK: - Root View

struct ContentView: View {
    @State private var selectedGame: String? = nil

    var body: some View {
        VStack {
            if selectedGame == nil {
                VStack(spacing: 12) {
                    Text("Watch Arcade")
                        .font(.headline)
                        .padding()

                    Button("Play Pong") {
                        selectedGame = "Pong"
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Play BreakOut") {
                        selectedGame = "BreakOut"
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if selectedGame == "Pong" {
                PongGameView(goBack: { selectedGame = nil })
            } else if selectedGame == "BreakOut" {
                BreakOutGameView(goBack: { selectedGame = nil })
            }
        }
    }
}

// MARK: - Pong Game

struct PongGameView: View {
    @State private var game = PongGame()
    @State private var crownValue: Double = 0.5
    @FocusState private var isFocused: Bool
    let goBack: () -> Void
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                Circle()
                    .frame(width: 6, height: 6)
                    .position(game.ballPosition(in: geo.size))

                Rectangle()
                    .frame(width: 4, height: 20)
                    .position(x: 10, y: geo.size.height * game.botY)

                Rectangle()
                    .frame(width: 4, height: 20)
                    .position(x: geo.size.width - 10, y: geo.size.height * game.playerY)

                VStack {
                    HStack {
                        Text("\(game.botScore)")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(game.playerScore)")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                if let winner = game.winner {
                    VStack {
                        Text("\(winner) Wins!")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                        Button("Back") {
                            goBack()
                        }
                    }
                }
            }
            .focusable(true)
            .focused($isFocused)
            .digitalCrownRotation(
                $crownValue,
                from: 0.0,
                through: 1.0,
                by: 0.0001,
                sensitivity: .low,
                isContinuous: true,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownValue) { newValue in
                game.playerY = min(max(0.07, 1.0 - newValue), 0.93)
            }
            .onAppear {
                isFocused = true
            }
            .onReceive(timer) { _ in
                game.update()
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height > 20 {
                            goBack()
                        }
                    }
            )
        }
    }
}

struct PongGame {
    var ball = CGPoint(x: 0.5, y: 0.5)
    var velocity = CGVector(dx: -0.0035, dy: 0.0035)
    var playerY = 0.5
    var botY = 0.5
    var playerScore = 0
    var botScore = 0
    var winner: String? = nil

    mutating func update() {
        guard winner == nil else { return }

        ball.x += velocity.dx
        ball.y += velocity.dy

        ball.x = max(0.0, min(1.0, ball.x))
        ball.y = max(0.0, min(1.0, ball.y))

        // Reflect off top or bottom
        if ball.y <= 0 || ball.y >= 1 {
            velocity.dy *= -1
        }

        // Collision with paddles
        if ball.x >= 0.97 && abs(ball.y - playerY) < 0.1 {
            velocity.dx *= -1.05
            velocity.dy *= 1.05
            ball.x = 0.97
        } else if ball.x <= 0.03 && abs(ball.y - botY) < 0.1 {
            velocity.dx *= -1.05
            velocity.dy *= 1.05
            ball.x = 0.03
        }

        // Scoring logic
        var didScore = false
        if ball.x > 1 {
            botScore += 1
            didScore = true
        } else if ball.x < 0 {
            playerScore += 1
            didScore = true
        }

        if playerScore >= 10 {
            winner = "Player"
        } else if botScore >= 10 {
            winner = "Bot"
        }

        if didScore {
            reset()
        }

        // Bot follows ball
        botY += (ball.y - botY) * 0.04
    }


    func ballPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: ball.x * size.width, y: ball.y * size.height)
    }

    mutating func reset() {
        ball = CGPoint(x: 0.5, y: 0.5)
        velocity = CGVector(dx: 0.0035 * (Bool.random() ? 1 : -1), dy: 0.0035 * (Bool.random() ? 1 : -1))
    }
}

// MARK: - BreakOut Game

struct BreakOutGameView: View {
    @State private var game = BreakOutGame()
    @State private var crownValue: Double = 0.5
    @FocusState private var isFocused: Bool
    let goBack: () -> Void
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                ForEach(game.bricks, id: \.self) { brick in
                    if !brick.hit {
                        let brickWidth = geo.size.width / 6 - 4
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: brickWidth, height: 10)
                            .position(
                                x: CGFloat(brick.col) * geo.size.width / 6 + geo.size.width / 12,
                                y: CGFloat(brick.row) * 14 + 30
                            )
                    }
                }

                Circle()
                    .frame(width: 8, height: 8)
                    .position(game.ballPosition(in: geo.size))

                Rectangle()
                    .frame(width: 40, height: 6)
                    .position(x: game.paddleX * geo.size.width, y: geo.size.height - 20)

                VStack {
                    HStack {
                        Text("Score: \(game.score)")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .focusable(true)
            .focused($isFocused)
            .digitalCrownRotation(
                $crownValue,
                from: 0.0,
                through: 1.0,
                by: 0.0001,
                sensitivity: .low,
                isContinuous: true,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownValue) { newValue in
                game.paddleX = min(max(0.07, 1.0 - newValue), 0.93)
            }
            .onAppear {
                isFocused = true
            }
            .onReceive(timer) { _ in
                game.update()
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height > 20 {
                            goBack()
                        }
                    }
            )
        }
    }
}

struct BreakOutGame {
    var ball = CGPoint(x: 0.5, y: 0.5)
    var velocity = CGVector(dx: 0.0035, dy: -0.0035)
    var paddleX = 0.5
    var score = 0

    struct Brick: Hashable {
        let row: Int
        let col: Int
        var hit: Bool = false
    }

    var bricks: [Brick] = (0..<4).flatMap { row in
        (0..<6).map { col in Brick(row: row, col: col) }
    }

    mutating func update() {
        ball.x += velocity.dx
        ball.y += velocity.dy

        ball.x = max(0.0, min(1.0, ball.x))
        ball.y = max(0.0, min(1.0, ball.y))

        if ball.x <= 0 || ball.x >= 1 {
            velocity.dx *= -1
        }

        if ball.y <= 0 {
            velocity.dy *= -1
        }

        if ball.y >= 0.93 && abs(ball.x - paddleX) < 0.1 {
            velocity.dy *= -1
        }

        if ball.y > 1 {
            reset()
        }

        for i in bricks.indices {
            guard !bricks[i].hit else { continue }

            let brickX = CGFloat(bricks[i].col) / 6.0 + 1.0 / 12.0
            let brickY = CGFloat(bricks[i].row) * 0.04 + 0.1

            if abs(ball.x - brickX) < 0.08 && abs(ball.y - brickY) < 0.025 {
                bricks[i].hit = true
                velocity.dy *= -1
                score += 1
                break
            }
        }
    }

    func ballPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: ball.x * size.width, y: ball.y * size.height)
    }

    mutating func reset() {
        ball = CGPoint(x: 0.5, y: 0.5)
        velocity = CGVector(dx: 0.0035 * (Bool.random() ? 1 : -1), dy: -0.0035)
    }
}

