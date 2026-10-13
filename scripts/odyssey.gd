extends Node
# Chapter 13 orchestration. Combat and exploration clocks inherit PAUSABLE.
var settings: Dictionary = {}
var tiamat_seconds := -1.0
var tiamat_started := false
var darkness_started := false
var current: LevelBase
var tiamat_image: Node2D
var pulse_clock := 0.0
var hit_pulse := 0.0
var busy := false
var temporary_effects: Array[Node] = []
var caption: Label

func _ready() -> void:
    settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/odyssey.json"))
    get_node("/root/GameState").run_reset.connect(reset)
    get_node("/root/Cutscene").completed.connect(_cutscene_completed)

func reset() -> void:
    tiamat_seconds=-1
    tiamat_started=false
    darkness_started=false
    busy=false

func decorate(level: LevelBase) -> void:
    current=level
    tiamat_started=false
    tiamat_seconds=-1
    darkness_started=false
    tiamat_image=null
    pulse_clock=0
    if level.level_id=="TiamatZone":
        var prompt: Node2D=load("res://scripts/huluppu_interaction.gd").new()
        level.add_child(prompt)
        if get_node("/root/Story").is_flag("utnapishtim_done"):
            blood(level)
            get_node("/root/Rampage").set_death_suspended(true)
    elif level.level_id=="HuluppuCrown":
        get_node("/root/Rampage").set_death_suspended(true)
        var arena: Node=load("res://scripts/huluppu_arena.gd").new()
        arena.name="Arena"
        level.add_child(arena)
    elif level.level_id=="TiamatCollapsed":
        var trunk:=AssetVisual.add_image(level,"res://assets/props/huluppu_trunk.webp",Vector2(2400,100),Vector2(780,2200),-8)
        trunk.name="CollapsedHuluppu"
        trunk.rotation=PI*.5
        trunk.modulate=Color(.13,.14,.21)
        tiamat_image=AssetVisual.add_image(level,"res://assets/backgrounds/tiamat/entity.webp",Vector2(1900,0),Vector2(1600,1120),-5)
        tiamat_image.name="TiamatEntity"
        var fade_shader:=Shader.new()
        fade_shader.code="shader_type canvas_item; void fragment(){ COLOR.a *= smoothstep(0.0,0.22,UV.x); }"
        var fade_material:=ShaderMaterial.new()
        fade_material.shader=fade_shader
        tiamat_image.get_node("Image").material=fade_material
        tiamat_image.modulate=Color(.35,.27,.38)
        var body: Node2D=load("res://scripts/tiamat_body.gd").new()
        body.position=Vector2(float(settings["tiamat_body_x"]),880)
        level.add_child(body)
        if get_node("/root/Story").is_flag("tiamat_talk_done") and not get_node("/root/Story").is_flag("choice_pending"):
            tiamat_seconds=float(settings["tiamat_free_seconds"])
            tiamat_started=true

func blood(level: LevelBase) -> void:
    if level.has_node("UtnapishtimBlood"):
        return
    var pos: Array=settings["blood_position"]
    var size_px: Array=settings["blood_size"]
    var pool:=AssetVisual.add_image(level,"res://assets/props/utnapishtim_blood.webp",Vector2(float(pos[0]),float(pos[1])),Vector2(float(size_px[0]),float(size_px[1])),-1)
    pool.name="UtnapishtimBlood"

func _process(delta: float) -> void:
    if not is_instance_valid(current) or get_node("/root/GameState").active_character=="siyavash":
        return
    if current.level_id=="TiamatCollapsed":
        pulse_clock+=delta
        hit_pulse=maxf(0,hit_pulse-delta)
        if is_instance_valid(tiamat_image):
            tiamat_image.scale=Vector2.ONE*(1+.4*clampf((get_node("/root/SceneManager").player.global_position.x-1600)/1200,0,1)+.013*sin(pulse_clock*1.5)+.035*hit_pulse)
            tiamat_image.modulate.a=clampf((get_node("/root/SceneManager").player.global_position.x-1600)/700,0,1)
        if not tiamat_started and get_node("/root/SceneManager").player.global_position.x>=float(settings["tiamat_trigger_x"]):
            tiamat_started=true
            _talk_tiamat.call_deferred()
        if tiamat_seconds>=0 and not get_node("/root/Dialogue").active and not busy:
            tiamat_seconds=maxf(0,tiamat_seconds-delta)
            if tiamat_seconds<=0 and not darkness_started:
                darkness_started=true
                _darkness.call_deferred()
    if current.level_id in ["HwaniraPlaza","TiamatCollapsed"]:
        var hero: NimrodPlayer=get_node("/root/SceneManager").player
        if (hero.global_position.x<70 and hero.movement_axis()<0) or (hero.global_position.x>float(current.config["width"])-70 and hero.movement_axis()>0):
            get_node("/root/SceneManager").show_toast(str(get_node("/root/Story").settings["rear_locked_message"]),1)

func _talk_tiamat() -> void:
    tiamat_started=true
    if not is_instance_valid(current) or current.level_id!="TiamatCollapsed":
        return
    var visual_pulse:=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_loops()
    if is_instance_valid(tiamat_image):
        visual_pulse.tween_property(tiamat_image,"scale",Vector2.ONE*1.42,.8)
        visual_pulse.tween_property(tiamat_image,"scale",Vector2.ONE*1.32,.8)
    await get_node("/root/Dialogue").play_interaction("tiamat_talk")
    if visual_pulse.is_valid():visual_pulse.kill()
    if is_instance_valid(current) and current.level_id=="TiamatCollapsed" and get_node("/root/Story").is_flag("tiamat_talk_done"):
        tiamat_seconds=float(settings["tiamat_free_seconds"])

func _darkness() -> void:
    var manager: Node=get_node("/root/SceneManager")
    busy=true
    manager.set_player_locked(true)
    # Vignette is a UI effect, then full-screen black. Pauses also stop the tween.
    var mat: ShaderMaterial=get_node("/root/Chapter").vignette.material
    mat.set_shader_parameter("tint",Vector3.ZERO)
    var tween:=create_tween()
    tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("strength",v),0.,1.,float(settings["darkness_seconds"])*.65)
    await tween.finished
    if not is_instance_valid(current) or current.level_id!="TiamatCollapsed":
        busy=false
        return
    await manager._fade_to(1,float(settings["darkness_seconds"])*.35)
    var form: Node=get_node("/root/HumbabaForm")
    if form.engaged():await form.ended
    manager.set_player_locked(true)
    get_node("/root/Story").set_flag("choice_pending")
    get_node("/root/Save").save_checkpoint("choice")
    busy=false
    get_node("/root/Choice").open_systems()

func select_system(id: String) -> void:
    if id!="laochachahra":
        return
    var manager: Node=get_node("/root/SceneManager")
    busy=true
    manager.set_player_locked(true)
    var state: Node=get_node("/root/GameState")
    state.run_flags["selected_system"]=id
    state.run_flags["choice_pending"]=false
    get_node("/root/Story").set_flag("system_laochachahra_selected")
    get_node("/root/Story").set_flag("siyavash_started")
    state.siyavash_progress["started"]=true
    state.switch_character("siyavash")
    get_node("/root/Chapter").caption.text="라오차차흐라 항성계"
    get_node("/root/Chapter").caption.modulate.a=1
    get_node("/root/Chapter").caption.show()
    await get_tree().create_timer(1.8,false).timeout
    get_node("/root/Chapter").caption.hide()
    get_node("/root/Chapter").vignette.material.set_shader_parameter("strength",0)
    await manager.go_to("HwaniraPlaza","Spawn_Start",{"instant":true,"preserve_fade":true})
    manager.set_player_locked(true)
    await manager._fade_to(0,1.2)
    manager.set_player_locked(false)
    manager.player.hp=100
    get_node("/root/Save").save_checkpoint("character")
    busy=false

func event(id: String) -> void:
    var runner: Node=get_node("/root/Cutscene")
    var manager: Node=get_node("/root/SceneManager")
    var hero: NimrodPlayer=manager.player
    var token: int=runner.generation
    match id:
        "utnapishtim_rampage":
            get_node("/root/Rampage").set_death_suspended(true)
            get_node("/root/Rampage").set_value(100)
            var form: Node=get_node("/root/HumbabaForm")
            if form.state=="transforming":await form.transform_resolved
            if runner.generation!=token or not runner.active or form.state!="active":return
            var elder: NPC=current.npcs.get("utnapishtim")
            if not is_instance_valid(elder):return
            runner._control(elder)
            hero.global_position=elder.global_position+Vector2(-130,0)
            hero.facing=1
            var original: Vector2=elder.position
            var elapsed:=0.0
            var index:=0
            while elapsed<float(settings["rampage_attack_seconds"]):
                if runner.generation!=token or not runner.active:
                    if is_instance_valid(elder):elder.position=original
                    return
                for clip: String in ["claw_windup","claw_swipe"]:
                    hero.cinematic_clip=clip
                    hero.cinematic_clock=0
                    form.render(clip,0)
                    var clone:=hero.visual.duplicate() as Sprite2D
                    current.add_child(clone)
                    clone.global_position=hero.visual.global_position
                    clone.modulate=Color(1,.12,.08,.5)
                    clone.z_index=hero.z_index-1
                    runner._control(clone)
                    temporary_effects.append(clone)
                    var trail:=clone.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
                    trail.tween_property(clone,"modulate:a",0.,.3*runner.timing_scale)
                    trail.tween_callback(clone.queue_free)
                    var fx: Node2D=Stage5FX.spawn(current,"guard_spark",elder.global_position+Vector2(0,-70),Vector2(80,80))
                    fx.modulate=Color(1,.12,.12)
                    runner._control(fx)
                    temporary_effects.append(fx)
                    elder.position=original+Vector2(-4 if index%2 else 4,0)
                    get_node("/root/Audio").play_sfx("humbaba_claw")
                    var length: float=float(form.clips[clip]["duration_seconds"])*float(form.settings["combo_time_multiplier"])
                    await runner._wait(length)
                    if runner.generation!=token or not runner.active:return
                    elapsed+=length
                index+=1
            elder.position=original
            await manager._fade_to(1,float(settings["rampage_fade_seconds"])*runner.timing_scale)
            if runner.generation!=token or not runner.active:return
            form.exit(true)
            blood(current)
            get_node("/root/Story").set_flag("utnapishtim_done")
            hero.cinematic_clip="idle"
            hero.cinematic_clock=0
            elder.play_clip("idle")
            await runner._wait(.02)
            await manager._fade_to(0,float(settings["rampage_fade_in_seconds"])*runner.timing_scale)
        "huluppu_climb":
            get_node("/root/Rampage").set_death_suspended(true)
            await runner._step({"type":"walk_to","actor":"player","x":settings["climb_x"],"seconds":.8})
            if runner.generation!=token or not runner.active:return
            hero.cinematic_clip="jump_rise"
            hero.cinematic_clock=0
            runner._control(hero.camera)
            var old_limit: int=hero.camera.limit_top
            hero.camera.limit_top=-1600
            runner.motion=runner.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
            runner.motion.tween_property(hero,"global_position:y",float(settings["climb_y"]),float(settings["climb_seconds"])*runner.timing_scale)
            runner.motion.tween_property(manager._fade_rect,"modulate:a",1.,float(settings["climb_seconds"])*runner.timing_scale)
            await runner.motion.finished
            if runner.generation!=token or not runner.active:
                hero.camera.limit_top=old_limit
                return
            await manager.go_to("HuluppuCrown","Spawn_Entrance",{"instant":true,"preserve_fade":true})
            await manager._fade_to(0,1.2*runner.timing_scale)
        "huluppu_victory":
            await manager._fade_to(1,2*runner.timing_scale)
            if runner.generation!=token or not runner.active:return
            get_node("/root/Story").set_flag("huluppu_boss_done")
            if not get_node("/root/HumbabaForm").engaged():get_node("/root/Rampage").set_value(60)
            get_node("/root/Rampage").set_death_suspended(false)
            await manager.go_to("TiamatCollapsed","Spawn_Start",{"instant":true,"preserve_fade":true})
            await manager._fade_to(0,1.5*runner.timing_scale)

func _cutscene_completed(id: String) -> void:
    if id=="utnapishtim_rampage":
        get_node("/root/Save").save_checkpoint("rampage")
    elif id=="huluppu_victory":
        get_node("/root/Save").save_checkpoint("victory")

func reuse_boss_fx(id: String, at: Vector2, size_px: Vector2) -> Node2D:
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/stage9_fx.json"))[id]
    var fx: Node2D=load("res://scripts/image_effect.gd").new()
    var size: Array=spec["frame_size"]
    fx.configure("res://"+str(spec["path"]),Vector2i(int(size[0]),int(size[1])),int(spec["frames"]),float(spec["duration"]),true,Vector2(float(size[0])*.5,float(size[1])*.5))
    fx.scale=size_px/Vector2(float(size[0]),float(size[1]))
    current.add_child(fx)
    fx.global_position=at
    return fx

func cleanup_effects() -> void:
    for effect in temporary_effects:
        if is_instance_valid(effect):effect.queue_free()
    temporary_effects.clear()
