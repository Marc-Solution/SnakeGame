//
//  GameModels.swift
//  SnakeGame
//
//  Core data models for the Snake game engine.
//

import Foundation

// MARK: - Grid Configuration

/// Configuration constants for the game grid
enum GridConfig: Sendable {
    static let columns: Int = 20
    static let rows: Int = 20
}

// MARK: - Grid Point

/// Represents a single point/cell on the game grid
struct GridPoint: Equatable, Hashable, Sendable {
    let x: Int
    let y: Int
    
    /// Returns a new GridPoint moved in the specified direction
    func moved(in direction: Direction) -> GridPoint {
        switch direction {
        case .up:
            return GridPoint(x: x, y: y - 1)
        case .down:
            return GridPoint(x: x, y: y + 1)
        case .left:
            return GridPoint(x: x - 1, y: y)
        case .right:
            return GridPoint(x: x + 1, y: y)
        }
    }
    
    /// Checks if the point is within the grid boundaries
    var isWithinBounds: Bool {
        x >= 0 && x < GridConfig.columns && y >= 0 && y < GridConfig.rows
    }
}

// MARK: - Direction

/// Movement directions for the snake
enum Direction: CaseIterable, Sendable {
    case up
    case down
    case left
    case right
    
    /// Returns the opposite direction
    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
    
    /// Checks if this direction is opposite to another
    func isOpposite(to other: Direction) -> Bool {
        self == other.opposite
    }
}

// MARK: - Snake

/// Represents the snake with its body segments
struct Snake: Sendable {
    /// Array of grid points representing the snake's body.
    /// The first element is the head, the last is the tail.
    private(set) var body: [GridPoint]
    
    /// The current direction the snake is moving
    private(set) var direction: Direction
    
    /// The snake's head position
    var head: GridPoint {
        body[0]
    }
    
    /// The snake's tail (all segments except the head)
    var tail: [GridPoint] {
        Array(body.dropFirst())
    }
    
    /// The length of the snake
    var length: Int {
        body.count
    }
    
    /// Creates a new snake with default starting position and direction
    /// Starts in the center of the grid, moving right, with 3 segments
    init() {
        let startX = GridConfig.columns / 2
        let startY = GridConfig.rows / 2
        
        self.body = [
            GridPoint(x: startX, y: startY),         // Head
            GridPoint(x: startX - 1, y: startY),     // Body segment 1
            GridPoint(x: startX - 2, y: startY)      // Tail
        ]
        self.direction = .right
    }
    
    /// Creates a snake with custom body and direction
    init(body: [GridPoint], direction: Direction) {
        self.body = body
        self.direction = direction
    }
    
    /// Attempts to change the snake's direction.
    /// Returns false if the direction change is invalid (opposite direction).
    mutating func changeDirection(to newDirection: Direction) -> Bool {
        // Cannot reverse direction directly
        guard !newDirection.isOpposite(to: direction) else {
            return false
        }
        direction = newDirection
        return true
    }
    
    /// Moves the snake one step in its current direction.
    /// If `grow` is true, the snake grows by keeping its tail.
    mutating func move(grow: Bool = false) {
        let newHead = head.moved(in: direction)
        body.insert(newHead, at: 0)
        
        if !grow {
            body.removeLast()
        }
    }
    
    /// Checks if the snake's head collides with its own body
    var hasCollidedWithSelf: Bool {
        let headPosition = head
        return tail.contains(headPosition)
    }
    
    /// Checks if the snake's head is outside the grid boundaries
    var hasCollidedWithWall: Bool {
        !head.isWithinBounds
    }
    
    /// Checks if a given point is occupied by the snake
    func occupies(_ point: GridPoint) -> Bool {
        body.contains(point)
    }
}

// MARK: - Food

/// Represents food on the game grid
struct Food: Sendable {
    let position: GridPoint
    
    /// Generates food at a random position that doesn't overlap with the snake
    static func spawn(avoiding snake: Snake) -> Food {
        var availablePositions: [GridPoint] = []
        
        // Collect all positions not occupied by the snake
        for x in 0..<GridConfig.columns {
            for y in 0..<GridConfig.rows {
                let point = GridPoint(x: x, y: y)
                if !snake.occupies(point) {
                    availablePositions.append(point)
                }
            }
        }
        
        // Pick a random available position
        let randomPosition = availablePositions.randomElement() ?? GridPoint(x: 0, y: 0)
        return Food(position: randomPosition)
    }
}

// MARK: - Game State

/// Represents the current state of the game
enum GameState: Equatable, Sendable {
    case idle       // Game hasn't started yet
    case playing    // Game is actively running
    case paused     // Game is paused
    case gameOver   // Game has ended
}
