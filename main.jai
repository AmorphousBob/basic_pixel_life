main :: () 
{
app_init(); defer app_shutdown();

while !app.should_quit {
		update_delta_t();
		defer
		{
			app.frame_count += 1;
			app.fps_counter += 1;
			app.frame = .{};
		}
}

}



app_init :: ()
{
	setup_output_file();
	
	init_state_pointers();
	
	// windows setup
	Windows.SetProcessDPIAware();
	Windows.timeBeginPeriod(1);
	// this is kinda sketch lol, ideally I'd just like to tack it into the Windows namespace, but idk
	// how to do that without modifying Windows.jai
	FreeConsole();
	
	app.window = create_window(app.window_w, app.window_h, app_title, background_color_rgb=CLEAR_COL.xyz.component);
	
	// default allocator is permanent
	context.allocator = permanent_allocator;
	
	// do all the init shit baybee
	nil_resource = *app.resources[0];
	memory_init();
	render_init();
	init_resources();
	
	sound_init();
	ui_init(*app.ui);
		
	set_app_mode(START_APP_STATE);
	
	app.refresh_rate = get_refresh_rate();
	app.rdtsc_frequency = get_rdtsc_frequency();
}

app_shutdown :: ()
{
	sound_shutdown();
	memory_free();
}

update_delta_t :: inline ()
{
	frame_start_time := rdtsc();
	if app.frame_start_time != 0
	{
		app.last_frame_start_time = app.frame_start_time;
		
		if !VSYNC
		{
			app.delta_t = cast(float) (frame_start_time - app.last_frame_start_time) / app.rdtsc_frequency;
			app.time_elapsed += app.delta_t;
		}
	}
	app.frame_start_time = frame_start_time;
	
	if VSYNC then app.delta_t = 1.0/app.refresh_rate;
	
	// measure fps
	if tick_timer(*app.fps_timer, app.delta_t)
	{
		app.fps = app.fps_counter;
		app.fps_timer = 1.0;
		app.fps_counter = 0;
	}
}

app : *AppState;
__app_state : AppState;
AppState :: struct
{
	resources: [#run enum_highest_value(ResourceID)+1]ArcResource;
	should_quit: bool;
	window: Window_Type;
	window_w : s32 = WINDOW_X;
	window_h: s32 = WINDOW_Y;
	saved_window: Saved_Window_Info;
	is_fullscreen := false;
	mouse_pos: Vector2;
	
	// measurements
	rdtsc_frequency: u64;
	refresh_rate: float;
	delta_t: float = 1.0 / 60.0;
	
	frame_start_time: u64;
	last_frame_start_time: u64;
	
	time_elapsed: float64;
	frame_count: u64;
	fps_counter: u64;
	fps_timer: float = 1.0;
	fps: u64;
	
	// gotta have the derivatives for some finicky windows reason
	_cursor_confied: bool = false; 
	_cursor_showing: bool = true;
	// these are what you set to determine the state
	confine_cursor: bool = false;
	// randy: NOTE - this now does nothing, since we're
	// showing cursor always
	show_cursor: bool = true;
	key_down: [Input.Key_Code.MOUSE_WHEEL_DOWN + 1] bool;
	
	app_mode: AppMode;
	entering_app_mode: AppMode;
	exiting_app_mode: AppMode;
	
	main_menu_alpha: float;
	main_menu_alpha_t: float;
	world_alpha: float;
	world_alpha_t: float;
	// sub main menu
	main_home_alpha: float;
	main_home_alpha_t: float;
	main_controls_alpha: float;
	main_controls_alpha_t: float;
	
	camera: Camera2;
	
	world_gen: WorldGenParams;
	world: WorldState;
	
	ui: UI_State;
	
	// debug
	frame_stepping := false;
	lines: [1024] Line;
	using debug_config: DebugConfig;
	expander_world_gen: bool;
	expander_dumpy: bool = true;
	expander_spawn: bool;
	dropdown: bool;
	spawn_entity_option: EntityType = .goblin;
	scroll_spawn: int;

	// :particle system
	particles: [128]Particle;
	particle_cursor: int;
	
	
	// game interface stuff
	interface_mode: InterfaceMode;
	entering_interface_mode: InterfaceMode;
	exiting_interface_mode: InterfaceMode;
	disable_player_input: bool;
	// interface animations
	respawn_mode_alpha: float;
	respawn_mode_alpha_t: float;
	pause_menu_alpha: float;
	pause_menu_alpha_t: float;
	inventory_alpha: float;
	inventory_alpha_t: float;
	game_over_alpha: float;
	game_over_alpha_t: float;
	hints_menu_alpha: float;
	hints_menu_alpha_t: float;
	workbench_alpha: float;
	workbench_alpha_t: float;
	placement_alpha: float;
	placement_alpha_t: float;
	build_mode_alpha: float;
	build_mode_alpha_t: float;
	// transient interface state
	active_workbench: EntityHandle;
	placement_x_dir:= 1;
	mouse_held_item: EntityHandle;
	crafting_slot_index: int = 0;
	blueprint_slot_index: int = 0;
	active_blueprint_id: ItemID;
	
	view_matrix: Matrix4;
	
	frame : FrameStorage; // gets zeroed each frame
	FrameStorage :: struct
	{
		key_pressed: [Input.Key_Code.MOUSE_WHEEL_DOWN + 1] bool;
		key_released: [Input.Key_Code.MOUSE_WHEEL_DOWN + 1] bool;
		wheel_delta: s32;
		mouse_delta: Vector2;
		hot_interactable: EntityHandle;
		hot_blueprint: EntityHandle;
	}
}