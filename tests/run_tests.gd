extends SceneTree
## Headless tests. Run with:
##   godot_console --headless --path . --script res://tests/run_tests.gd
## Exits with 0 when everything passes, 1 otherwise. The tests live in test_suite.gd, which is
## loaded at run time because this entry script can't see the autoloads when it compiles.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var suite: Node = load("res://tests/test_suite.gd").new()
	suite.name = "TestSuite"
	root.add_child(suite)
	suite.finished.connect(func(failed: int): quit(1 if failed > 0 else 0))
	suite.run()
