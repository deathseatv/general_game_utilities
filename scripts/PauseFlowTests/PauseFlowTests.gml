function pfTapKey(h, vk)
{
	simulateKeyPress(vk);
	h.app.update();

	// Advance 1 frame so the simulateKeyPress scheduled release actually runs
	simulateFrameWait(1);

	// One more update so InputManager captures the 0 and resets prevValue/value
	h.app.update();
}


function gmtlPfHasGlobal(name)
{
	return variable_struct_exists(global, name);
}

function gmtlPfGetGlobal(name)
{
	if(!gmtlPfHasGlobal(name))
	{
		return undefined;
	}

	return global[$ name];
}

function gmtlPfSetGlobal(name, value)
{
	global[$ name] = value;
}

function gmtlPfRemoveGlobal(name)
{
	if(gmtlPfHasGlobal(name))
	{
		variable_struct_remove(global, name);
	}
}

function gmtlPfSnapshotGlobals()
{
	var names =
	[
		"input",
		"flow",
		"events",
		"eventBus",
		"keybinds",
		"settings"
	];

	var snap =
	{
		names : names,
		exists : [],
		values : []
	};

	var n = array_length(names);

	for(var i = 0; i < n; i += 1)
	{
		var key = names[i];
		snap.exists[i] = gmtlPfHasGlobal(key);
		snap.values[i] = gmtlPfGetGlobal(key);
	}

	return snap;
}

function gmtlPfRestoreGlobals(snap)
{
	var n = array_length(snap.names);

	for(var i = 0; i < n; i += 1)
	{
		var key = snap.names[i];

		if(snap.exists[i])
		{
			gmtlPfSetGlobal(key, snap.values[i]);
		}
		else
		{
			gmtlPfRemoveGlobal(key);
		}
	}
}

function gmtlPfMakeHarness()
{
	var bus = new EventBus();

	var tracer =
	{
		trace : []
	};

	tracer.handle = function(payload, eventName, sender)
	{
		array_push(self.trace, string(eventName));
	};

	var input = new InputManager();

	var keybinds =
	{
		getKey : function(actionName)
		{
			if(string(actionName) == "pause")
			{
				return vk_escape;
			}

			return 0;
		}
	};

	initInputInSystems(input, bus, keybinds);

	var gameState = new GameStateManager();
	gameState.init(bus);
	gameState.setState(gameState.states.playing);

	var menus = new MenuManager();
	menus.init(bus);

	var scenes = { update : function() { }, drawGui : function() { } };

	var flow = new FlowManager();
	flow.init(bus,
	{
		mode : "events",
		input : input,
		menus : menus,
		scenes : scenes,
		gameState : gameState,
		wire : true
	});

	flow.wire();

	// subscribe tracer LAST so it fires FIRST (bus emits LIFO)
	bus.on("game/pause", tracer.handle, tracer);
	bus.on("pause/entered", tracer.handle, tracer);
	bus.on("menu/show", tracer.handle, tracer);
	bus.on("game/unpause", tracer.handle, tracer);
	bus.on("pause/exited", tracer.handle, tracer);

	global.input = input;
	global.flow = flow;
	global.keybinds = keybinds;
	var gui = { update : function() { }, drawGui : function() { } };

	var debugConsole =
	{
		consumed : false,
		isOpen : false,
		pauseWhenOpen : false,
		update : function(canOpen) { }
	};

	var app = new AppController();
	app.booted = true;
	app.events = bus;
	app.input = input;
	app.menus = menus;
	app.gameState = gameState;
	app.scenes = scenes;
	app.gui = gui;
	app.debugConsole = debugConsole;

	return
	{
		app : app,
		bus : bus,
		tracer : tracer,
		input : input,
		flow : flow,
		menus : menus,
		gameState : gameState
	};
}


function gmtlPauseFlowTests_safe1()
{
	suite(function()
	{
		section("PauseFlow_safe1", function()
		{
			test("initInputInSystems wires pause => game/pause (and watches Escape)", function()
			{
				var snap = gmtlPfSnapshotGlobals();

				gmtlPfRemoveGlobal("input");
				gmtlPfRemoveGlobal("flow");
				gmtlPfRemoveGlobal("events");
				gmtlPfRemoveGlobal("eventBus");
				gmtlPfRemoveGlobal("keybinds");
				gmtlPfRemoveGlobal("settings");

				var bus = new EventBus();
				var input = new InputManager();

				var keybinds =
				{
					getKey : function(actionName)
					{
						if(string(actionName) == "pause")
						{
							return vk_escape;
						}

						return 0;
					}
				};

				var ok = initInputInSystems(input, bus, keybinds);

				expect(ok).toBeTruthy();
				expect(variable_struct_exists(input.signals, "pause")).toBeTruthy();
				expect(variable_struct_exists(input.bindings, "pause")).toBeTruthy();
				expect(input.bindings[$ "pause"].pressed).toBe("flow/togglePause");

				gmtlPfRestoreGlobals(snap);
			});

			test("Esc while playing triggers game/pause -> pause/entered -> menu/show pause", function()
			{
				var snap = gmtlPfSnapshotGlobals();
				var h = gmtlPfMakeHarness();

				simulateKeyPress(vk_escape);
				h.app.update();
				keyboard_clear(vk_escape);

				expect(h.tracer.trace[0]).toBe("game/pause");
				expect(h.tracer.trace[1]).toBe("pause/entered");
				expect(h.tracer.trace[2]).toBe("menu/show");

				expect(h.gameState.state).toBe(h.gameState.states.paused);
				expect(h.menus.isOpen).toBeTruthy();
				expect(h.menus.currentMenuId).toBe("pause");

				gmtlPfRestoreGlobals(snap);
			});

				test("Esc while playing pauses even if FlowManager has no gameState ref", function()
				{
					var snap = gmtlPfSnapshotGlobals();
					var h = gmtlPfMakeHarness();

					h.flow.gameState = undefined;

					simulateKeyPress(vk_escape);
					h.app.update();
					keyboard_clear(vk_escape);

					expect(h.gameState.state).toBe(h.gameState.states.paused);
					expect(h.menus.isOpen).toBeTruthy();
					expect(h.menus.currentMenuId).toBe("pause");

					gmtlPfRestoreGlobals(snap);
				});

			test("Esc in pause menu consumes pause signal, emits game/unpause, and closes menu", function()
			{
				var snap = gmtlPfSnapshotGlobals();
				var h = gmtlPfMakeHarness();

				simulateKeyPress(vk_escape);
				h.app.update();
				keyboard_clear(vk_escape);

				simulateKeyPress(vk_escape);
				h.app.update();
				keyboard_clear(vk_escape);

				// let input settle (pause signal value goes back to 0)
				h.app.update();

				expect(h.gameState.state).toBe(h.gameState.states.playing);
				expect(h.menus.isOpen).toBeFalsy();

				simulateKeyPress(vk_escape);
				h.app.update();
				keyboard_clear(vk_escape);

				expect(h.gameState.state).toBe(h.gameState.states.paused);
				expect(h.menus.isOpen).toBeTruthy();
				expect(h.menus.currentMenuId).toBe("pause");

				gmtlPfRestoreGlobals(snap);
			});

			test("Esc can open pause again after closing with Esc (regression guard)", function()
			{
				var snap = gmtlPfSnapshotGlobals();
				var h = gmtlPfMakeHarness();

				pfTapKey(h, vk_escape); // pause
				pfTapKey(h, vk_escape); // unpause

				expect(h.gameState.state).toBe(h.gameState.states.playing);
				expect(h.menus.isOpen).toBeFalsy();

				pfTapKey(h, vk_escape); // pause again

				expect(h.gameState.state).toBe(h.gameState.states.paused);
				expect(h.menus.isOpen).toBeTruthy();
				expect(h.menus.currentMenuId).toBe("pause");

				gmtlPfRestoreGlobals(snap);
			});

		});
	});
}