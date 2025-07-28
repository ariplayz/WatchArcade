import SwiftUI
import Combine

enum GameType {
    case pong, breakout
}

struct ContentView: View {
    @State private var selectedGame: GameType = .pong
    @State private var showSwipeText = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Group {
                    if selectedGame == .pong {
                        PongView(size: geo.size)
                    } else {
                        BreakOutView(size: geo.size)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { gesture in
                            if gesture.translation.height > 20 {
                                selectedGame = selectedGame == .pong ? .breakout : .pong
                                showSwipeText = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showSwipeText = false
                                    }
                                }
                            }
                        }
                )

                if showSwipeText {
                    Text("Swipe down to switch game")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSwipeText = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - PongView
struct PongView: View {
    var size: CGSize
    @State private var game = PongGame()
    @State private var crownValue: Double = 0.5
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Midline
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: size.height)

            // Ball
            Circle()
                .frame(width: 10, height: 10)
                .position(game.ballPosition(in: size))

            // Player paddle (right)
            Rectangle()
                .frame(width: 6, height: 40)
                .position(x: size.width - 10, y: size.height * game.playerY)

            // Bot paddle (left)
            Rectangle()
                .frame(width: 6, height: 40)
                .position(x: 10, y: size.height * game.botY)

            // Scores
            VStack {
                HStack {
                    Text("\(game.botScore)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(game.playerScore)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                        .opacity(0.5)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Spacer()
            }

            // Win text
            if game.winner != nil {
                Text("\(game.winner!) Wins!")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownValue, from: 0, through: 1, by: 0.01, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crownValue) { newValue in
            game.playerY = min(max(0, newValue), 1)
        }
        .onReceive(timer) { _ in
            game.update()
        }
    }
}

struct PongGame {
    var ball = CGPoint(x: 0.5, y: 0.5)
    var velocity = CGVector(dx: -0.005, dy: 0.004)
    var playerY: CGFloat = 0.5
    var botY: CGFloat = 0.5
    var playerScore = 0
    var botScore = 0
    var winner: String? = nil

    mutating func update() {
        guard winner == nil else { return }

        ball.x += velocity.dx
        ball.y += velocity.dy

        // Bounce top/bottom
        if ball.y <= 0 || ball.y >= 1 {
            velocity.dy *= -1
        }

        // Bot AI
        if botY < ball.y {
            botY += 0.004
        } else {
            botY -= 0.004
        }
        botY = min(max(botY, 0), 1)

        // Collision with player paddle (right)
        if ball.x >= 0.98,
           abs(ball.y - playerY) < 0.07 {
            ball.x = 0.98
            velocity.dx *= -1
        }

        // Collision with bot paddle (left)
        if ball.x <= 0.02,
           abs(ball.y - botY) < 0.07 {
            ball.x = 0.02
            velocity.dx *= -1
        }

        // Missed by player
        if ball.x > 1 {
            botScore += 1
            resetBall(toPlayer: false)
        }

        // Missed by bot
        if ball.x < 0 {
            playerScore += 1
            resetBall(toPlayer: true)
        }

        // Win condition
        if playerScore >= 10 {
            winner = "Player"
        } else if botScore >= 10 {
            winner = "Bot"
        }
    }

    mutating func resetBall(toPlayer: Bool) {
        ball = CGPoint(x: 0.5, y: 0.5)
        velocity = CGVector(dx: toPlayer ? -0.005 : 0.005, dy: CGFloat.random(in: -0.004...0.004))
    }

    func ballPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * ball.x, y: size.height * ball.y)
    }
}

// MARK: - BreakOutView (unchanged)
struct BreakOutView: View {
    var size: CGSize
    @State private var game = BreakOutGame()
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Bricks
            ForEach(game.bricks.indices, id: \.self) { index in
                if game.bricks[index].isActive {
                    Rectangle()
                        .frame(width: 30, height: 10)
                        .position(game.bricks[index].position(in: size))
                }
            }

            // Ball
            Circle()
                .frame(width: 10, height: 10)
                .position(game.ballPosition(in: size))

            // Paddle
            Rectangle()
                .frame(width: 50, height: 10)
                .position(x: size.width * game.paddlePosition, y: size.height - 20)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let width = size.width
                    game.paddlePosition = min(max(0, value.location.x / width), 1)
                }
        )
        .onReceive(timer) { _ in
            game.update(in: size)
        }
    }
}

struct BreakOutGame {
    var paddlePosition = CGFloat(0.5)
    var ballPos = CGPoint(x: 0.5, y: 0.5)
    var ballVel = CGVector(dx: 0.01, dy: 0.01)
    var bricks: [Brick] = []

    init() {
        for row in 0..<3 {
            for col in 0..<5 {
                bricks.append(Brick(x: CGFloat(col) * 0.2 + 0.1, y: CGFloat(row) * 0.05 + 0.1))
            }
        }
    }

    mutating func update(in size: CGSize) {
        ballPos.x += ballVel.dx
        ballPos.y += ballVel.dy

        if ballPos.x <= 0 || ballPos.x >= 1 {
            ballVel.dx *= -1
        }

        if ballPos.y <= 0 {
            ballVel.dy *= -1
        }

        if ballPos.y >= 0.95,
           abs(ballPos.x - paddlePosition) < 0.1 {
            ballVel.dy *= -1
        }

        for i in bricks.indices {
            let brickCenter = bricks[i].position(in: size)
            let ballCenter = CGPoint(x: size.width * ballPos.x, y: size.height * ballPos.y)

            if bricks[i].isActive &&
               abs(ballCenter.x - brickCenter.x) < 20 &&
               abs(ballCenter.y - brickCenter.y) < 10 {
                bricks[i].isActive = false
                ballVel.dy *= -1
            }
        }
    }

    func ballPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * ballPos.x, y: size.height * ballPos.y)
    }
}

struct Brick {
    var x: CGFloat
    var y: CGFloat
    var isActive = true

    func position(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }
}
