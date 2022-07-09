tool
extends Button

export(bool) var has_connection_left = true setget setDotLeft
export(bool) var has_connection_right = true setget setDotRight
export(int) var type

export(int) var debug_sibling_index_left = -1
export(int) var debug_sibling_index_right = -1

var sibling_left = null
var sibling_right = null

func setDotLeft(v):
	has_connection_left = v
	$Control/DotLeft.visible = has_connection_left
func setDotRight(v):
	has_connection_right = v
	$Control/DotRight.visible = has_connection_right

onready var vlist_self = get_parent()
onready var hbox = vlist_self.get_parent().get_parent().get_parent()
onready var ctrl_left = hbox.get_child(vlist_self.get_parent().get_parent().get_index() - 1)
onready var ctrl_right = hbox.get_child(vlist_self.get_parent().get_parent().get_index() + 1)
onready var vlist_left = null if ctrl_left == null else ctrl_left.get_node("Panel/VBoxContainer")
onready var vlist_right = null if ctrl_right == null else ctrl_right.get_node("Panel/VBoxContainer")
func get_sibling(direction):
	if direction == "left":
		return sibling_left
	else:
		return sibling_right
func connect_sibling(direction, node):
	if direction == "left":
		# disconnect previous siblings
		if sibling_left != null:
			sibling_left.disconnect_sibling("right")
		sibling_left = node
	else:
		# disconnect previous siblings
		if sibling_right != null:
			sibling_right.disconnect_sibling("left")
		sibling_right = node
	set_conn_point(direction, node)
func disconnect_sibling(direction):
	if direction == "left":
		sibling_left = null
	else:
		sibling_right = null

func refresh_hover():
	if has_connection_left:
		$Control/DotLeft.visible = highlight || selected
#		$Control/DotLeft/MeshInstance2D.visible = !(sibling_left == null)
	if has_connection_right:
		$Control/DotRight.visible = highlight || selected
#		$Control/DotRight/MeshInstance2D.visible = !(sibling_right == null)
	if a_sibling_is_pressed != null && !highlight:
		modulate.a = 0.5
	else:
		modulate.a = 1.0
var a_sibling_is_pressed = null
func hello_neighbor(node):
	a_sibling_is_pressed = node # assume only one at a time could EVER be possible
func nevermind_neighbor(node):
	if a_sibling_is_pressed == node:
		a_sibling_is_pressed = null
var highlight = false
func _on_Control_mouse_entered():
	highlight = true
	refresh_hover()
func _on_Control_mouse_exited():
	highlight = false
	refresh_hover()

var selected = false
func _on_Button_pressed():
	for b in vlist_self.get_children():
		b.pressed = false
		b.selected = false
	self.pressed = true # the above fires *after* Godot has set the press, so we need to do it again >:/
	self.selected = true

func _ready():
	refresh_hover()

func _draw():
	# draw splines
	if a_sibling_is_pressed == null && highlight:
		if has_connection_left && (editing_left || sibling_left != null):
			draw_polyline($PathLeft.curve.get_baked_points(), Color(1,1,1,1), 2.0)
		if has_connection_right && (editing_right || sibling_right != null):
			draw_polyline($PathRight.curve.get_baked_points(), Color(1,1,1,1), 2.0)

var editing_left = false
var editing_right = false
func is_inside_node(pos, node):
	var area = node.get_global_position()
	var size = node.rect_size
	if pos.x >= area.x \
	&& pos.y >= area.y \
	&& pos.x <= area.x + size.x \
	&& pos.y <= area.y + size.y:
		return true
	return false
func greet_neighbor_update(s):
	if editing_left || editing_right:
		s.hello_neighbor(self)
	else:
		s.nevermind_neighbor(self)
func get_hovering_sibling():
	var hovering = null

	# finally, neighbor greeting (for the "a_sibling_is_pressed" variable)
	for cbox in hbox.get_children():
		var vlist = cbox.get_node("Panel/VBoxContainer")
		for s in vlist.get_children():
			if s != self: # ignore ourselves
				greet_neighbor_update(s) # this updates the "a_sibling_is_pressed" variable
				s.refresh_hover()

	# update left-side neighbors
	if editing_left && vlist_left != null:
		for s in vlist_left.get_children():
			var ctrl = s.get_node("Control")
			s.highlight = false
			if is_inside_node(get_global_mouse_position(), ctrl):
				s.highlight = true
				hovering = s
			s.refresh_hover()
	# update right-side neighbors
	if editing_right && vlist_right != null:
		for s in vlist_right.get_children():
			var ctrl = s.get_node("Control")
			s.highlight = false
			if is_inside_node(get_global_mouse_position(), ctrl):
				s.highlight = true
				hovering = s
			s.refresh_hover()
	return hovering
var hovering_sibling = null
func set_conn_point(direction, node):
	# move spline tail to specific node center
	if direction == "left":
		$PathLeft.curve.set_point_position(1, node.get_node("Control/DotRight").get_global_position() - get_global_position())
	else:
		$PathRight.curve.set_point_position(0, node.get_node("Control/DotLeft").get_global_position() - get_global_position())
func _process(delta):
	hovering_sibling = get_hovering_sibling()
	if editing_left:
		if hovering_sibling != null:
			set_conn_point("left", hovering_sibling)
		else:
			$PathLeft.curve.set_point_position(1, get_local_mouse_position())
	if editing_right:
		if hovering_sibling != null:
			set_conn_point("right", hovering_sibling)
		else:
			$PathRight.curve.set_point_position(0, get_local_mouse_position())
	# force redraw of splines
	update()

func refresh_splines_to_connected():
	if sibling_left != null:
		set_conn_point("left", sibling_left)
	if sibling_right != null:
		set_conn_point("right", sibling_right)

func _on_ButtonLeft_button_down():
	editing_left = true
func _on_ButtonLeft_button_up():
	if !editing_left:
		return
	editing_left = false
	if hovering_sibling != null:
		connect_sibling("left", hovering_sibling)
		hovering_sibling.connect_sibling("right", self)
	refresh_splines_to_connected()
func _on_ButtonRight_button_down():
	editing_right = true
func _on_ButtonRight_button_up():
	if !editing_right:
		return
	editing_right = false
	if hovering_sibling != null:
		connect_sibling("right", hovering_sibling)
		hovering_sibling.connect_sibling("left", self)
	refresh_splines_to_connected()
func _input(event):
	if editing_left || editing_right:
		if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT && !event.is_pressed():
			editing_left = false
			editing_right = false
			refresh_splines_to_connected()

func _on_ButtonLeft_mouse_entered_exited():
	if has_connection_left:
		$Control/DotLeft/ButtonLeft.grab_focus()
func _on_ButtonRight_mouse_entered_exited():
	if has_connection_right:
		$Control/DotRight/ButtonRight.grab_focus()
