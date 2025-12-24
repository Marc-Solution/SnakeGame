
# Product Requirements Document (PRD)
## Project: Simple Snake Game
## Platform: iOS (SwiftUI)

### 1. App Overview
A classic Snake game where the player controls a snake on a 2D grid. The snake grows as it eats food. The game ends if the snake hits the wall or its own tail.

### 2. Technical Architecture
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Pattern:** MVVM (Model-View-ViewModel)
- **Compatibility:** iOS 16+

### 3. Core Mechanics
- **Grid System:** A logical grid (e.g., 20x20 columns/rows).
- **Movement:** - The snake moves automatically at a fixed time interval (e.g., 0.2s).
  - Movement is confined to Up, Down, Left, Right.
  - Cannot reverse direction directly (e.g., cannot go Down if currently going Up).
- **Snake:** - Starts as a small chain (e.g., 3 segments).
  - Head leads, body follows.
- **Food:** - Spawns randomly on the grid.
  - Cannot spawn on top of the snake.
- **Collision Rules:**
  - Wall Collision: Game Over.
  - Self Collision: Game Over.

### 4. UI/UX Requirements
- **Game View:**
  - Visual representation of the Grid.
  - Snake: Green squares.
  - Food: Red circle/square.
- **HUD:** - Current Score displayed at the top.
- **Controls:** - Swipe gestures (Up, Down, Left, Right) to change direction.
- **Game Over State:** - Overlay showing "Game Over".
  - "Restart" button to reset the game state.

### 5. Future Scope (Not in MVP)
- High score persistence.
- Difficulty levels (speed increases).
