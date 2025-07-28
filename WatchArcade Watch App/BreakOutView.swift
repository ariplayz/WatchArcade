//
//  BreakOutView.swift
//  WatchArcade
//
//  Created by Ari Greene Cummings on 7/27/25.
//


import SwiftUI

struct BreakOutView: View {
    @State private var game = BreakOutGame()
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Bricks
                ForEach(game.bricks.indices, id: \.self) { index in
                    if game.bricks[index].isActive {
                        Rectangle()
                            .frame(width: 30, height: 10)
                            .position(game.bricks[index].position(in: geo.size))
                    }
                }

                // Ball
                Circle()
                    .frame(width: 10, height: 10)
                    .position(game.ballPosition(in: geo.size))

                // Paddle
                Rectangle()
                    .frame(width: 50, height: 10)
                    .position(x: geo.size.width * game.paddlePosition, y: geo.size.height - 20)
            }
            .onReceive(timer) { _ in
                game.update(in: geo.size)
            }
            .digitalCrownRotation($game.paddlePosition, from: 0, through: 1, by: 0.01)
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
