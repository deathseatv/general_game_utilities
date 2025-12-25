function FlowManager() constructor
{
	eventBus = undefined;

	mode = "events"; // "events" | "direct"

	menus = undefined;
	scenes = undefined;
	gameState = undefined;
	input = undefined;

	ids =
	{
		introMenu : "intro",
		mainMenu : "main",
		pauseMenu : "pause",
		loadingMenu : "loading",
		confirmExitMenu : "confirmExit",
		defaultScene : "rm_game"
	};

	unsubs = [];

	fallbackState = "boot";
	fallbackStack = [];

	resolveGlobals = function()
	{
		if(is_undefined(menus) && variable_global_exists("menus") && is_struct(global.menus))
		{
			menus = global.menus;
		}

		if(is_undefined(scenes) && variable_global_exists("scenes") && is_struct(global.scenes))
		{
			scenes = global.scenes;
		}

		if(is_undefined(gameState) && variable_global_exists("gameState") && is_struct(global.gameState))
		{
			gameState = global.gameState;
		}

		if(is_undefined(input) && variable_global_exists("input") && is_struct(global.input))
		{
			input = global.input;
		}
	};

	ev = function(key, fallback)
	{
		if(variable_global_exists("eventNames")
			&& is_struct(global.eventNames)
			&& variable_struct_exists(global.eventNames, key))
		{
			return global.eventNames[$ key];
		}

		return fallback;
	};

	getStateToken = function(key)
	{
		var k = string(key);

		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "states")
			&& is_struct(gameState.states)
			&& variable_struct_exists(gameState.states, k))
		{
			return gameState.states[$ k];
		}

		return k;
	};

	getStateValue = function()
	{
		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "getState")
			&& is_callable(gameState.getState))
		{
			return gameState.getState();
		}

		return fallbackState;
	};

	isStateSafe = function(key)
	{
		return getStateValue() == getStateToken(key);
	};

	setStateSafe = function(key)
	{
		var token = getStateToken(key);

		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "setState")
			&& is_callable(gameState.setState))
		{
			return gameState.setState(token);
		}

		if(fallbackState == token)
		{
			return false;
		}

		fallbackState = token;
		return true;
	};

	pushStateSafe = function(key)
	{
		var token = getStateToken(key);

		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "pushState")
			&& is_callable(gameState.pushState))
		{
			return gameState.pushState(token);
		}

		fallbackStack[array_length(fallbackStack)] = fallbackState;
		fallbackState = token;
		return true;
	};

	popStateSafe = function()
	{
		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "popState")
			&& is_callable(gameState.popState))
		{
			return gameState.popState();
		}

		var n = array_length(fallbackStack);
		if(n <= 0)
		{
			return false;
		}

		var prev = fallbackStack[n - 1];
		array_delete(fallbackStack, n - 1, 1);
		fallbackState = prev;
		return true;
	};

	clearStateStackSafe = function()
	{
		if(is_struct(gameState)
			&& variable_struct_exists(gameState, "clearStack")
			&& is_callable(gameState.clearStack))
		{
			gameState.clearStack();
			return;
		}

		fallbackStack = [];
	};

	emit = function(eventName, payload)
	{
		if(!is_struct(eventBus)
			|| !variable_struct_exists(eventBus, "emit")
			|| !is_callable(eventBus.emit))
		{
			return false;
		}

		eventBus.emit(eventName, is_undefined(payload) ? { } : payload, noone);
		return true;
	};

	showMenuSafe = function(menuId)
	{
		var _id = string(menuId);

		if(is_struct(menus)
			&& variable_struct_exists(menus, "show")
			&& is_callable(menus.show))
		{
			return menus.show(_id);
		}

		return emit(ev("menuShow", "menu/show"), { menuId : _id });
	};

	closeMenuSafe = function()
	{
		if(is_struct(menus)
			&& variable_struct_exists(menus, "close")
			&& is_callable(menus.close))
		{
			menus.close();
			return true;
		}

		return emit(ev("menuClose", "menu/close"), { });
	};

	isMenuOpenSafe = function()
	{
		return is_struct(menus)
			&& variable_struct_exists(menus, "isOpen")
			&& menus.isOpen;
	};

	currentMenuIdSafe = function()
	{
		if(is_struct(menus) && variable_struct_exists(menus, "currentMenuId"))
		{
			return string(menus.currentMenuId);
		}

		return "";
	};

	loadSceneSafe = function(sceneId)
	{
		if(is_struct(scenes)
			&& variable_struct_exists(scenes, "load")
			&& is_callable(scenes.load))
		{
			return scenes.load(sceneId);
		}

		return emit(ev("sceneLoad", "scene/load"), { sceneId : sceneId });
	};

	consumeSignalSafe = function(signalName)
	{
		if(is_struct(input)
			&& variable_struct_exists(input, "consume")
			&& is_callable(input.consume))
		{
			input.consume(string(signalName));
		}
	};

	clearWiring = function()
	{
		var n = array_length(unsubs);

		for(var i = 0; i < n; i += 1)
		{
			var fn = unsubs[i];
			if(is_callable(fn))
			{
				fn();
			}
		}

		unsubs = [];
	};


	destroy = function()
	{
		self.clearWiring();
		eventBus = undefined;
		menus = undefined;
		scenes = undefined;
		gameState = undefined;
		input = undefined;
		return true;
	};

	wire = function()
	{
		self.clearWiring();

		if(!is_struct(eventBus)
			|| !variable_struct_exists(eventBus, "on")
			|| !is_callable(eventBus.on))
		{
			return false;
		}

		array_push(unsubs, eventBus.on(ev("flowBoot", "flow/boot"), method(self, self.onBoot)));
		array_push(unsubs, eventBus.on(ev("flowStartGame", "flow/startGame"), method(self, self.onStartGame)));
		array_push(unsubs, eventBus.on(ev("flowMainMenu", "flow/mainMenu"), method(self, self.onMainMenu)));
		array_push(unsubs, eventBus.on(ev("flowPause", "flow/pause"), method(self, self.onPause)));
		array_push(unsubs, eventBus.on(ev("flowUnpause", "flow/unpause"), method(self, self.onUnpause)));
		array_push(unsubs, eventBus.on(ev("flowTogglePause", "flow/togglePause"), method(self, self.onTogglePause)));
		array_push(unsubs, eventBus.on(ev("flowQuit", "flow/quit"), method(self, self.onQuit)));

		if(mode == "direct")
		{
			array_push(unsubs, eventBus.on(ev("gameStart", "game/start"), method(self, self.onGameStart)));
			array_push(unsubs, eventBus.on(ev("gameMainMenu", "game/mainMenu"), method(self, self.onGameMainMenu)));
			array_push(unsubs, eventBus.on(ev("gamePause", "game/pause"), method(self, self.onGamePause)));
			array_push(unsubs, eventBus.on(ev("gameUnpause", "game/unpause"), method(self, self.onGameUnpause)));
			array_push(unsubs, eventBus.on(ev("sceneDidLoad", "scene/didLoad"), method(self, self.onSceneDidLoad)));
		}

		return true;
	};

	init = function(bus)
	{
		var opts = (argument_count >= 2) ? argument[1] : undefined;

		eventBus = bus;

		if(is_struct(opts))
		{
			if(variable_struct_exists(opts, "mode"))
			{
				mode = string(opts.mode);
			}

			if(variable_struct_exists(opts, "menus")) menus = opts.menus;
			if(variable_struct_exists(opts, "scenes")) scenes = opts.scenes;
			if(variable_struct_exists(opts, "gameState")) gameState = opts.gameState;
			if(variable_struct_exists(opts, "input")) input = opts.input;

			if(variable_struct_exists(opts, "ids") && is_struct(opts.ids))
			{
				var names = variable_struct_get_names(opts.ids);
				for(var i = 0; i < array_length(names); i += 1)
				{
					var k = names[i];
					ids[$ k] = string(opts.ids[$ k]);
				}
			}

			if(variable_struct_exists(opts, "wire") && opts.wire)
			{
				self.wire();
			}
		}

		self.resolveGlobals();
		return true;
	};

	boot = function()
	{
		self.resolveGlobals();

		if(mode == "events")
		{
			return emit(ev("menuShow", "menu/show"), { menuId : ids.introMenu });
		}

		setStateSafe("menu");
		showMenuSafe(ids.introMenu);
		return true;
	};

	startGame = function(sceneId)
	{
		self.resolveGlobals();

		var sid = is_undefined(sceneId) ? ids.defaultScene : sceneId;

		if(mode == "events")
		{
			return emit(ev("gameStart", "game/start"), { sceneId : sid });
		}

		setStateSafe("loading");
		showMenuSafe(ids.loadingMenu);
		loadSceneSafe(sid);
		return true;
	};

	mainMenu = function()
	{
		self.resolveGlobals();

		if(mode == "events")
		{
			return emit(ev("gameMainMenu", "game/mainMenu"), { });
		}

		clearStateStackSafe();
		setStateSafe("menu");
		showMenuSafe(ids.mainMenu);
		return true;
	};

	pause = function()
	{
		self.resolveGlobals();

		if(mode == "events")
		{
			return emit(ev("gamePause", "game/pause"), { });
		}

		if(!isStateSafe("playing"))
		{
			return false;
		}

		pushStateSafe("paused");
		showMenuSafe(ids.pauseMenu);
		consumeSignalSafe("pause");
		return true;
	};

	unpause = function()
	{
		self.resolveGlobals();

		if(mode == "events")
		{
			emit(ev("gameUnpause", "game/unpause"), { });
			emit(ev("menuClose", "menu/close"), { });
			return true;
		}

		if(isStateSafe("paused"))
		{
			popStateSafe();
		}
		else
		{
			setStateSafe("playing");
		}

		closeMenuSafe();
		consumeSignalSafe("pause");
		return true;
	};

	togglePause = function()
	{
		self.resolveGlobals();

		if(mode == "events")
		{
			var menuId = currentMenuIdSafe();

			if(menuId == ids.pauseMenu || isStateSafe("paused"))
			{
				emit(ev("gameUnpause", "game/unpause"), { });
				emit(ev("menuClose", "menu/close"), { });
				return true;
			}

			if(isMenuOpenSafe() && menuId != "" && menuId != ids.pauseMenu)
			{
				return false;
			}

			return emit(ev("gamePause", "game/pause"), { });
		}

		if(isStateSafe("paused"))
		{
			return unpause();
		}

		return pause();
	};

	quit = function()
	{
		game_end();
		return true;
	};

	onBoot = function(payload, eventName, sender)
	{
		boot();
	};

	onStartGame = function(payload, eventName, sender)
	{
		var sid = ids.defaultScene;

		if(is_struct(payload) && variable_struct_exists(payload, "sceneId"))
		{
			sid = payload.sceneId;
		}

		startGame(sid);
	};

	onMainMenu = function(payload, eventName, sender)
	{
		mainMenu();
	};

	onPause = function(payload, eventName, sender)
	{
		pause();
	};

	onUnpause = function(payload, eventName, sender)
	{
		unpause();
	};

	onTogglePause = function(payload, eventName, sender)
	{
		togglePause();
	};

	onQuit = function(payload, eventName, sender)
	{
		quit();
	};

	onGameStart = function(payload, eventName, sender)
	{
		var sid = ids.defaultScene;

		if(is_struct(payload) && variable_struct_exists(payload, "sceneId"))
		{
			sid = payload.sceneId;
		}

		setStateSafe("loading");
		showMenuSafe(ids.loadingMenu);
		loadSceneSafe(sid);
	};

	onGameMainMenu = function(payload, eventName, sender)
	{
		clearStateStackSafe();
		setStateSafe("menu");
		showMenuSafe(ids.mainMenu);
	};

	onGamePause = function(payload, eventName, sender)
	{
		if(!isStateSafe("playing"))
		{
			return;
		}

		pushStateSafe("paused");
		showMenuSafe(ids.pauseMenu);
	};

	onGameUnpause = function(payload, eventName, sender)
	{
		if(isStateSafe("paused"))
		{
			popStateSafe();
		}
		else
		{
			setStateSafe("playing");
		}

		closeMenuSafe();
	};

	onSceneDidLoad = function(payload, eventName, sender)
	{
		if(isStateSafe("boot"))
		{
			setStateSafe("menu");
			return;
		}

		if(isStateSafe("loading"))
		{
			setStateSafe("playing");
			closeMenuSafe();
		}
	};
}