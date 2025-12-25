function gmtlIntegrationMakeEventSpy()
{
	var spy =
	{
		count : 0,
		lastPayload : undefined,
		lastEventName : "",

		onEvent : function(payload, eventName, sender)
		{
			self.count += 1;
			self.lastPayload = payload;
			self.lastEventName = eventName;
		}
	};

	spy.handler = method(spy, spy.onEvent);
	return spy;
}

function gmtlIntegrationMakeUpdateSpy()
{
	return
	{
		calls : 0,
		isOpen : false,

		init : function(bus) { },

		update : function()
		{
			self.calls += 1;
		},

		drawGui : function() { },

		onRoomStart : function() { }
	};
}

function gmtlIntegrationMakeSetMasterRecorder()
{
	var rec =
	{
		calls : [],

		run : function(v)
		{
			var n = array_length(self.calls);
			self.calls[n] = { v : v };
		}
	};

	rec.bound = method(rec, rec.run);
	return rec;
}

function gmtlIntegrationMakeSetBusRecorder()
{
	var rec =
	{
		calls : [],

		run : function(busName, v, fadeMs)
		{
			var n = array_length(self.calls);
			self.calls[n] = { busName : busName, v : v, fadeMs : fadeMs };
		}
	};

	rec.bound = method(rec, rec.run);
	return rec;
}

function gmtlIntegrationTests()
{
	suite(function()
	{
		section("Integration", function()
		{
			test("Input -> Pause chain: Esc pauses + opens pause menu", function()
			{
				var bus = new EventBus();

				var input = new InputManager();
				initInputInSystems(input, bus);

				var gameState = new GameStateManager();
				gameState.init(bus);
				gameState.setState(gameState.states.playing);

				var menus = new MenuManager();
				menus.init(bus);
				menus.close();

				var scenes = { };

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

				simulateKeyPress(vk_escape);
				input.update();
				keyboard_clear(vk_escape);

				expect(gameState.state).toBe(gameState.states.paused);
				expect(menus.isOpen).toBeTruthy();
				expect(menus.currentMenuId).toBe("pause");
			});

			test("Input binding: F10 emits video/toggleFullscreen", function()
			{
				var bus = new EventBus();

				var spy = gmtlIntegrationMakeEventSpy();
				bus.on("video/toggleFullscreen", spy.handler);

				var input = new InputManager();
				initInputInSystems(input, bus);

				simulateKeyPress(vk_f10);
				input.update();
				keyboard_clear(vk_f10);

				expect(spy.count).toBe(1);
				expect(spy.lastEventName).toBe("video/toggleFullscreen");
				expect(is_struct(spy.lastPayload)).toBeTruthy();
				expect(spy.lastPayload.signal).toBe("toggleFullscreen");
			});

			test("Menu -> UI hover sound emits audio/playUi (keyboard selection change)", function()
			{
				var bus = new EventBus();

				var spy = gmtlIntegrationMakeEventSpy();
				bus.on("audio/playUi", spy.handler);

				var menus = new MenuManager();
				menus.init(bus);

				menus.resolveSoundId = function(soundName)
				{
					return 1;
				};

				menus.show("main");
				menus.inputLockFrames = 0;

				menus.update();

				simulateKeyPress(vk_down);
				menus.update();
				keyboard_clear(vk_down);

				expect(spy.count).toBe(1);
				expect(spy.lastEventName).toBe("audio/playUi");
				expect(is_struct(spy.lastPayload)).toBeTruthy();
				expect(spy.lastPayload.sound).toBe(1);
			});

			test("Menu -> UI select sound emits audio/playUi (enter on action)", function()
			{
				var bus = new EventBus();

				var spy = gmtlIntegrationMakeEventSpy();
				bus.on("audio/playUi", spy.handler);

				var menus = new MenuManager();
				menus.init(bus);

				menus.resolveSoundId = function(soundName)
				{
					return 1;
				};

				menus.show("main");
				menus.inputLockFrames = 0;

				menus.update();

				simulateKeyPress(vk_enter);
				menus.update();
				keyboard_clear(vk_enter);

				expect(spy.count).toBe(1);
				expect(spy.lastEventName).toBe("audio/playUi");
				expect(is_struct(spy.lastPayload)).toBeTruthy();
				expect(spy.lastPayload.sound).toBe(1);
			});

			test("Settings -> Audio: apply triggers AudioManager volume setters", function()
			{
				var bus = new EventBus();

				var audio = new AudioManager();

				var masterRec = gmtlIntegrationMakeSetMasterRecorder();
				var busRec = gmtlIntegrationMakeSetBusRecorder();

				audio.setMasterVolume = masterRec.bound;
				audio.setBusVolume = busRec.bound;

				audio.init(bus);

				var settings = new SettingsManager();
				settings.init(bus);

				settings.set("masterVolume", 0.5);
				settings.set("musicVolume", 0.4);
				settings.set("sfxVolume", 0.3);
				settings.set("uiVolume", 0.2);

				settings.apply();

				expect(array_length(masterRec.calls)).toBe(1);
				expect(masterRec.calls[0].v).toBe(0.5);

				expect(array_length(busRec.calls)).toBe(3);

				expect(busRec.calls[0].busName).toBe("music");
				expect(busRec.calls[0].v).toBe(0.4);
				expect(busRec.calls[0].fadeMs).toBe(0);

				expect(busRec.calls[1].busName).toBe("sfx");
				expect(busRec.calls[1].v).toBe(0.3);
				expect(busRec.calls[1].fadeMs).toBe(0);

				expect(busRec.calls[2].busName).toBe("ui");
				expect(busRec.calls[2].v).toBe(0.2);
				expect(busRec.calls[2].fadeMs).toBe(0);
			});

			test("AppController + DebugConsole: tilde/escape consumes + gates updates, then restores", function()
			{
				var app = new AppController();
				app.booted = true;

				var inputSpy = gmtlIntegrationMakeUpdateSpy();
				var menusSpy = gmtlIntegrationMakeUpdateSpy();
				var scenesSpy = gmtlIntegrationMakeUpdateSpy();

				menusSpy.isOpen = false;

				var gameStateStub =
				{
					states : { playing : "playing" },
					state : "playing"
				};

				var console = new DebugConsole();
				console.pauseWhenOpen = true;

				app.input = inputSpy;
				app.menus = menusSpy;
				app.scenes = scenesSpy;
				app.gameState = gameStateStub;
				app.debugConsole = console;

				simulateKeyPress(console.openKey);
				app.update();
				keyboard_clear(console.openKey);

				expect(console.isOpen).toBeTruthy();
				expect(inputSpy.calls).toBe(0);

				app.update();
				expect(inputSpy.calls).toBe(0);

				simulateKeyPress(vk_escape);
				app.update();
				keyboard_clear(vk_escape);

				expect(console.isOpen).toBeFalsy();
				expect(inputSpy.calls).toBe(0);

				app.update();
				expect(inputSpy.calls).toBe(1);
				expect(menusSpy.calls).toBe(1);
				expect(scenesSpy.calls).toBe(1);
			});

			test("Input binding: invalid pause keybind (0) falls back to Esc", function()
			{
				var bus = new EventBus();

				var spy = gmtlIntegrationMakeEventSpy();
				bus.on("game/pause", spy.handler);

				var input = new InputManager();

				var keybinds =
				{
					getKey : function(actionName)
					{
						if(string(actionName) == "pause")
						{
							return 0;
						}

						return -1;
					}
				};

				initInputInSystems(input, bus, keybinds);

				var gameState = new GameStateManager();
				gameState.init(bus);
				gameState.setState(gameState.states.playing);

				var scenes = { };

				var flow = new FlowManager();
				flow.init(bus,
				{
					mode : "events",
					input : input,
					scenes : scenes,
					gameState : gameState,
					wire : true
				});

				flow.wire();

				simulateKeyPress(vk_escape);
				input.update();
				keyboard_clear(vk_escape);

				expect(spy.count).toBe(1);
				expect(spy.lastEventName).toBe("game/pause");
			});
		});
	});
}
