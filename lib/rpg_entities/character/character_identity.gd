## Contains name and other values that identify this character. Those values
## should be constant and identity should exist as saved resource, so they do
## not appear in saved games (except for PC which needs to be in save.)
@tool
class_name CharacterIdentity
extends Resource

@export var name: String

@export var sex: Sex


enum Sex {
	FEMALE,
	MALE,
	NA,
}
