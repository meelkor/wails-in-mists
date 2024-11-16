<p align="center">
    <img src="https://github.com/meelkor/wails-in-mists/blob/master/resources/logo/wails_transparent_1024.png?raw=true" width=256>
</p>

# Wails in Mists (name subject to change)

First of all: There's no game here at all right now.

This attempt at making a combination of CRPG and roguelite serves as testing
ground while learning Godot and game development in general, so I can maybe
possibly one day make a game or something.

Since this is my first proper contact with Godot and game engines in general I
keep trying various paradigms how to control game state propagate events and
whatnot that may very well go against Godot's design patterns but I just wanna
try what works best for me. And thus there's like zero consistency.

## File structure

Struggling with deciding on a structure I like, but as of now:

* **effects** - scenes of gfx such as weapon effect, projectiles etc
* **game_resources** - actual game content resources such as npcs, items, dialogue scripts
* **gui** - all kinds building blocks for the GUI
* **import_scripts** - all godot import scripts
* **levels** - whole level (locations) scenes with their level-specific resources
* **lib** - all the game logic, resource classes and lower level building blocks
* **materials** - reusable mesh materials
* **models** - reusable 3D models, sometimes can be used directly in level scene
* **resources** - other godot resources like fonts, icons, general textures, styles, curves
* **rust** - rust version of lib/ since I don't wanna create mod files everywhere just to be able to put the rust files where they belong hierarchically
* **scenes** - (todo: rename) building blocks of game levels / environment
