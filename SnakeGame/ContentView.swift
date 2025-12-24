//
//  ContentView.swift
//  SnakeGame
//
//  The main game view with arcade-style visuals.
//

import SwiftUI

// MARK: - Color Theme

extension Color {
    static let arcadeBackground = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let gridLine = Color(red: 0.15, green: 0.17, blue: 0.22)
    static let snakeHead = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let snakeBody = Color(red: 0.15, green: 0.65, blue: 0.35)
    static let foodRed = Color(red: 0.95, green: 0.25, blue: 0.3)
    static let foodHighlight = Color(red: 1.0, green: 0.5, blue: 0.5)
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.5)
    static let overlayBackground = Color.black.opacity(0.85)
}

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let boardSize = calculateBoardSize(for: geometry.size)
            
            ZStack {
                // Background
                Color.arcadeBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // HUD - Score Display
                    ScoreHUD(score: viewModel.score, gameState: viewModel.gameState)
                    
                    Spacer()
                    
                    // Game Board
                    GameBoardView(
                        snake: viewModel.snake,
                        food: viewModel.food,
                        boardSize: boardSize
                    )
                    .frame(width: boardSize, height: boardSize)
                    
                    Spacer()
                    
                    // Start prompt for idle state
                    if viewModel.gameState == .idle {
                        StartPrompt()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Game Over Overlay
                if viewModel.gameState == .gameOver {
                    GameOverOverlay(score: viewModel.score) {
                        viewModel.startGame()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .gesture(swipeGesture)
            .onTapGesture {
                if viewModel.gameState == .idle {
                    viewModel.startGame()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.gameState)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                
                // Determine swipe direction based on which axis had more movement
                if abs(horizontal) > abs(vertical) {
                    // Horizontal swipe
                    if horizontal > 0 {
                        viewModel.swipeRight()
                    } else {
                        viewModel.swipeLeft()
                    }
                } else {
                    // Vertical swipe
                    if vertical > 0 {
                        viewModel.swipeDown()
                    } else {
                        viewModel.swipeUp()
                    }
                }
            }
    }
    
    // MARK: - Board Size Calculation
    
    private func calculateBoardSize(for screenSize: CGSize) -> CGFloat {
        let padding: CGFloat = 32
        let maxWidth = screenSize.width - padding
        let maxHeight = screenSize.height - 200 // Reserve space for HUD and prompts
        return min(maxWidth, maxHeight)
    }
}

// MARK: - Score HUD

struct ScoreHUD: View {
    let score: Int
    let gameState: GameState
    
    var body: some View {
        HStack {
            // Snake icon
            Image(systemName: "line.diagonal")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.neonGreen)
                .rotationEffect(.degrees(45))
            
            Text("SNAKE")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.neonGreen)
            
            Spacer()
            
            // Score display
            VStack(alignment: .trailing, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text("\(score)")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: score)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gridLine.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neonGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Game Board View

struct GameBoardView: View {
    let snake: Snake
    let food: Food
    let boardSize: CGFloat
    
    private var cellSize: CGFloat {
        boardSize / CGFloat(GridConfig.columns)
    }
    
    var body: some View {
        Canvas { context, size in
            // Draw grid background
            drawGrid(context: context, size: size)
            
            // Draw food
            drawFood(context: context)
            
            // Draw snake
            drawSnake(context: context)
        }
        .background(Color.arcadeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.neonGreen.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: Color.neonGreen.opacity(0.2), radius: 20)
    }
    
    // MARK: - Drawing Functions
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let path = Path { path in
            // Vertical lines
            for i in 0...GridConfig.columns {
                let x = CGFloat(i) * cellSize
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            // Horizontal lines
            for i in 0...GridConfig.rows {
                let y = CGFloat(i) * cellSize
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        
        context.stroke(path, with: .color(.gridLine), lineWidth: 0.5)
    }
    
    private func drawSnake(context: GraphicsContext) {
        for (index, segment) in snake.body.enumerated() {
            let rect = rectForCell(segment)
            let cornerRadius = cellSize * 0.25
            let insetRect = rect.insetBy(dx: 1, dy: 1)
            
            let isHead = index == 0
            let color = isHead ? Color.snakeHead : Color.snakeBody
            
            // Draw segment with rounded corners
            let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
            let segmentPath = roundedRect.path(in: insetRect)
            
            // Add slight gradient effect for depth
            context.fill(segmentPath, with: .color(color))
            
            // Add highlight to head
            if isHead {
                let highlightRect = insetRect.insetBy(dx: cellSize * 0.15, dy: cellSize * 0.15)
                let highlightPath = RoundedRectangle(cornerRadius: cornerRadius * 0.6).path(in: highlightRect)
                context.fill(highlightPath, with: .color(Color.white.opacity(0.3)))
                
                // Draw eyes based on direction
                drawEyes(context: context, headRect: insetRect, direction: snake.direction)
            }
        }
    }
    
    private func drawEyes(context: GraphicsContext, headRect: CGRect, direction: Direction) {
        let eyeSize = cellSize * 0.15
        let eyeOffset = cellSize * 0.2
        
        var leftEyeCenter: CGPoint
        var rightEyeCenter: CGPoint
        
        let centerX = headRect.midX
        let centerY = headRect.midY
        
        switch direction {
        case .up:
            leftEyeCenter = CGPoint(x: centerX - eyeOffset, y: centerY - eyeOffset * 0.5)
            rightEyeCenter = CGPoint(x: centerX + eyeOffset, y: centerY - eyeOffset * 0.5)
        case .down:
            leftEyeCenter = CGPoint(x: centerX - eyeOffset, y: centerY + eyeOffset * 0.5)
            rightEyeCenter = CGPoint(x: centerX + eyeOffset, y: centerY + eyeOffset * 0.5)
        case .left:
            leftEyeCenter = CGPoint(x: centerX - eyeOffset * 0.5, y: centerY - eyeOffset)
            rightEyeCenter = CGPoint(x: centerX - eyeOffset * 0.5, y: centerY + eyeOffset)
        case .right:
            leftEyeCenter = CGPoint(x: centerX + eyeOffset * 0.5, y: centerY - eyeOffset)
            rightEyeCenter = CGPoint(x: centerX + eyeOffset * 0.5, y: centerY + eyeOffset)
        }
        
        let leftEyeRect = CGRect(
            x: leftEyeCenter.x - eyeSize / 2,
            y: leftEyeCenter.y - eyeSize / 2,
            width: eyeSize,
            height: eyeSize
        )
        let rightEyeRect = CGRect(
            x: rightEyeCenter.x - eyeSize / 2,
            y: rightEyeCenter.y - eyeSize / 2,
            width: eyeSize,
            height: eyeSize
        )
        
        context.fill(Circle().path(in: leftEyeRect), with: .color(.white))
        context.fill(Circle().path(in: rightEyeRect), with: .color(.white))
    }
    
    private func drawFood(context: GraphicsContext) {
        let rect = rectForCell(food.position)
        let insetRect = rect.insetBy(dx: 2, dy: 2)
        
        // Draw apple body (red circle)
        let circlePath = Circle().path(in: insetRect)
        context.fill(circlePath, with: .color(.foodRed))
        
        // Add highlight for 3D effect
        let highlightSize = cellSize * 0.25
        let highlightRect = CGRect(
            x: insetRect.minX + cellSize * 0.15,
            y: insetRect.minY + cellSize * 0.15,
            width: highlightSize,
            height: highlightSize
        )
        context.fill(Circle().path(in: highlightRect), with: .color(.foodHighlight.opacity(0.6)))
        
        // Draw stem
        let stemPath = Path { path in
            let stemStartX = rect.midX
            let stemStartY = insetRect.minY + 2
            path.move(to: CGPoint(x: stemStartX, y: stemStartY))
            path.addLine(to: CGPoint(x: stemStartX + 2, y: stemStartY - 4))
        }
        context.stroke(stemPath, with: .color(Color(red: 0.4, green: 0.25, blue: 0.1)), lineWidth: 2)
        
        // Draw leaf
        let leafPath = Path { path in
            let leafStartX = rect.midX + 2
            let leafStartY = insetRect.minY - 2
            path.move(to: CGPoint(x: leafStartX, y: leafStartY))
            path.addQuadCurve(
                to: CGPoint(x: leafStartX + 5, y: leafStartY + 3),
                control: CGPoint(x: leafStartX + 4, y: leafStartY - 2)
            )
        }
        context.stroke(leafPath, with: .color(Color.green), lineWidth: 1.5)
    }
    
    private func rectForCell(_ point: GridPoint) -> CGRect {
        CGRect(
            x: CGFloat(point.x) * cellSize,
            y: CGFloat(point.y) * cellSize,
            width: cellSize,
            height: cellSize
        )
    }
}

// MARK: - Start Prompt

struct StartPrompt: View {
    @State private var isAnimating = false
    
    var body: some View {
        Text("TAP TO START")
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(.neonGreen)
            .opacity(isAnimating ? 0.4 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlay: View {
    let score: Int
    let onRestart: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.overlayBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Game Over Title
                VStack(spacing: 8) {
                    Text("GAME")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.foodRed)
                    
                    Text("OVER")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(.foodRed)
                }
                .shadow(color: .foodRed.opacity(0.5), radius: 10)
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)
                
                // Score Display
                VStack(spacing: 8) {
                    Text("FINAL SCORE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Text("\(score)")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateIn)
                
                // Play Again Button
                Button(action: onRestart) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("PLAY AGAIN")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.arcadeBackground)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.neonGreen)
                    )
                    .shadow(color: .neonGreen.opacity(0.5), radius: 10)
                }
                .scaleEffect(animateIn ? 1 : 0.5)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateIn)
            }
        }
        .onAppear {
            animateIn = true
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
