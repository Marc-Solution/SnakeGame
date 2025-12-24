//
//  GameViewModel.swift
//  SnakeGame
//
//  The game engine that handles game loop, movement, collision detection, and scoring.
//

import Foundation
@preconcurrency import Combine

// MARK: - Game Configuration

/// Configuration constants for game mechanics
enum GameConfig: Sendable {
    /// Time interval between snake movements (in seconds)
    static let moveInterval: TimeInterval = 0.15
    
    /// Points awarded for eating food
    static let pointsPerFood: Int = 10
}

// MARK: - Game View Model

/// The main game engine managing all game logic
@MainActor
final class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The current game state
    @Published private(set) var gameState: GameState = .idle
    
    /// The snake entity
    @Published private(set) var snake: Snake = Snake()
    
    /// The current food on the grid
    @Published private(set) var food: Food
    
    /// The player's current score
    @Published private(set) var score: Int = 0
    
    // MARK: - Private Properties
    
    /// Timer for the game loop
    private var gameTimer: Timer?
    
    /// The next direction to apply (buffered to prevent multiple direction changes per tick)
    private var nextDirection: Direction?
    
    // MARK: - Initialization
    
    init() {
        // Initialize snake first, then spawn food avoiding it
        let initialSnake = Snake()
        self.snake = initialSnake
        self.food = Food.spawn(avoiding: initialSnake)
    }
    
    // MARK: - Public Methods
    
    /// Starts a new game
    func startGame() {
        resetGame()
        gameState = .playing
        startGameLoop()
    }
    
    /// Pauses the current game
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        stopGameLoop()
    }
    
    /// Resumes a paused game
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        startGameLoop()
    }
    
    /// Restarts the game after game over
    func restartGame() {
        startGame()
    }
    
    /// Changes the snake's direction based on player input.
    /// The direction change is buffered and applied on the next game tick.
    /// - Parameter newDirection: The requested direction
    func changeDirection(to newDirection: Direction) {
        guard gameState == .playing else { return }
        
        // Validate direction change against current direction
        // This prevents reversing direction directly
        guard !newDirection.isOpposite(to: snake.direction) else { return }
        
        // Buffer the direction change for the next tick
        nextDirection = newDirection
    }
    
    // MARK: - Private Methods
    
    /// Resets all game state to initial values
    private func resetGame() {
        stopGameLoop()
        snake = Snake()
        food = spawnFood()
        score = 0
        nextDirection = nil
        gameState = .idle
    }
    
    /// Spawns food at a random position avoiding the snake
    private func spawnFood() -> Food {
        Food.spawn(avoiding: snake)
    }
    
    /// Starts the game loop timer on the MainActor
    private func startGameLoop() {
        stopGameLoop() // Ensure no duplicate timers
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: GameConfig.moveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.gameTick()
            }
        }
    }
    
    /// Stops the game loop timer
    private func stopGameLoop() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    /// Executes one tick of the game loop
    private func gameTick() {
        guard gameState == .playing else { return }
        
        // Apply buffered direction change
        applyBufferedDirection()
        
        // Move the snake and check for collisions
        moveSnake()
    }
    
    /// Applies the buffered direction change to the snake
    private func applyBufferedDirection() {
        if let direction = nextDirection {
            _ = snake.changeDirection(to: direction)
            nextDirection = nil
        }
    }
    
    /// Moves the snake and handles collision detection
    private func moveSnake() {
        // Check for collisions before moving (peek ahead)
        let nextHeadPosition = snake.head.moved(in: snake.direction)
        
        // Check wall collision
        if checkWallCollision(at: nextHeadPosition) {
            endGame()
            return
        }
        
        // Check self collision
        if checkSelfCollision(at: nextHeadPosition) {
            endGame()
            return
        }
        
        // Check if snake will eat food
        let willEatFood = nextHeadPosition == food.position
        
        // Move the snake
        snake.move(grow: willEatFood)
        
        // Handle food consumption
        if willEatFood {
            handleFoodConsumption()
        }
    }
    
    /// Checks if the given position collides with a wall
    private func checkWallCollision(at position: GridPoint) -> Bool {
        !position.isWithinBounds
    }
    
    /// Checks if the given position collides with the snake's body
    private func checkSelfCollision(at position: GridPoint) -> Bool {
        // We check against body minus the tail (since tail moves away)
        let bodyWithoutTail = Array(snake.body.dropLast())
        return bodyWithoutTail.contains(position)
    }
    
    /// Handles scoring and food respawn when snake eats food
    private func handleFoodConsumption() {
        score += GameConfig.pointsPerFood
        food = spawnFood()
    }
    
    /// Ends the game
    private func endGame() {
        stopGameLoop()
        gameState = .gameOver
    }
}

// MARK: - Direction Input Helpers

extension GameViewModel {
    
    /// Convenience method for swipe up gesture
    func swipeUp() {
        changeDirection(to: .up)
    }
    
    /// Convenience method for swipe down gesture
    func swipeDown() {
        changeDirection(to: .down)
    }
    
    /// Convenience method for swipe left gesture
    func swipeLeft() {
        changeDirection(to: .left)
    }
    
    /// Convenience method for swipe right gesture
    func swipeRight() {
        changeDirection(to: .right)
    }
}

