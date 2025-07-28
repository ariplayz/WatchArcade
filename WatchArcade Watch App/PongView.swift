//
//  PongView.swift
//  WatchArcade
//
//  Created by Ari Greene Cummings on 7/27/25.
//


import SwiftUI

struct PongView: View {
    @State private var game = PongGame()
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ball
                Circle()
                    .frame(width: 10, height: 10)
                    .position(x: geo.size.width * game.ballPosition.x,
                              y: geo.size.height * game.ballPosition.y)

                // Paddle
                Rectangle()
                    .frame(width: 50, height: 10)
                    .position(x: geo.size.width * game.paddlePosition,
                              y: geo.size.height - 20)
            }
            .onReceive(timer) { _ in
                game.update(in: geo.size)
            }
            .digitalCrownRotation($game.paddlePosition, from: 0, through: 1, by: 0.01)
        }
    }
}

struct PongGame {
    var ballPosition = CGPoint(x: 0.5, y: 0.5)
    var ballVelocity = CGVector(dx: 0.01, dy: 0.01)
    var paddlePosition = CGFloat(0.5)

    mutating func update(in size: CGSize) {
        ballPosition.x += ballVelocity.dx
        ballPosition.y += ballVelocity.dy

        // Bounce off walls
        if ballPosition.x <= 0 || ballPosition.x >= 1 {
            ballVelocity.dx *= -1
        }
        if ballPosition.y <= 0 {
            ballVelocity.dy *= -1
        }

        // Paddle bounce
        if ballPosition.y >= 0.95,
           abs(ballPosition.x - paddlePosition) < 0.1 {
            ballVelocity.dy *= -1
        }
    }
}
