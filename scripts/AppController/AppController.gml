function AppController() constructor
{
	events = undefined;

	input = undefined;
	menus = undefined;
	audio = undefined;
	scenes = undefined;
	gameState = undefined;
	settings = undefined;
	keybinds = undefined;
	time = undefined;
	camera = undefined;

	gui = undefined;

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
		keybinds = (variable_global_exists("keybinds") && is_struct(global.keybinds)) ? global.keybinds : new KeybindsManager();
		time = (variable_global_exists("time") && is_struct(global.time)) ? global.time : new TimeManager();
		camera = (variable_global_exists("camera") && is_struct(global.camera)) ? global.camera : new CameraManager();

		gui = (variable_global_exists("gui") && is_struct(global.gui)) ? global.gui : new GuiManager();

		debugConsole = (variable_global_exists("debugConsole") && is_struct(global.debugConsole)) ? global.debugConsole : new DebugConsole();

		global.input = input;
		global.menus = menus;
		global.audio = audio;
		global.scenes = scenes;
		global.gameState = gameState;
		global.settings = settings;
		global.keybinds = keybinds;
		global.time = time;
		global.camera = camera;
		global.gui = gui;
		global.debugConsole = debugConsole;

		audio.init(events);
		settings.init(events);

		if(variable_struct_exists(settings, "load") && is_callable(settings.load))
		{
			settings.load();
		}

		if(variable_struct_exists(keybinds, "load") && is_callable(keybinds.load))
		{
			keybinds.load();
		}

		time.init(events);
		scenes.init(events);
		gameState.init(events);
		menus.init(events);

		if(variable_struct_exists(menus, "setKeybinds") && is_callable(menus.setKeybinds))
		{
			menus.setKeybinds(keybinds);
		}

		camera.init(events);

		if(is_struct(gui) && variable_struct_exists(gui, "init") && is_callable(gui.init))
		{
			gui.init(events);
		}

		initInputInSystems(input, events, keybinds);

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
		if(is_struct(settings) && variable_struct_exists(settings, "toggleFullscreen") && is_callable(settings.toggleFullscreen))
		{
			settings.toggleFullscreen();
			return;
		}

		var isFs = window_get_fullscreen();
		window_set_fullscreen(!isFs);
	};

	update = function()
	{
		if(!booted)
		{
			return;
		}

		var splitInput = is_struct(input)
			&& variable_struct_exists(input, "beginFrame")
			&& is_callable(input.beginFrame)
			&& variable_struct_exists(input, "dispatchEvents")
			&& is_callable(input.dispatchEvents);

		if(splitInput
			&& variable_struct_exists(input, "clearConsumed")
			&& is_callable(input.clearConsumed))
		{
			input.clearConsumed();
		}

		var isPlaying = false;
		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "isPlaying")
			&& is_callable(gameState.isPlaying))
		{
			isPlaying = gameState.isPlaying();
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

		if(splitInput)
		{
			input.beginFrame();
		}
		else
		{
			input.update();
		}

		menus.update();

		if(is_struct(gui) && variable_struct_exists(gui, "update") && is_callable(gui.update))
		{
			gui.update();
		}

		if(splitInput)
		{
			input.dispatchEvents();
		}

		scenes.update();
	};

	drawGui = function()
	{
		if(!booted)
		{
			return;
		}

		scenes.drawGui();

		if(is_struct(gui) && variable_struct_exists(gui, "drawGui") && is_callable(gui.drawGui))
		{
			gui.drawGui();
		}

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
