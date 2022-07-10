extends Node

var node = null

func clear():
	node.text = ""

func out(txt, color = Color(1,1,1,1), endl = "\n"):
	print(txt)
#	node.text += txt
#	node.text += "\n"
	var html = color.to_html()
	node.append_bbcode("[color=#" + html + "]" + txt + "[/color]" + endl)
