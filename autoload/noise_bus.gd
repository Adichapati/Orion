extends Node
## Every loud action calls NoiseBus.emit_noise(); guards in range hear it and investigate.
## Radii are in tiles, measured in grid space: walking 2, running 5, a pot smashing 6, a clash 8.

signal noise(pos: Vector2, radius: float, source: Node)

## Recent noises, kept briefly so the F3 overlay can draw them as rings.
var recent: Array = []


func emit_noise(pos: Vector2, radius: float, source: Node = null) -> void:
	if radius <= 0.0:
		return
	noise.emit(pos, radius, source)
	recent.append({"pos": pos, "radius": radius, "age": 0.0})


func _process(delta: float) -> void:
	for n in recent:
		n.age += delta
	recent = recent.filter(func(n): return n.age < 0.8)
