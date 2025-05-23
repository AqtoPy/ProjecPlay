extends CharacterBody3D

# Настройки движения
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.1

# Настройки headbob
@export var bob_frequency := 2.0
@export var bob_amplitude := 0.08
var bob_time := 0.0

# Настройки камеры
@export var camera_path: NodePath
var camera: Camera3D
var base_camera_height := 0.0

# Настройки падения
@export var fall_damage_threshold := 15.0
@export var max_fall_damage := 50.0
var was_on_floor := true
var fall_start_height := 0.0

# Состояние игрока
var health := 100.0
var is_sprinting := false
var current_speed := walk_speed

# Физические параметры
@export var gravity_multiplier := 2.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
    camera = get_node(camera_path)
    base_camera_height = camera.position.y
    
    # Захват мыши
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    # Вращение камеры с помощью мыши
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
        camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
        camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
    
    # Выход из игры по ESC
    if event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
    # Получаем ввод движения
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    # Применяем гравитацию
    if not is_on_floor():
        velocity.y -= gravity * gravity_multiplier * delta
    
    # Обработка прыжка
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    
    # Проверка на спринт
    is_sprinting = Input.is_action_pressed("sprint")
    current_speed = sprint_speed if is_sprinting else walk_speed
    
    # Движение по земле
    if is_on_floor():
        if direction:
            velocity.x = direction.x * current_speed
            velocity.z = direction.z * current_speed
        else:
            velocity.x = move_toward(velocity.x, 0, current_speed)
            velocity.z = move_toward(velocity.z, 0, current_speed)
    
    # Применяем headbob при движении
    if is_on_floor() and (velocity.x != 0 or velocity.z != 0):
        bob_time += delta * current_speed * (1.0 if is_sprinting else 0.5)
        var bob_amount = sin(bob_time * bob_frequency) * bob_amplitude * (0.5 if is_sprinting else 1.0)
        camera.position.y = base_camera_height + bob_amount
    else:
        # Плавный возврат камеры в исходное положение
        camera.position.y = lerp(camera.position.y, base_camera_height, delta * 5.0)
        bob_time = 0.0
    
    # Обработка падения и урона
    if is_on_floor():
        if not was_on_floor:
            handle_fall_damage()
        was_on_floor = true
        fall_start_height = global_position.y
    else:
        was_on_floor = false
    
    move_and_slide()

func handle_fall_damage():
    var fall_distance = fall_start_height - global_position.y
    if fall_distance > fall_damage_threshold:
        var damage = remap(fall_distance, fall_damage_threshold, fall_damage_threshold * 2, 0, max_fall_damage)
        damage = clamp(damage, 0, max_fall_damage)
        health -= damage
        print("Fall damage taken: ", damage, " | Health remaining: ", health)
        
        # Эффект тряски камеры при получении урона
        var shake_amount = min(damage / 10.0, 0.5)
        camera.rotation.x += randf_range(-shake_amount, shake_amount)
        camera.rotation.z += randf_range(-shake_amount, shake_amount)
