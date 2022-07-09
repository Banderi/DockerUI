extends Control

func is_bit_enabled(mask, index):
	return mask & (1 << index) != 0
func enable_bit(mask, index):
	return mask | (1 << index)
func disable_bit(mask, index):
	return mask & ~(1 << index)

# data!
var DATA = {
	"images":[],
	"containers":[]
}

# threaded semaphore
var ready = 3

func record_image(obj):
	DATA.images.push_back(obj);
func record_container(obj):
	DATA.containers.push_back(obj);

func unpopulate():
	pass
func populate():
	unpopulate()
	pass

onready var t_IMAGES = $TabContainer/Raw/IMAGES
onready var t_CONTAINERS = $TabContainer/Raw/CONTAINERS

func substr(string, ref, index):
	if index >= ref.size():
		return ""
	if index + 1 >= ref.size():
		return string.substr(ref[index], string.length()-ref[index]).strip_edges()
	return string.substr(ref[index], ref[index+1]-ref[index]).strip_edges()
func _callb_images(output):
	t_IMAGES.text = ""
	DATA.images = []

	var l = 0
	var ref = []
	output = output.split("\n")
	for line in output:
		t_IMAGES.text += line
		t_IMAGES.text += "\n"
		if l > 0: # skip first line
			record_image({
				"repository":substr(line, ref, 0),
				"tag":substr(line, ref, 1),
				"id":substr(line, ref, 2),
				"created":substr(line, ref, 3),
				"size":substr(line, ref, 4),
			})
		else:
			ref.push_back(0)
			ref.push_back(line.find("TAG"))
			ref.push_back(line.find("IMAGE ID"))
			ref.push_back(line.find("CREATED"))
			ref.push_back(line.find("SIZE"))
		l += 1
	ready = enable_bit(ready, 0)
func _callb_containters(output):
	t_CONTAINERS.text = ""
	DATA.containers = []

	var l = 0
	var ref = []
	output = output.split("\n")
	for line in output:
		t_CONTAINERS.text += line
		t_CONTAINERS.text += "\n"
		if l > 0: # skip first line
			record_container({
				"id":substr(line, ref, 0),
				"image":substr(line, ref, 1),
				"command":substr(line, ref, 2),
				"created":substr(line, ref, 3),
				"status":substr(line, ref, 4),
				"ports":substr(line, ref, 5),
				"names":substr(line, ref, 6),
			})
		else:
			ref.push_back(0)
			ref.push_back(line.find("IMAGE"))
			ref.push_back(line.find("COMMAND"))
			ref.push_back(line.find("CREATED"))
			ref.push_back(line.find("STATUS"))
			ref.push_back(line.find("PORTS"))
			ref.push_back(line.find("NAMES"))
		l += 1
	ready = enable_bit(ready, 1)

func refresh():
	if is_bit_enabled(ready, 0):
		ready = disable_bit(ready, 0)
		Shell.run("docker image list", self, "_callb_images")
	else:
		print("Waiting...(0)")
	if is_bit_enabled(ready, 1):
		ready = disable_bit(ready, 1)
		Shell.run("docker container list", self, "_callb_containters")
	else:
		print("Waiting...(1)")

###

func _ready():
	refresh()
	imgPATH.text = $FileDialog.current_path
	Global.splinecanvas = $TabContainer/Dashboard/CanvasLayer

func _on_Timer_timeout():
	refresh()

###

func _on_SelectPath_pressed():
	$FileDialog.popup()

onready var imgPATH = $TabContainer/Dashboard/PATH

func _on_FileDialog_dir_selected(dir):
	imgPATH.text = dir

func _on_PATH_gui_input(event):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == BUTTON_LEFT:
		$FileDialog.popup()

func _on_RebuildImage_pressed():
	pass # Replace with function body.
