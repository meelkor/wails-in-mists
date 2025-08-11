@tool
@abstract
class_name CharacterVisuals
extends Resource


## Create new CharacterScene (with all exported paths correctly set) which
## contains the character's model with all attachments etc. (such as hair)
## based on this resource's configuration (if any, depends on implementation).
##
## Each character has unique instance of this class and thus it may store
## character-specific data (e.g. the scene so it can be changed in update_scene
## call)
##
## Called whenever some change ocurred to the character (equipment changed,
## combat state changed etc.). Should modify the scene that was originally
## created by make_scene to match that scene.
##
## It is also called right after the scene is created to initialize the model
## with equipment etc.
## todo comment
@abstract
func make_scene(character: GameCharacter, in_combat: bool) -> CharacterScene
