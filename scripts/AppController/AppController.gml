function AppController() constructor
{
	events = undefined;

	input = undefined;
	menus = undefined;
	audio = undefined;
	scenes = undefined;
	gameState = undefined;
	settings = undefined;
	time = undefined;
	camera = undefined;

	booted = false;

	init = function()
	{
		if(booted)
		{
			return;
		}

		booted = true;

		// reuse existing global bus if one exists
		if(variable_global_exists("events") && is_struct(global.events))
		{
			events = global.events;
		}
		else if(variable_global_exists("eventBus") && is_struct(global.eventBus))
		{
			events = global.eventBus;
			global.events = events;
		}
		else
		{
			events = new EventBus();
			global.events = events;
			global.eventBus = events;
		}

		// if globals already exist (from editor/test), reuse them
		input = (variable_global_exists("input") && is_struct(global.input)) ? global.input : new InputManager();
		menus = (variable_global_exists("menus") && is_struct(global.menus)) ? global.menus : new MenuManager();
		audio = (variable_global_exists("audio") && is_struct(global.audio)) ? global.audio : new AudioManager();
		scenes = (variable_global_exists("scenes") && is_struct(global.scenes)) ? global.scenes : new SceneManager();
		gameState = (variable_global_exists("gameState") && is_struct(global.gameState)) ? global.gameState : new GameStateManager();
		settings = (variable_global_exists("settings") && is_struct(global.settings)) ? global.settings : new SettingsManager();
		time = (variable_global_exists("time") && is_struct(global.time)) ? global.time : new TimeManager();
		camera = (variable_global_exists("camera") && is_struct(global.camera)) ? global.camera : new CameraManager();

		global.input = input;
		global.menus = menus;
		global.audio = audio;
		global.scenes = scenes;
		global.gameState = gameState;
		global.settings = settings;
		global.time = time;
		global.camera = camera;

		// init each system ONCE (safe even if they subscribe multiple times, but we avoid it)
		audio.init(events);
		settings.init(events);
		time.init(events);
		scenes.init(events);
		gameState.init(events);
		menus.init(events);
		camera.init(events);

		initInputInSystems(input, events);

		settings.apply();

		gameState.setState(gameState.states.menu);
		menus.show("intro");
	};

	update = function()
	{
		if(!booted)
		{
			return;
		}

		input.update();
		menus.update();
		scenes.update();
	};

	drawGui = function()
	{
		if(!booted)
		{
			return;
		}

		scenes.drawGui();
		menus.drawGui();
	};

	onRoomStart = function()
	{
		if(!booted)
		{
			return;
		}

		scenes.onRoomStart();
	};
}
