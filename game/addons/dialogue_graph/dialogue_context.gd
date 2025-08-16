## Structure which is provided to each dialogue step on execution which
## contains its context so it can access various parts of the game etc. This
## context should be same of all the steps so it can only created once.
##
## todo: I hate how "addon" uses part of the game... but there is nothing I can
##  do, is there? maybe leave only the editor portion in the addon and put
##  everything else to game?
class_name DialogueContext
extends RefCounted

var actor: GameCharacter

var dialogue: DialogueGraph

var di: DI
