@tool
## Quickly fade in text glyph by glyph when it's added to tree. Like visual
## novel text.
class_name RichTextFadeIn
extends RichTextEffect


var bbcode := "fade_in"

## Speed of the text appears. In character / second
var speed := 160

## Speed of the text appears. In character / second
var faded_char_n := 40


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color.a = clamp((char_fx.elapsed_time * speed - char_fx.relative_index) / faded_char_n, 0, 1)
	char_fx.visible = char_fx.color.a > 0
	return true
