## Semestral project TRAX Game

### Test project

You can test the program by simply running the “player.py” file. All moves in the game are automatically saved in PNG in the “moves” folder.

### Project description

As semester work, I wrote an algorithm of an AI player for the Trax game, a strategic board game. My role in the project was to implement the AI player in “player.py”, which must make allowed moves and compete against other players.

More about TRAX game rules:  https://en.wikipedia.org/wiki/Trax_(game)

### Features and Functionality

**Board representation:** The AI player utilizes a 2D array to represent the game board, where each cell can hold a Trax tile. The board's dimensions are adjustable, allowing for various grid sizes.
**My strategy:** The AI player scans the board for 1 move forward, finds the cycle that is most likely to be closed in the next step and makes the appropriate move.
**Forced moves:** In certain situations, tile placements create obligations for subsequent moves. The AI player can simulate and identify forced moves, adjusting its placement strategy accordingly.
**Valid tile selection:** To ensure legality and optimize its moves, the AI player identifies valid tiles based on the required colors and available options.
