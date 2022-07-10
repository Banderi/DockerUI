extends Button
class_name ElemGeneric

onready var vlist_self = get_parent()
onready var hbox = vlist_self.get_parent().get_parent().get_parent()

var selected = false
func select():
	pressed = true
	selected = true
func unselect():
	pressed = false
	selected = false
	release_focus()

func _on_Button_pressed():
	for ctrl in hbox.get_children():
		var vlist = ctrl.get_node("Panel/VBoxContainer")
		for b in vlist.get_children():
			b.unselect()
	# the above fires *after* Godot has set the press, so we need to do it again >:/
	select()
