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
		"time",
		"camera"
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

		updateCalls : 0,

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

			test("update calls input.update then menus.update then scenes.update", function()
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

				global.input.updateCalls = 0;
				global.menus.updateCalls = 0;
				global.scenes.updateCalls = 0;

				app.update();

				expect(global.input.updateCalls).toBe(1);
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
		});
	});
}
