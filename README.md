# The Doors

`The Doors` is a first-person horror prototype built with Godot. The project focuses on tense exploration, atmospheric presentation, interactive doors, and a procedural room-streaming system that can stitch together standard rooms, hallways, and rarer maze sections.

## Overview

The game currently includes:

- A main menu and pause flow
- A first-person player controller with mouse look
- Door interaction through a forward raycast
- Footstep and landing audio
- Procedurally spawned room segments
- Weighted random room selection
- A reusable world environment resource
- A debug fly mode for fast testing

This repository is still actively in progress, so some systems are functional prototypes rather than final gameplay implementations.

## Built With

- [Godot 4.6](https://godotengine.org/)
- Jolt Physics for 3D physics
- GDScript

## Project Structure

Key folders:

- [`assets`](C:/Users/Lenovo/Documents/the-doors/assets): source assets organized by type
- [`assets/images`](C:/Users/Lenovo/Documents/the-doors/assets/images): UI textures and material textures
- [`assets/music`](C:/Users/Lenovo/Documents/the-doors/assets/music): music, ambience, and sound effects
- [`assets/blender`](C:/Users/Lenovo/Documents/the-doors/assets/blender): Blender-authored 3D source assets
- [`materials`](C:/Users/Lenovo/Documents/the-doors/materials): shared rendering resources such as the world environment
- [`scenes`](C:/Users/Lenovo/Documents/the-doors/scenes): Godot scenes for rooms, menus, player, and environment pieces
- [`scripts`](C:/Users/Lenovo/Documents/the-doors/scripts): gameplay and scene logic
- [`fonts`](C:/Users/Lenovo/Documents/the-doors/fonts): project fonts used by the UI

Important scenes:

- [`scenes/main.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/main.tscn): main gameplay scene
- [`scenes/main_menu.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/main_menu.tscn): starting menu scene
- [`scenes/player.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/player.tscn): player character setup
- [`scenes/room.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/room.tscn): base room segment
- [`scenes/hallway.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/hallway.tscn): hallway variation
- [`scenes/hallway_long.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/hallway_long.tscn): longer hallway variation
- [`scenes/maze1.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/maze1.tscn): rare maze segment

Important scripts:

- [`scripts/player.gd`](C:/Users/Lenovo/Documents/the-doors/scripts/player.gd): movement, mouse look, head bob, cursor, sprint, jump, and debug fly mode
- [`scripts/world_generator.gd`](C:/Users/Lenovo/Documents/the-doors/scripts/world_generator.gd): procedural room spawning and weighted selection
- [`scripts/raycast.gd`](C:/Users/Lenovo/Documents/the-doors/scripts/raycast.gd): interact detection
- [`scripts/door.gd`](C:/Users/Lenovo/Documents/the-doors/scripts/door.gd): door interaction logic
- [`scripts/main.gd`](C:/Users/Lenovo/Documents/the-doors/scripts/main.gd): pause panel behavior
- [`scripts/main_menu.gd`](C:/Users/Lenovo/Documents/the-doors/scripts/main_menu.gd): start button flow

## Current Gameplay Systems

### Player Controller

The player uses a `CharacterBody3D` setup with:

- WASD-style movement
- mouse-look camera rotation
- jump and sprint
- head bob while moving
- footstep audio while grounded
- landing sound feedback

### Interaction

The player can interact with doors using a forward raycast. When the target collider exposes an `interact()` method and the interact key is pressed, the door logic is triggered and the global door counter is incremented.

### Procedural Room Generation

The world generator keeps a rolling set of active room segments around the player and spawns new segments when the player approaches either edge of the current streamed layout.

Current weighted room pool:

- standard room: common
- hallway: common
- long hallway: uncommon
- maze section: rare

The generator also avoids immediately repeating the exact previous room type.

### Menus and UI

The project includes:

- a main menu scene
- a pause overlay panel
- custom UI fonts
- a custom in-game cursor while the mouse is captured

## Controls

Current input bindings from [`project.godot`](C:/Users/Lenovo/Documents/the-doors/project.godot):

- `W / A / S / D` or arrow keys: move
- `Mouse`: look
- `Space`: jump
- `E`: interact
- `Shift`: sprint toggle
- `Esc`: pause
- `F`: toggle fly mode
- `Ctrl`: descend while flying

Fly mode is intended as a development/testing tool and is not necessarily a final gameplay mechanic.

## Getting Started

### Requirements

- Godot 4.6

### Open the Project

1. Clone this repository.
2. Open Godot 4.6.
3. Import the project by selecting [`project.godot`](C:/Users/Lenovo/Documents/the-doors/project.godot).
4. Run the main scene configured by the project.

### Running the Game

The project is configured to launch `The Doors` through its assigned main scene in the project settings. You can also open [`scenes/main_menu.tscn`](C:/Users/Lenovo/Documents/the-doors/scenes/main_menu.tscn) directly in the editor if you want to begin from the menu scene.

## Asset Organization

The asset tree is intentionally grouped by source type:

- `assets/images`: textures, UI art, and image-based materials
- `assets/music`: music tracks, ambient audio, and sound effects
- `assets/blender`: `.blend` source files used for imported meshes and scene assets

Godot `.import` sidecar files are kept alongside their source files so imported resources stay linked correctly.

## Notes for Development

- Godot editor-generated temp scene files may appear during editing sessions.
- The project includes an enabled plugin at [`addons/godot_super-wakatime`](C:/Users/Lenovo/Documents/the-doors/addons/godot_super-wakatime).
- Some gameplay systems are still prototype-level and may be changed significantly as development continues.

## Roadmap Ideas

Possible next steps for the project:

- expand room variety and procedural rules
- add enemy encounters or chase events
- create a proper settings menu
- add save/progression systems
- improve sound design and reactive ambience
- formalize win and lose conditions

## License

See [`LICENSE`](C:/Users/Lenovo/Documents/the-doors/LICENSE).
