extends SceneTree
var failed:=false
func check(value:bool,message:String) -> void:
	if not value:failed=true;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var profile=root.get_node("StreetProfile");var settings=root.get_node("GameSettings")
	profile.path="res://tests/garage-career.tmp";settings.settings_path="res://tests/garage-settings.tmp"
	profile.driver_created=true;profile.launch_mode="free";profile.credits=1300;profile.purchased_tiers.assign([0,0,0])
	settings.set_performance(0,0,0)
	var city:Node3D=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("disable_population",true);root.add_child(city)
	for i in range(14):await physics_frame
	city.car.set_physics_process(false)
	profile.launch_mode="garage"
	var menu:CanvasLayer=city.car.get_node("PauseMenu");menu.open_menu();menu._open_garage()
	var garage:Control=menu.get_node("Garage")
	var engine:OptionButton=garage.get_node(garage.ROWS+"/Engine")
	var base_acceleration:float=city.car.acceleration
	engine.select(1);garage._on_performance_choice(1)
	check(profile.credits==100 and settings.engine_level==1 and profile.purchased_tiers[0]==1 and city.car.acceleration>base_acceleration,"Garage purchase updates wallet, owned tier and real performance")
	engine.select(3);garage._on_performance_choice(3)
	check(engine.selected==1 and profile.credits==100 and settings.engine_level==1,"Unaffordable part restores selection and performance")
	var brand:OptionButton=garage.get_node(garage.ROWS+"/EngineBrand")
	brand.select(1);garage._on_brand_choice(1)
	check(profile.credits==100 and settings.engine_brand==1,"Included brand does not charge twice")
	check(garage._stats.text.contains("100 CR"),"Wallet shown in garage")
	DirAccess.remove_absolute(profile.path);DirAccess.remove_absolute(settings.settings_path)
	print("CAREER GARAGE ","FAIL" if failed else "PASS",": purchase, insufficient funds, brands, wallet and actual vehicle stats")
	paused=false;quit(1 if failed else 0)
