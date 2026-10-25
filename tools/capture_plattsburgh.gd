extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(1440,900)
 var world:Node3D=load("res://world/handbuilt/plattsburgh_region.scn").instantiate();root.add_child(world);current_scene=world
 for i in range(90):await process_frame
 var output:="C:/Users/joshu/Documents/Codex/2026-10-18/referenced-chatgpt-conversation-this-is-an/outputs/"
 world.car.set_physics_process(false)
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"REVVED-Plattsburgh-Driving.png")
 var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(160,260,260);camera.look_at(Vector3(0,12,0));camera.far=5000;camera.current=true
 for i in range(30):await process_frame
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"REVVED-Plattsburgh-Downtown.png")
 print("REGION CAPTURE PASS");quit()
