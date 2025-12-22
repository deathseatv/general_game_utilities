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

	debugConsole = undefined;

	booted = false;

	init = function()
	{
		if(booted)
		{
			return;
		}

		booted = true;

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

		input = (variable_global_exists("input") && is_struct(global.input)) ? global.input : new InputManager();
		menus = (variable_global_exists("menus") && is_struct(global.menus)) ? global.menus : new MenuManager();
		audio = (variable_global_exists("audio") && is_struct(global.audio)) ? global.audio : new AudioManager();
		scenes = (variable_global_exists("scenes") && is_struct(global.scenes)) ? global.scenes : new SceneManager();
		gameState = (variable_global_exists("gameState") && is_struct(global.gameState)) ? global.gameState : new GameStateManager();
		settings = (variable_global_exists("settings") && is_struct(global.settings)) ? global.settings : new SettingsManager();
		time = (variable_global_exists("time") && is_struct(global.time)) ? global.time : new TimeManager();
		camera = (variable_global_exists("camera") && is_struct(global.camera)) ? global.camera : new CameraManager();

		debugConsole = (variable_global_exists("debugConsole") && is_struct(global.debugConsole)) ? global.debugConsole : new DebugConsole();

		global.input = input;
		global.menus = menus;
		global.audio = audio;
		global.scenes = scenes;
		global.gameState = gameState;
		global.settings = settings;
		global.time = time;
		global.camera = camera;
		global.debugConsole = debugConsole;

		audio.init(events);
		settings.init(events);
		time.init(events);
		scenes.init(events);
		gameState.init(events);
		menus.init(events);
		camera.init(events);

		initInputInSystems(input, events);

		if(is_struct(events))
		{
			events.on("video/toggleFullscreen", method(self, self.onToggleFullscreen));
		}

		settings.apply();

		self.initDebugConsole();

		gameState.setState(gameState.states.menu);
		menus.show("intro");
	};

	initDebugConsole = function()
	{
		if(!is_struct(debugConsole))
		{
			return;
		}

		if(!variable_struct_exists(debugConsole, "registerCommand"))
		{
			return;
		}

		if(!variable_struct_exists(debugConsole, "commands"))
		{
			return;
		}

		debugConsole.registerCommand("help", "help", function(args, line)
		{
			var names = variable_struct_get_names(debugConsole.commands);
			array_sort(names, true);

			debugConsole.log("Commands:");
			for(var i = 0; i < array_length(names); i += 1)
			{
				var entry = debugConsole.commands[$ names[i]];
				if(is_struct(entry) && variable_struct_exists(entry, "usage"))
				{
					debugConsole.log("- " + entry.usage);
				}
			}
		});

		debugConsole.registerCommand("clear", "clear", function(args, line)
		{
			debugConsole.lines = [];
		});

		debugConsole.registerCommand("pause", "pause [0/1]", function(args, line)
		{
			if(array_length(args) == 0)
			{
				debugConsole.pauseWhenOpen = !debugConsole.pauseWhenOpen;
				debugConsole.log("pauseWhenOpen = " + string(debugConsole.pauseWhenOpen));
				return;
			}

			debugConsole.pauseWhenOpen = (real(args[0]) != 0);
			debugConsole.log("pauseWhenOpen = " + string(debugConsole.pauseWhenOpen));
		});

		debugConsole.registerCommand("close", "close", function(args, line)
		{
			debugConsole.close();
		});

		debugConsole.log("Console ready. Type 'help'.");
	};


	onToggleFullscreen = function(payload, eventName, sender)
	{
		var isFs = window_get_fullscreen();
		window_set_fullscreen(!isFs);
	};

	update = function()
	{
		if(!booted)
		{
			return;
		}

		var playingId = "playing";
		if(is_struct(gameState))
		{
			if(variable_struct_exists(gameState, "states") && is_struct(gameState.states))
			{
				if(variable_struct_exists(gameState.states, "playing"))
				{
					playingId = gameState.states.playing;
				}
			}
		}

		var isPlaying = false;
		if(is_struct(gameState))
		{
			if(variable_struct_exists(gameState, "state") && gameState.state == playingId) isPlaying = true;
			else if(variable_struct_exists(gameState, "currentState") && gameState.currentState == playingId) isPlaying = true;
			else if(variable_struct_exists(gameState, "currentStateId") && gameState.currentStateId == playingId) isPlaying = true;
			else if(variable_struct_exists(gameState, "stateId") && gameState.stateId == playingId) isPlaying = true;
			else if(variable_struct_exists(gameState, "currentStateName") && gameState.currentStateName == playingId) isPlaying = true;
		}

		var isMenuOpen = false;
		if(is_struct(menus) && variable_struct_exists(menus, "isOpen"))
		{
			isMenuOpen = menus.isOpen;
		}

		var canConsoleOpen = isPlaying && !isMenuOpen;

		if(is_struct(debugConsole) && variable_struct_exists(debugConsole, "update"))
		{
			debugConsole.update(canConsoleOpen);

			if(variable_struct_exists(debugConsole, "consumed") && debugConsole.consumed)
			{
				return;
			}

			if(variable_struct_exists(debugConsole, "isOpen") && debugConsole.isOpen)
			{
				if(variable_struct_exists(debugConsole, "pauseWhenOpen") && debugConsole.pauseWhenOpen)
				{
					return;
				}
			}
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

		if(is_struct(debugConsole) && variable_struct_exists(debugConsole, "drawGui"))
		{
			if(debugConsole.isOpen)
			{
				var guiW = display_get_gui_width();
				var guiH = display_get_gui_height();
				debugConsole.drawGui(0, 0, guiW, guiH * 0.5);
			}
		}
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
