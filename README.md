# Wails in Mists (name subject to change)

Attempt at making a combination of CRPG and roguelite. Very early stages of
development. Basically still learning Godot and everything regarding graphics,
game design, texture art and whatnot.

## File structure

Struggling with deciding on a structure I like, but as of now:

* **effects** - scenes of gfx such as weapon effect, projectiles etc
* **game_resources** - actual game content resources such as npcs, items, dialogue scripts
* **gui** - all kinds building blocks for the GUI
* **import_scripts** - all godot import scripts
* **levels** - whole level (locations) scenes with their level-specific resources
* **lib** - all the game logic and lower level building blocks
* **materials** - reusable mesh materials
* **models** - reusable 3D models, sometimes can be used directly in level scene
* **resources** - other godot resources like fonts, icons, general textures, styles, curves
* **rust** - rust version of lib/ since I don't wanna create mod files everywhere just to be able to put the rust files where they belong hierarchically
* **scenes** - (todo: rename) building blocks of game levels / environment
