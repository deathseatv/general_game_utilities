suite(function()
{
	section("GguLifecycle", function()
	{
		test("gguLifecycleInstall returns false when no valid events bus", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = undefined;
			global.eventBus = undefined;

			var ok = gguLifecycleInstall();

			expect(ok).toBeFalsy();

			gguTestRestoreGlobals(snap);
		});

		test("gguLifecycleInstall installs once and returns false on second install", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();

			var ok1 = gguLifecycleInstall();
			var ok2 = gguLifecycleInstall();

			expect(ok1).toBeTruthy();
			expect(ok2).toBeFalsy();
			expect(gguLifecycleIsInstalled()).toBeTruthy();

			gguLifecycleUninstall();

			gguTestRestoreGlobals(snap);
		});

		test("install emits lifecycle/booted when app.booted is true", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(true);
			global.events = new EventBus();

			var bootEvent = gguEventName("lifecycleBooted", "lifecycle/booted");
			var spy = gguTestMakeEventSpy();

			global.events.on(bootEvent, spy.handler);

			var ok = gguLifecycleInstall();

			expect(ok).toBeTruthy();
			expect(spy.count).toBe(1);
			expect(spy.lastEventName).toBe(bootEvent);

			gguLifecycleUninstall();

			gguTestRestoreGlobals(snap);
		});

		test("game/start emits gameplay/enter and sets inGameplay true", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();

			var enterEvent = gguEventName("gameplayEnter", "gameplay/enter");
			var startEvent = gguEventName("gameStart", "game/start");

			var spy = gguTestMakeEventSpy();
			global.events.on(enterEvent, spy.handler);

			gguLifecycleInstall();

			var payload = { from : "test" };
			global.events.emit(startEvent, payload, noone);

			expect(global.gguLifecycle.inGameplay).toBeTruthy();
			expect(spy.count).toBe(1);
			expect(spy.lastEventName).toBe(enterEvent);
			expect(spy.lastPayload.from).toBe("test");

			gguLifecycleUninstall();

			gguTestRestoreGlobals(snap);
		});

		test("game/mainMenu emits gameplay/exit only when inGameplay is true", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();

			var startEvent = gguEventName("gameStart", "game/start");
			var exitEvent = gguEventName("gameplayExit", "gameplay/exit");
			var mainMenuEvent = gguEventName("gameMainMenu", "game/mainMenu");

			var spy = gguTestMakeEventSpy();
			global.events.on(exitEvent, spy.handler);

			gguLifecycleInstall();

			global.events.emit(mainMenuEvent, { }, noone);
			expect(spy.count).toBe(0);

			global.events.emit(startEvent, { }, noone);
			expect(global.gguLifecycle.inGameplay).toBeTruthy();

			global.events.emit(mainMenuEvent, { why : "test" }, noone);
			expect(spy.count).toBe(1);
			expect(spy.lastPayload.why).toBe("test");
			expect(global.gguLifecycle.inGameplay).toBeFalsy();

			global.events.emit(mainMenuEvent, { }, noone);
			expect(spy.count).toBe(1);

			gguLifecycleUninstall();

			gguTestRestoreGlobals(snap);
		});

		test("game/pause bridges into pause/entered once; game/unpause bridges pause/exited once", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();

			var pauseEntered = gguEventName("pauseEntered", "pause/entered");
			var pauseExited = gguEventName("pauseExited", "pause/exited");
			var gamePause = gguEventName("gamePause", "game/pause");
			var gameUnpause = gguEventName("gameUnpause", "game/unpause");

			var spyEnter = gguTestMakeEventSpy();
			var spyExit = gguTestMakeEventSpy();

			global.events.on(pauseEntered, spyEnter.handler);
			global.events.on(pauseExited, spyExit.handler);

			gguLifecycleInstall();

			expect(global.gguLifecycle.paused).toBeFalsy();

			global.events.emit(gamePause, { }, noone);
			expect(global.gguLifecycle.paused).toBeTruthy();
			expect(spyEnter.count).toBe(1);

			global.events.emit(gamePause, { }, noone);
			expect(spyEnter.count).toBe(1);

			global.events.emit(gameUnpause, { }, noone);
			expect(global.gguLifecycle.paused).toBeFalsy();
			expect(spyExit.count).toBe(1);

			global.events.emit(gameUnpause, { }, noone);
			expect(spyExit.count).toBe(1);

			gguLifecycleUninstall();

			gguTestRestoreGlobals(snap);
		});

		test("gguLifecycleUninstall removes handlers (no further state updates)", function()
		{
			var snap = gguTestSnapshotGlobals([ "events", "eventBus", "gguLifecycle", "gguServices", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();

			var gamePause = gguEventName("gamePause", "game/pause");

			gguLifecycleInstall();
			expect(global.gguLifecycle.paused).toBeFalsy();

			gguLifecycleUninstall();
			expect(gguLifecycleIsInstalled()).toBeFalsy();

			global.events.emit(gamePause, { }, noone);
			expect(global.gguLifecycle.paused).toBeFalsy();

			gguTestRestoreGlobals(snap);
		});
	});
});
