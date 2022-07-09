extends Node

var thread_for_execute = null
var queue_for_execute = []

######## Begin # OS.execute() Threaded ########
func run(cmd, callback_node, callback_func):
	if thread_for_execute == null:
		thread_for_execute = Thread.new()
	var output = []
	var state = 'waiting'
	var task = [output, cmd, callback_node, callback_func, state]
	queue_for_execute.append(task)
	if queue_for_execute.size() == 1:
		# Only item in the list so start the task.
		call_deferred('defered_start_execute')

func defered_start_execute():
	queue_for_execute[0][4] = 'executing'
	var args = [queue_for_execute[0][0], queue_for_execute[0][1], queue_for_execute[0][2], queue_for_execute[0][3]]
	thread_for_execute.start(self, '_threaded_execute', args)

func _threaded_execute(args):
	print('sh# \"', args[1], '\"')
	var output = args[0]
	if args[1] == "": # Empty command!!
		call_deferred('_clean_up_execute_thread')
		return args
	var cmd = args[1].split(" ")
	var bin = cmd[0]
	cmd.remove(0)
	var callback_node = args[2]
	var callback_func = args[3]
	OS.execute(bin, cmd, true, output)
	args[0] = output
	call_deferred('_clean_up_execute_thread')
	return args

func _clean_up_execute_thread():
	var args = thread_for_execute.wait_to_finish()
	var output = args[0]
	var cmd = args[1]
	var callback_node = args[2]
	var callback_func = args[3]
#	var callable_node = get_node(callback_node)
	var callable_func = funcref(callback_node, callback_func)
	callable_func.call_func(output[0])
	queue_for_execute.pop_front()
	if queue_for_execute.size() > 0:
		# Start the next task.
		call_deferred('defered_start_execute')
	elif queue_for_execute.size() == 0:
		thread_for_execute = null
######## End # OS.execute() Threaded ########
