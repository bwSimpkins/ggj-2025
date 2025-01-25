extends TileMapLayer

@export var width: int = 10
@export var height: int = 20

func _ready():
	for y in range(height):
		for x in range(width):
			var tile_id = 0
			set_cell(Vector2i(x, y), tile_id, Vector2i.ZERO)
