extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func frames(count:int)->void:
	for i in range(count):await process_frame
func run()->void:
	var p:=root.get_node("StreetProfile");p.path="res://tests/mode-menus.tmp";p.driver_created=true;p.story_seen={"prologue":true};p.event_results={};p.story_setback_pending=false;p.return_to_legacy=false;p.series_report="";p.series_active=false
	var browser:Control=load("res://ui/front_end/race_browser.tscn").instantiate();root.add_child(browser)
	check(browser.visible_events.size()==18 and browser.map.practice_mode,"All courses and map use practice rules")
	browser.district.select(2);browser.discipline.select(3);browser.refresh()
	check(browser.visible_events.size()==1 and browser.selected==11,"Combined coast and time-attack filter")
	browser.district.select(0);browser.discipline.select(0);browser.refresh();browser.select_event(17)
	check(browser.selected==17 and not browser.start.disabled,"Locked career finale is available for practice")
	for resolution in [Vector2i(1280,720),Vector2i(640,360),Vector2i(393,852)]:
		root.size=resolution;root.content_scale_size=resolution;await frames(8);browser.layout_body();await frames(5)
		for control in [browser.district,browser.discipline,browser.start,browser.detail]:check(root.get_visible_rect().encloses(control.get_global_rect()),"Race browser fits "+str(resolution)+" / "+str(control.name)+" / "+str(control.get_global_rect()))
	browser.queue_free();await process_frame
	var menu:Control=load("res://ui/front_end/main_menu.tscn").instantiate();root.add_child(menu)
	for page in ["home","challenge_series","settings","extras"]:
		menu.call(page);await frames(8)
		check(menu.get_viewport().gui_get_focus_owner()!=null,"Menu keyboard focus on "+page)
		check(root.get_visible_rect().encloses(menu.scroll.get_global_rect()),"Scrollable menu fits on "+page+" / "+str(menu.scroll.get_global_rect()))
	menu.queue_free();await process_frame
	DirAccess.remove_absolute(p.path)
	print("MODE MENUS ","FAIL" if failed else "PASS",": filters, all courses, keyboard focus, compact and portrait layouts")
	quit(1 if failed else 0)
