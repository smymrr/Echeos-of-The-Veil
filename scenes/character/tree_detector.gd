extends Area2D

@export var tree_front_z_index: int = 10
@export var tree_faded_alpha: float = 0.4
@export var tree_fade_time: float = 0.15

var _tree_tweens: Dictionary = {}      # tree -> Tween
var _tree_default_z: Dictionary = {}   # tree -> original z_index


func _ready() -> void:
	self.area_entered.connect(_on_tree_area_entered)
	self.area_exited.connect(_on_tree_area_exited)


func _get_tree_from_area(area: Area2D) -> Node2D:
	var tree := area.get_parent() as Node2D
	print(tree.name)
	if tree and tree.is_in_group("trees"):
		print('is a tree')
		return tree
	return null


func _on_tree_area_entered(area: Area2D) -> void:
	print("entered")
	var tree := _get_tree_from_area(area)
	if tree == null:
		return
	if not _tree_default_z.has(tree):
		_tree_default_z[tree] = tree.z_index
	tree.z_index = tree_front_z_index
	_fade_tree(tree, tree_faded_alpha)


func _on_tree_area_exited(area: Area2D) -> void:
	var tree := _get_tree_from_area(area)
	if tree == null:
		return
	tree.z_index = _tree_default_z.get(tree, 0)
	_fade_tree(tree, 1.0)


func _fade_tree(tree: Node2D, target_alpha: float) -> void:
	if _tree_tweens.has(tree) and _tree_tweens[tree].is_valid():
		_tree_tweens[tree].kill()
	var tween := create_tween()
	tween.tween_property(tree, "modulate:a", target_alpha, tree_fade_time)
	_tree_tweens[tree] = tween
