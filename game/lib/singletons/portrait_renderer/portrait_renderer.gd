## Singleton node for rendering character portraits
extends Node

const PortraitViewport = preload("./portrait_viewport.gd")


## Render and cache portrait for given character
func render(character: GameCharacter) -> Texture:
	if not character.cached_portrait:
		var viewport := preload("./portrait_viewport.tscn").instantiate() as PortraitViewport
		add_child(viewport)
		character.cached_portrait = await viewport.render(character)
		remove_child(viewport)
		get_tree().process_frame.connect(viewport.queue_free)
	return character.cached_portrait
