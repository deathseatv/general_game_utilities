function gmtlAc4HasGlobal(name)
{
	return variable_struct_exists(global, name);
}

function gmtlAc4GetGlobal(name)
{
	if(!gmtlAc4HasGlobal(name))
	{
		return undefined;
	}

	return global[$ name];
}

function gmtlAc4SetGlobal(name, value)
{
	global[$ name] = value;
}

function gmtlAc4RemoveGlobal(name)
{
	if(gmtlAc4HasGlobal(name))
	{
		variable_struct_remove(global, name);
	}
}

function gmtlAc4SnapshotGlobals()
{
	var names =
	[
		"events",
		"eventBus",
		"input",
		"menus",
		"audio",
		"scenes",
		"gameState",
		"settings",
		"keybinds",
		"time",
		"camera",
		"debugConsole"
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

		snap.exists[i] = gmtlAc4HasGlobal(key);
		snap.values[i] = gmtlAc4GetGlobal(key);
	}

	return snap;
}

function gmtlAc4RestoreGlobals(snap)
{
	var n = array_length(snap.names);

	for(var i = 0; i < n; i += 1)
	{
		var key = snap.names[i];

		if(snap.exists[i])
		{
			gmtlAc4SetGlobal(key, snap.values[i]);
		}
		else
		{
			gmtlAc4RemoveGlobal(key);
		}
	}
}

function gmtlAc4MakeBus()
{
	return
	{
		emit : function(eventName, payload, sender)
		{
			return 1;
		},

		on : function(eventName, handler, ctx)
		{
			return function() { };
		}
	};
}

function gmtlAc4MakeInputStub()
{
	return
	{
		addCalls : [],
		bindCalls : [],
		setBusCalls : [],

		eventBus : undefined,

		signals : { pause : { pressed : false, released : false, value : 0 } },

		keyPressed : function(vk)
		{
			var token =
			{
				run : function(raw)
				{
					return 0;
				}
			};

			return method(token, token.run);
		},

		addSignal : function(signalName, mapperFn)
		{
			var n = array_length(self.addCalls);
			self.addCalls[n] =
			{
				signalName : signalName,
				mapperFn : mapperFn
			};

			if(!variable_struct_exists(self.signals, signalName))
			{
				self.signals[$ signalName] = { pressed : false, released : false, value : 0 };
			}
		},

		setEventBus : function(bus)
		{
			var n = array_length(self.setBusCalls);
			self.setBusCalls[n] = bus;
			self.eventBus = bus;
		},

		bindSignal : function(signalName, pressedEventName, releasedEventName, changedEventName)
		{
			var n = array_length(self.bindCalls);
			self.bindCalls[n] =
			{
				signalName : signalName,
				pressedEventName : pressedEventName,
				releasedEventName : releasedEventName,
				changedEventName : changedEventName
			};
		},

		clearConsumedCalls : 0,
		beginFrameCalls : 0,
		dispatchCalls : 0,
		updateCalls : 0,

		clearConsumed : function()
		{
			self.clearConsumedCalls += 1;
		},

		beginFrame : function()
		{
			self.beginFrameCalls += 1;
		},

		dispatchEvents : function()
		{
			self.dispatchCalls += 1;
		},

		update : function()
		{
			self.updateCalls += 1;
		}
	};
}

function gmtlAc4MakeMenusStub()
{
	return
	{
		initCalls : 0,
		updateCalls : 0,
		drawCalls : 0,

		showCalls : [],

		init : function(bus)
		{
			self.initCalls += 1;
		},

		show : function(menuId)
		{
			var n = array_length(self.showCalls);
			self.showCalls[n] = menuId;
			return true;
		},

		update : function()
		{
			self.updateCalls += 1;
		},

		drawGui : function()
		{
			self.drawCalls += 1;
		}
	};
}

function gmtlAc4MakeScenesStub()
{
	return
	{
		initCalls : 0,
		updateCalls : 0,
		drawCalls : 0,
		roomStartCalls : 0,

		init : function(bus)
		{
			self.initCalls += 1;
		},

		update : function()
		{
			self.updateCalls += 1;
		},

		drawGui : function()
		{
			self.drawCalls += 1;
		},

		onRoomStart : function()
		{
			self.roomStartCalls += 1;
		}
	};
}

function gmtlAc4MakeInitOnlyStub()
{
	return
	{
		initCalls : 0,

		init : function(bus)
		{
			self.initCalls += 1;
		}
	};
}

function gmtlAc4MakeSettingsStub()
{
	return
	{
		initCalls : 0,
		applyCalls : 0,

		init : function(bus)
		{
			self.initCalls += 1;
		},

		apply : function()
		{
			self.applyCalls += 1;
		}
	};
}

function gmtlAc4MakeGameStateStub()
{
	return
	{
		states : { menu : "menu" },

		initCalls : 0,
		setCalls : [],

		init : function(bus)
		{
			self.initCalls += 1;
		},

		setState : function(next)
		{
			var n = array_length(self.setCalls);
			self.setCalls[n] = next;
			return true;
		}
	};
}

function gmtlAppControllerTests_safe4()
{
	suite(function()
	{
		section("AppController_safe4", function()
		{
			test("init reuses existing global.events (does not force global.eventBus) and wires systems", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				gmtlAc4RemoveGlobal("events");
				gmtlAc4RemoveGlobal("eventBus");

				var bus = gmtlAc4MakeBus();
				global.events = bus;

				global.input = gmtlAc4MakeInputStub();
				global.menus = gmtlAc4MakeMenusStub();
				global.audio = gmtlAc4MakeInitOnlyStub();
				global.scenes = gmtlAc4MakeScenesStub();
				global.gameState = gmtlAc4MakeGameStateStub();
				global.settings = gmtlAc4MakeSettingsStub();
				global.time = gmtlAc4MakeInitOnlyStub();
				global.camera = gmtlAc4MakeInitOnlyStub();

				var app = new AppController();
				app.init();

				expect(global.events).toBe(bus);

				// Your AppController only sets global.eventBus in the "new EventBus()" branch.
				expect(gmtlAc4HasGlobal("eventBus")).toBeFalsy();

				expect(array_length(global.input.addCalls)).toBe(3);
				expect(array_length(global.input.bindCalls)).toBe(3);

				expect(global.settings.applyCalls).toBe(1);

				expect(array_length(global.gameState.setCalls)).toBe(1);
				expect(global.gameState.setCalls[0]).toBe(global.gameState.states.menu);

				expect(array_length(global.menus.showCalls)).toBeGreaterThan(0);
				expect(global.menus.showCalls[0]).toBe("intro");

				gmtlAc4RestoreGlobals(snap);
			});

			test("init creates a bus when none exists (sets global.events and global.eventBus)", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				gmtlAc4RemoveGlobal("events");
				gmtlAc4RemoveGlobal("eventBus");

				global.input = gmtlAc4MakeInputStub();
				global.menus = gmtlAc4MakeMenusStub();
				global.audio = gmtlAc4MakeInitOnlyStub();
				global.scenes = gmtlAc4MakeScenesStub();
				global.gameState = gmtlAc4MakeGameStateStub();
				global.settings = gmtlAc4MakeSettingsStub();
				global.time = gmtlAc4MakeInitOnlyStub();
				global.camera = gmtlAc4MakeInitOnlyStub();

				var app = new AppController();
				app.init();

				expect(is_struct(global.events)).toBeTruthy();
				expect(is_struct(global.eventBus)).toBeTruthy();
				expect(global.events).toBe(global.eventBus);

				gmtlAc4RestoreGlobals(snap);
			});

			test("update calls input.beginFrame/dispatchEvents around menus.update then scenes.update", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				var bus = gmtlAc4MakeBus();
				global.events = bus;

				global.input = gmtlAc4MakeInputStub();
				global.menus = gmtlAc4MakeMenusStub();
				global.audio = gmtlAc4MakeInitOnlyStub();
				global.scenes = gmtlAc4MakeScenesStub();
				global.gameState = gmtlAc4MakeGameStateStub();
				global.settings = gmtlAc4MakeSettingsStub();
				global.time = gmtlAc4MakeInitOnlyStub();
				global.camera = gmtlAc4MakeInitOnlyStub();

				var app = new AppController();
				app.init();

				global.input.clearConsumedCalls = 0;
				global.input.beginFrameCalls = 0;
				global.input.dispatchCalls = 0;
				global.input.updateCalls = 0;
				global.menus.updateCalls = 0;
				global.scenes.updateCalls = 0;

				app.update();

				expect(global.input.clearConsumedCalls).toBe(1);
				expect(global.input.beginFrameCalls).toBe(1);
				expect(global.input.dispatchCalls).toBe(1);
				expect(global.input.updateCalls).toBe(0);
				expect(global.menus.updateCalls).toBe(1);
				expect(global.scenes.updateCalls).toBe(1);

				gmtlAc4RestoreGlobals(snap);
			});

			test("drawGui calls scenes.drawGui then menus.drawGui", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				var bus = gmtlAc4MakeBus();
				global.events = bus;

				global.input = gmtlAc4MakeInputStub();
				global.menus = gmtlAc4MakeMenusStub();
				global.audio = gmtlAc4MakeInitOnlyStub();
				global.scenes = gmtlAc4MakeScenesStub();
				global.gameState = gmtlAc4MakeGameStateStub();
				global.settings = gmtlAc4MakeSettingsStub();
				global.time = gmtlAc4MakeInitOnlyStub();
				global.camera = gmtlAc4MakeInitOnlyStub();

				var app = new AppController();
				app.init();

				global.menus.drawCalls = 0;
				global.scenes.drawCalls = 0;

				app.drawGui();

				expect(global.scenes.drawCalls).toBe(1);
				expect(global.menus.drawCalls).toBe(1);

				gmtlAc4RestoreGlobals(snap);
			});

			test("onRoomStart forwards to scenes.onRoomStart", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				var bus = gmtlAc4MakeBus();
				global.events = bus;

				global.input = gmtlAc4MakeInputStub();
				global.menus = gmtlAc4MakeMenusStub();
				global.audio = gmtlAc4MakeInitOnlyStub();
				global.scenes = gmtlAc4MakeScenesStub();
				global.gameState = gmtlAc4MakeGameStateStub();
				global.settings = gmtlAc4MakeSettingsStub();
				global.time = gmtlAc4MakeInitOnlyStub();
				global.camera = gmtlAc4MakeInitOnlyStub();

				var app = new AppController();
				app.init();

				app.onRoomStart();

				expect(global.scenes.roomStartCalls).toBe(1);

				gmtlAc4RestoreGlobals(snap);
			});

			test("update uses gameState.isPlaying() to decide if console can open", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				global.events = new EventBus();
				global.input = gmtlAc4MakeInputStub();
				global.menus = gmtlAc4MakeMenusStub();
				global.audio = gmtlAc4MakeInitOnlyStub();
				global.scenes = gmtlAc4MakeScenesStub();
				global.settings = gmtlAc4MakeSettingsStub();
				global.keybinds = gmtlAc4MakeInitOnlyStub();
				global.time = gmtlAc4MakeInitOnlyStub();
				global.camera = gmtlAc4MakeInitOnlyStub();

				global.menus.isOpen = false;

				global.gameState = gmtlAc4MakeGameStateStub();

				global.gameState.calls = 0;
				global.gameState.calls = 0;

				global.gameState.isPlaying = method(global.gameState, function()
				{
					self.calls += 1;
					return true;
				});
				
				global.debugConsole =
				{
					updateCalls : [],

					consumed : false,
					isOpen : false,

					update : function(canOpen)
					{
						var n = array_length(self.updateCalls);
						self.updateCalls[n] = canOpen;
					}
				};

				var app = new AppController();
				app.init();

				app.update();

				expect(global.gameState.calls).toBe(1);
				expect(array_length(global.debugConsole.updateCalls)).toBe(1);
				expect(global.debugConsole.updateCalls[0]).toBeTruthy();

				gmtlAc4RestoreGlobals(snap);
			});

			test("Esc in pause menu emits unpause and does not emit pause in same frame", function()
			{
				var snap = gmtlAc4SnapshotGlobals();

				var bus = new EventBus();

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

				var input = new InputManager();
				input.setEventBus(bus);
				initInputInSystems(input, bus, keybinds);

				var menus = new MenuManager();
				menus.init(bus);
				if(variable_struct_exists(menus, "setKeybinds") && is_callable(menus.setKeybinds))
				{
					menus.setKeybinds(keybinds);
				}
				else
				{
					menus.keybinds = keybinds;
				}

				var gameState = new GameStateManager();
				gameState.init(bus);
				gameState.setState(gameState.states.playing);

				var debugConsole =
				{
					consumed : false,
					isOpen : false,
					pauseWhenOpen : true,

					update : function(canOpen) { }
				};

				var scenes =
				{
					updateCalls : 0,
					update : function() { self.updateCalls += 1; }
				};

				var app = new AppController();
				app.booted = true;
				app.events = bus;
				app.input = input;
				app.menus = menus;
				app.gameState = gameState;
				app.scenes = scenes;
				app.debugConsole = debugConsole;

				global.input = input;

				var pauseSpy = { count : 0 };
				pauseSpy.handle = function(payload, eventName, sender) { self.count += 1; };
				var unpauseSpy = { count : 0 };
				unpauseSpy.handle = function(payload, eventName, sender) { self.count += 1; };

				bus.on("game/pause", pauseSpy.handle, pauseSpy);
				bus.on("game/unpause", unpauseSpy.handle, unpauseSpy);

				simulateKeyPress(vk_escape);
				app.update();
				keyboard_clear(vk_escape);

				expect(pauseSpy.count).toBe(1);
				expect(unpauseSpy.count).toBe(0);
				expect(gameState.state).toBe(gameState.states.paused);
				expect(menus.isOpen).toBeTruthy();

				simulateKeyPress(vk_escape);
				app.update();
				keyboard_clear(vk_escape);

				expect(pauseSpy.count).toBe(1);
				expect(unpauseSpy.count).toBe(1);
				expect(gameState.state).toBe(gameState.states.playing);
				expect(menus.isOpen).toBeFalsy();

				gmtlAc4RestoreGlobals(snap);
			});
		});
	});
}
