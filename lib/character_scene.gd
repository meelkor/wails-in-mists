## Script that should be used for root node of (for now) humanoid model scenes
## imported from gltf and have the paths set correctly, so we then know which
## mesh is what (body, eyes etc.)
class_name CharacterScene
extends Node3D

@export var body: MeshInstance3D

@export var eyes: MeshInstance3D
