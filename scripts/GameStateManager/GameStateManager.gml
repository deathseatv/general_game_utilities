function GameStateManager() constructor
{
	eventBus = undefined;

	states =
	{
		boot : "boot",
		menu : "menu",
		loading : "loading",
		playing : "playing",
		paused : "paused",
		gameOver : "gameOver"
	};

	state = states.boot;
	stack = [];

	isValidState = function(v)
	{
		return (v == states.boot)
			|| (v == states.menu)
			|| (v == states.loading)
			|| (v == states.playing)
			|| (v == states.paused)
			|| (v == states.gameOver);
	};

	getState = function()
	{
		return state;
	};

	setState = function(next)
	{
		if(!is_string(next))
		{
			return false;
		}

		if(!isValidState(next))
		{
			return false;
		}

		if(state == next)
		{
			return false;
		}

		var prev = state;
		state = next;

		if(!is_undefined(eventBus))
		{
			eventBus.emit("state/changed", { prev : prev, value : next }, noone);

			if(prev != states.paused && next == states.paused)
			{
				eventBus.emit("pause/entered", { }, noone);
			}
			else if(prev == states.paused && next != states.paused)
			{
				eventBus.emit("pause/exited", { }, noone);
			}
		}

		return true;
	};

	isPlaying = function()
	{
		return state == states.playing;
	};

	isPaused = function()
	{
		return state == states.paused;
	};

	pushState = function(next)
	{
		if(!is_string(next) || !isValidState(next))
		{
			return false;
		}

		var n = array_length(stack);
		stack[n] = state;

		return setState(next);
	};

	popState = function()
	{
		var n = array_length(stack);

		if(n <= 0)
		{
			return false;
		}

		var prev = stack[n - 1];
		array_delete(stack, n - 1, 1);

		return setState(prev);
	};

	clearStack = function()
	{
		stack = [];
	};

	onPauseRequested = function(payload, eventName, sender)
	{
		if(state != states.playing)
		{
			// If we are in a gameplay room but state didn't transition yet,
			// allow pause when no menu is currently open.
			if(state == states.menu
				&& variable_global_exists("menus")
				&& is_struct(global.menus)
				&& variable_struct_exists(global.menus, "isOpen")
				&& !global.menus.isOpen)
			{
				setState(states.playing);
			}
			else
			{
				return;
			}
		}

		pushState(states.paused);

		if(!is_undefined(eventBus))
		{
			eventBus.emit("menu/show", { menuId : "pause" }, noone);
		}
	};

	onUnpauseRequested = function(payload, eventName, sender)
	{
		if(state == states.paused)
		{
			popState();
			return;
		}

		if(state != states.playing)
		{
			setState(states.playing);
		}
	};

	onSceneDidLoad = function(payload, eventName, sender)
	{
		if(state == states.boot)
		{
			setState(states.menu);
			return;
		}

		if(state == states.loading)
		{
			setState(states.playing);

			if(!is_undefined(eventBus))
			{
				eventBus.emit("menu/close", { }, noone);
			}

			return;
		}
	};

	onGameStart = function(payload, eventName, sender)
	{
		setState(states.loading);

		if(!is_undefined(eventBus) && is_struct(payload) && variable_struct_exists(payload, "sceneId"))
		{
			eventBus.emit("scene/load", { sceneId : payload.sceneId }, noone);
		}

		if(!is_undefined(eventBus))
		{
			eventBus.emit("menu/show", { menuId : "loading" }, noone);
		}
	};

	onMainMenu = function(payload, eventName, sender)
	{
		clearStack();
		setState(states.menu);

		if(!is_undefined(eventBus))
		{
			eventBus.emit("menu/show", { menuId : "main" }, noone);
		}
	};

	onGameOver = function(payload, eventName, sender)
	{
		clearStack();
		setState(states.gameOver);
	};

	init = function(bus)
	{
		eventBus = bus;

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("game/pause", method(self, self.onPauseRequested));
		eventBus.on("game/unpause", method(self, self.onUnpauseRequested));
		eventBus.on("scene/didLoad", method(self, self.onSceneDidLoad));

		eventBus.on("game/start", method(self, self.onGameStart));
		eventBus.on("game/mainMenu", method(self, self.onMainMenu));
		eventBus.on("game/gameOver", method(self, self.onGameOver));
	};
}
