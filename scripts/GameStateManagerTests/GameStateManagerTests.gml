function gmtlGsMakeEmitBus()
{
	return
	{
		emits : [],

		emit : function(eventName, payload, sender)
		{
			var entry =
			{
				eventName : eventName,
				payload : payload,
				sender : sender
			};

			var n = array_length(self.emits);
			self.emits[n] = entry;

			return 1;
		},

		on : function(eventName, handler, ctx)
		{
			return function() { };
		}
	};
}

function gmtlGsCountEmits(bus, name)
{
	var c = 0;
	var n = array_length(bus.emits);

	for(var i = 0; i < n; i += 1)
	{
		if(bus.emits[i].eventName == name)
		{
			c += 1;
		}
	}

	return c;
}

function gmtlGsLastEmit(bus, name)
{
	var n = array_length(bus.emits);

	for(var i = n - 1; i >= 0; i -= 1)
	{
		if(bus.emits[i].eventName == name)
		{
			return bus.emits[i];
		}
	}

	return undefined;
}

function gmtlGameStateManagerTests()
{
	suite(function()
	{
		section("GameStateManager", function()
		{
			test("constructs in boot with empty stack", function()
			{
				var gs = new GameStateManager();

				expect(gs.getState()).toBe(gs.states.boot);
				expect(array_length(gs.stack)).toBe(0);
			});

			test("setState rejects invalid and same-state transitions", function()
			{
				var gs = new GameStateManager();

				expect(gs.setState("nope")).toBeFalsy();
				expect(gs.setState(gs.states.boot)).toBeFalsy();

				expect(gs.setState(gs.states.menu)).toBeTruthy();
				expect(gs.getState()).toBe(gs.states.menu);

				expect(gs.setState(gs.states.menu)).toBeFalsy();
			});

			test("setState emits state/changed and pause events appropriately", function()
			{
				var gs = new GameStateManager();
				var bus = gmtlGsMakeEmitBus();

				gs.init(bus);

				gs.setState(gs.states.playing);

				expect(gmtlGsCountEmits(bus, "state/changed")).toBe(1);
				expect(gmtlGsCountEmits(bus, "pause/entered")).toBe(0);
				expect(gmtlGsCountEmits(bus, "pause/exited")).toBe(0);

				gs.setState(gs.states.paused);

				expect(gmtlGsCountEmits(bus, "state/changed")).toBe(2);
				expect(gmtlGsCountEmits(bus, "pause/entered")).toBe(1);

				gs.setState(gs.states.playing);

				expect(gmtlGsCountEmits(bus, "state/changed")).toBe(3);
				expect(gmtlGsCountEmits(bus, "pause/exited")).toBe(1);
			});

			test("pushState pushes previous and popState restores it", function()
			{
				var gs = new GameStateManager();

				gs.setState(gs.states.playing);

				expect(gs.pushState(gs.states.paused)).toBeTruthy();
				expect(gs.getState()).toBe(gs.states.paused);
				expect(array_length(gs.stack)).toBe(1);

				expect(gs.popState()).toBeTruthy();
				expect(gs.getState()).toBe(gs.states.playing);
				expect(array_length(gs.stack)).toBe(0);
			});

			test("popState returns false when stack empty", function()
			{
				var gs = new GameStateManager();

				expect(gs.popState()).toBeFalsy();
			});

			test("onPauseRequested only pauses from playing", function()
			{
				var gs = new GameStateManager();
				var bus = gmtlGsMakeEmitBus();

				gs.init(bus);

				gs.setState(gs.states.menu);
				gs.onPauseRequested({ }, "game/pause", noone);

				expect(gs.getState()).toBe(gs.states.menu);
				expect(gmtlGsCountEmits(bus, "menu/show")).toBe(0);

				gs.setState(gs.states.playing);
				gs.onPauseRequested({ }, "game/pause", noone);

				expect(gs.getState()).toBe(gs.states.paused);

				var e = gmtlGsLastEmit(bus, "menu/show");
				expect(is_undefined(e)).toBeFalsy();
				expect(e.payload.menuId).toBe("pause");
			});

			test("onUnpauseRequested pops if paused, otherwise sets playing when not playing", function()
			{
				var gs = new GameStateManager();

				gs.setState(gs.states.playing);
				gs.pushState(gs.states.paused);

				gs.onUnpauseRequested({ }, "game/unpause", noone);
				expect(gs.getState()).toBe(gs.states.playing);

				gs.setState(gs.states.menu);
				gs.onUnpauseRequested({ }, "game/unpause", noone);
				expect(gs.getState()).toBe(gs.states.playing);
			});

			test("onSceneDidLoad moves boot->menu and loading->playing (and closes menu)", function()
			{
				var gs = new GameStateManager();
				var bus = gmtlGsMakeEmitBus();

				gs.init(bus);

				gs.setState(gs.states.boot);
				gs.onSceneDidLoad({ }, "scene/didLoad", noone);

				expect(gs.getState()).toBe(gs.states.menu);

				gs.setState(gs.states.loading);
				gs.onSceneDidLoad({ }, "scene/didLoad", noone);

				expect(gs.getState()).toBe(gs.states.playing);

				var e = gmtlGsLastEmit(bus, "menu/close");
				expect(is_undefined(e)).toBeFalsy();
			});

			test("onGameStart sets loading and emits scene/load when sceneId provided", function()
			{
				var gs = new GameStateManager();
				var bus = gmtlGsMakeEmitBus();

				gs.init(bus);

				gs.onGameStart({ sceneId : "rm_game" }, "game/start", noone);

				expect(gs.getState()).toBe(gs.states.loading);

				var loadEvt = gmtlGsLastEmit(bus, "scene/load");
				expect(is_undefined(loadEvt)).toBeFalsy();
				expect(loadEvt.payload.sceneId).toBe("rm_game");

				var menuEvt = gmtlGsLastEmit(bus, "menu/show");
				expect(is_undefined(menuEvt)).toBeFalsy();
				expect(menuEvt.payload.menuId).toBe("loading");
			});

			test("onMainMenu clears stack and sets menu", function()
			{
				var gs = new GameStateManager();
				var bus = gmtlGsMakeEmitBus();

				gs.init(bus);

				gs.setState(gs.states.playing);
				gs.pushState(gs.states.paused);

				gs.onMainMenu({ }, "game/mainMenu", noone);

				expect(gs.getState()).toBe(gs.states.menu);
				expect(array_length(gs.stack)).toBe(0);

				var e = gmtlGsLastEmit(bus, "menu/show");
				expect(is_undefined(e)).toBeFalsy();
				expect(e.payload.menuId).toBe("main");
			});

			test("onGameOver clears stack and sets gameOver", function()
			{
				var gs = new GameStateManager();

				gs.setState(gs.states.playing);
				gs.pushState(gs.states.paused);

				gs.onGameOver({ }, "game/gameOver", noone);

				expect(gs.getState()).toBe(gs.states.gameOver);
				expect(array_length(gs.stack)).toBe(0);
			});

			test("init subscribes to EventBus and routes key events to handlers", function()
			{
				var bus = new EventBus();
				var gs = new GameStateManager();

				gs.init(bus);

				gs.setState(gs.states.playing);
				bus.emit("game/pause", { }, noone);
				expect(gs.getState()).toBe(gs.states.paused);

				bus.emit("game/unpause", { }, noone);
				expect(gs.getState()).toBe(gs.states.playing);

				bus.emit("game/start", { sceneId : "rm_game" }, noone);
				expect(gs.getState()).toBe(gs.states.loading);
			});
		});
	});
}
