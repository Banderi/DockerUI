extends Control

var curves = []

func draw_spline(curve, points):
	if curve[3]:
		draw_polyline(points, Color(0.5,1,1,1), 2.0)
	elif curve[2]:
		draw_polyline(points, Color(1,1,1,1), 2.0)
	else:
		draw_polyline(points, Color(1,1,1,0.5), 2.0)

func add_spline(curve):
	curves.push_back(curve)

func _draw():
	# draw splines
	for curve in curves:
		var points = curve[0].get_baked_points()
		for p in points.size():
			points[p] = points[p] + curve[1].get_global_position() - get_global_position()
		draw_spline(curve, points)
	curves = []

#	if curve1 != null:
#		var points = curve1[0].get_baked_points()
#		for p in points.size():
#			points[p] = points[p] + curve1[1].get_global_position() - get_global_position()
#		draw_spline(curve1, points)
#	if curve2 != null:
#		var points = curve2[0].get_baked_points()
#		for p in points.size():
#			points[p] = points[p] + curve2[1].get_global_position() - get_global_position()
#		draw_spline(curve2, points)
#
#	curve1 = null
#	curve2 = null

func _process(delta):
	update()
