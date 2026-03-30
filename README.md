# The Doors 

The Doors is a first-person atmospheric horror game I built with Godot 4.6. It currently includes 10 different  rooms each with an atmosphere with its own. The main objective of the room is get to room 25, where the game currently ends.
Inspired by "The Backrooms," the game features an infinite loop of rooms (coming soon) , upgrades purchased with coins you find throughout the rooms , and a custom-built character controller that gives eerie vibes.


# Play it Online

[The Doors](https://baralekogyan.itch.io/the-doors)

# Key Technical Features
The core of the game is a weight-based room spawner that spawns rooms one after another using a weighted randomized selection.

Dynamic Loading: To maintain high FPS, the system only keeps 3 active room segments loaded in the scene tree at any given time. The three rooms are; the room the player is currently in, one room behind the player, and one room in front of the player.

Culling Logic: Older rooms are freed once the player moves a certain distance, to prevent lag spikes and fps drops.

Randomization: Uses a weighted selection algorithm to ensure a balanced mix of "safe" rooms and rooms with strange creatures never seen before.

# Player Controller & Interaction
The main player is built using CharacterBody3D with the following implementations:

Movement: WASD/Arrow keys with integrated head-bob including sprinting (Ctrl to toggle) and crouching (Shift hold to toggle). 

Interaction: Interaction with the static assets is done with collision shapes instead of raycast. When inside the collision shape, a [E] prompt is visible and when [E] is pressed the assets have their respective interactions.

Audio: Eerie raining background music with footsteps everytime the player walks has currently been implemented. All the interactable assets also have their own sound effects.

# Physics & Performance
Jolt Physics: Integrated the Godot Jolt plugin for more stable 3D character collisions and better performance over the default GodotPhysics3D.

Debug Fly Mode: A dedicated debug build allows for F key toggling of a "Noclip" fly mode to inspect room stitching and collision boundaries in real-time.

# Built With
Godot V4.6
GDScript (as the main scripting language)
Jolt 3D (Physics Engine)
Blender (To design low poly assets)

# How to Play / Test
You can play the game online at [The Doors](https://baralekogyan.itch.io/the-doors)
You can play the debug version online at [The Doors Debug](https://baralekogyan.itch.io/the-doors-debug)

Optionally, You can also clone the repo and open it with godot and make any changes you wish there.

# Controls:

WASD / Arrows: Move

Space: Jump

Ctrl: Toggle Sprint

Shift: Sneaking/ Crouching

E: Interact

F: Toggle Fly Mode (Debug builds only)

P : Pause the game

Optionally, you can also change the controls in the settings menu!

# Inspiration
My main inspiration to build this copy was the Roblox game 'Doors'. I've always been fascinated by the concept of the game and wanted to recreate it on my own, add new features and improve the overall gameplay loop. I've always been fascinated by 3D games and I took this opportunity to make one on my own.
# Development Status
This is my first 3D project, and I am currently pushing updates every few days.
