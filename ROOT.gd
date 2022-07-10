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
func record_image(obj):
	DATA.images.push_back(obj);
func record_container(obj):
	DATA.containers.push_back(obj);

onready var vlist_IMAGES = $TabContainer/Dashboard/simpler/images/Panel/VBoxContainer
onready var vlist_CONTAINERS = $TabContainer/Dashboard/simpler/containers/Panel/VBoxContainer
onready var BTN_IMAGE = load("res://ListElements/Image.tscn")
onready var BTN_CONTAINER = load("res://ListElements/Container.tscn")
func unpopulate():
	for b in vlist_IMAGES.get_children():
		b.free()
	for b in vlist_CONTAINERS.get_children():
		b.free()
func populate():
	unpopulate()
	for image in DATA.images:
		var node = BTN_IMAGE.instance()
		node.text = image.repository + ":" + image.tag
		vlist_IMAGES.add_child(node)
	for container in DATA.containers:
		var node = BTN_CONTAINER.instance()
		node.text = container.names
		vlist_CONTAINERS.add_child(node)

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
		if line == "":
			continue
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
	refresh_pending_cmd -= 1
func _callb_containters(output):
	t_CONTAINERS.text = ""
	DATA.containers = []

	var l = 0
	var ref = []
	output = output.split("\n")
	for line in output:
		if line == "":
			continue
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
	refresh_pending_cmd -= 1

var waiting_for_refresh = false
var refresh_pending_cmd = 0
func refresh(manual = false):
	Shell.run("docker image list", self, "_callb_images", manual, manual)
	Shell.run("docker container list", self, "_callb_containters", manual, manual)
	refresh_pending_cmd = 2

func _on_Refresh_action_pressed():
	refresh(true)
func _on_Timer_timeout():
	refresh()
	pass
func _process(delta):
	if refresh_pending_cmd == 0:
		if waiting_for_refresh:
			$TabContainer/Dashboard/Refresh.done(null)
			waiting_for_refresh = false
			populate()
	else:
		waiting_for_refresh = true



###

var docker_version = null
func _ready():
	unpopulate()

	# init console
	Console.node = $TabContainer/Dashboard/OUTPUT
	Console.clear()
	Console.out("*** CONSOLE IS ALIVE ***", Color(0.5,1,1,1))

	# get docker version
	var ver = Shell.run_sync("docker version --format {{.Server.Version}}", false)
#	var ver = Shell.run_sync("docker version --format '{{json .}}'", false)
	if ver != []:
		docker_version = ver[0]
#		docker_version = JSON.parse(ver[0]).get_result()
		Console.out('Docker server version: ' + docker_version, Color(0.5,1,1,0.5), "")
	else:
		Console.out('ERROR: Docker enumeration failed!', Color(1,0,0,1), "")
		return

	$TabContainer/Dashboard/DockerUI/DockerVersion.text = "Docker Version: " + str(docker_version)
	refresh()
#	Console.out("Daemon (refresh) started", Color(0.5,1,1,0.5))
	imgPATH.text = $FileDialog.current_path
	Global.splinecanvas = $TabContainer/Dashboard/CanvasLayer

###

onready var imgPATH = $TabContainer/Dashboard/PATH
func _on_SelectPath_pressed():
	$FileDialog.popup()
func _on_FileDialog_dir_selected(dir):
	imgPATH.text = dir
func _on_PATH_gui_input(event):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == BUTTON_LEFT:
		$FileDialog.popup()

func _on_Unselect_pressed():
	# we'll do both at once, cuz it's easier, it works, and I'm lazy!
	for b in vlist_IMAGES.get_children():
		b.unselect()
	for b in vlist_CONTAINERS.get_children():
		b.unselect()

func _on_RebuildImage_action_pressed():
	pass # Replace with function body.


func _on_CMD_text_changed(new_text):
	$TabContainer/Dashboard/CMD/AsyncShellBtn.cmd = new_text
func _on_CMD_text_entered(new_text):
	$TabContainer/Dashboard/CMD/AsyncShellBtn.cmd = new_text
	$TabContainer/Dashboard/CMD/AsyncShellBtn._on_AsyncShellBtn_pressed()
func _on_ClearConsole_pressed():
	Console.clear()
