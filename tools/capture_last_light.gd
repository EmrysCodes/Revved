extends SceneTree
const OUT="C:/Users/joshu/Documents/Codex/2026-10-18/referenced-chatgpt-conversation-this-is-an/outputs/"
func _initialize()->void:call_deferred("run")
func frames(count:int)->void:
	for i in range(count):await process_frame
func shot(label:String)->void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+label+".png");print("CAPTURE ",label)
func attach(path:String)->Control:
	var scene:Control=load(path).instantiate();root.add_child(scene);current_scene=scene;return scene
func clear_scene()->void:
	current_scene.queue_free();await process_frame
func run()->void:
	root.size=Vector2i(1440,900);root.content_scale_size=root.size
	var p:=root.get_node("StreetProfile");p.path="res://tests/capture-story.tmp";p.return_to_legacy=false;p.driver_created=true;p.driver_name="Alex Mercer";p.music_volume=0;p.story_voice=false;p.story_auto=false;p.story_setback_pending=false;p.event_results={};p.series_report=""
	for key:String in p.STORY.data().scenes:p.story_seen[key]=true
	attach("res://ui/front_end/main_menu.tscn");await frames(65);await shot("REVVED-Last-Light-Main-Menu");await clear_scene()
	p.story_request={"key":"capital_run_before","destination":"hub","replay":true}
	var cinema:=attach("res://ui/story/story_scene.tscn");await frames(85);cinema.show_line(1);cinema.subtitle.visible_characters=-1;await frames(20);await shot("REVVED-Last-Light-Cinematic")
	root.size=Vector2i(640,360);root.content_scale_size=root.size;await frames(20);await shot("REVVED-Last-Light-Cinematic-Compact")
	root.size=Vector2i(393,852);root.content_scale_size=root.size;await frames(20);await shot("REVVED-Last-Light-Cinematic-Portrait");await clear_scene()
	root.size=Vector2i(1440,900);root.content_scale_size=root.size
	for id:String in ["capital_run","pearl_dash","bushnell_clock"]:p.event_results[id]={"wins":1}
	attach("res://ui/legacy/legacy_hub.tscn");await frames(35);await shot("REVVED-Last-Light-Story-Map");await clear_scene()
	var browser:=attach("res://ui/front_end/race_browser.tscn");await frames(30);browser.select_event(16);await frames(15);await shot("REVVED-Last-Light-Race-Browser");await clear_scene()
	var menu:=attach("res://ui/front_end/main_menu.tscn");menu.challenge_series();await frames(35);await shot("REVVED-Last-Light-Series");await clear_scene()
	print("LAST LIGHT CAPTURE PASS");quit()
