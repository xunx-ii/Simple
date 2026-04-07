class_name HitSparkEffect
extends Node2D

const PLACEHOLDER_TEXTURE := preload("res://assets/textures/placeholder.png")
const DEFAULT_COLOR := Color(1.0, 0.878431, 0.533333, 0.95)
const PARTICLE_COUNT := 5
const LIFETIME := 0.18
const DRAG := 16.0

var base_color: Color = DEFAULT_COLOR
var outward_direction: Vector2 = Vector2.UP
var remaining_lifetime: float = LIFETIME
var particles: Array = []
var velocities: Array = []
var rotations: Array = []
var particle_built: bool = false

func _ready() -> void:
    z_index = 6
    _build_particles()

func _process(delta: float) -> void:
    remaining_lifetime = max(remaining_lifetime - delta, 0.0)
    if remaining_lifetime <= 0.0:
        queue_free()
        return

    var alpha_ratio: float = remaining_lifetime / LIFETIME

    for index in range(particles.size()):
        var particle := particles[index] as Sprite2D
        var velocity: Vector2 = velocities[index]
        velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)
        velocities[index] = velocity
        particle.position += velocity * delta
        particle.rotation += rotations[index] * delta

        var color := particle.modulate
        color.a = base_color.a * alpha_ratio
        particle.modulate = color

func setup(hit_normal: Vector2, config: Dictionary = {}) -> void:
    base_color = config.get("color", DEFAULT_COLOR)
    outward_direction = hit_normal.normalized() if hit_normal != Vector2.ZERO else Vector2.UP
    remaining_lifetime = LIFETIME

    if is_node_ready():
        _build_particles()

func _build_particles() -> void:
    if particle_built:
        for child in particles:
            var particle := child as Sprite2D
            if particle != null:
                particle.queue_free()

        particles.clear()
        velocities.clear()
        rotations.clear()

    particle_built = true

    for _index in range(PARTICLE_COUNT):
        var particle := Sprite2D.new()
        particle.texture = PLACEHOLDER_TEXTURE
        particle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        particle.scale = Vector2.ONE * randf_range(0.05, 0.12)
        particle.modulate = base_color.lerp(Color.WHITE, randf_range(0.15, 0.55))
        add_child(particle)

        var spread_direction := outward_direction.rotated(randf_range(-1.2, 1.2)).normalized()
        particles.append(particle)
        velocities.append(spread_direction * randf_range(42.0, 92.0))
        rotations.append(randf_range(-9.0, 9.0))
