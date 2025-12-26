suite(function()
{
	section("GguServices", function()
	{
		test("gguServicesEnsure(false) does not auto-init AppController (does not replace existing app)", function()
		{
			var snap = gguTestSnapshotGlobals([ "app", "gguServices", "events", "eventBus", "eventNames" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();

			var s = gguServicesEnsure(false);

			expect(is_struct(s)).toBeTruthy();
			expect(s.app).toBe(global.app);
			expect(is_struct(s.events)).toBeTruthy();
			expect(is_struct(global.gguServices)).toBeTruthy();

			gguTestRestoreGlobals(snap);
		});

		test("gguServicesEnsure uses global.events when present", function()
		{
			var snap = gguTestSnapshotGlobals([ "gguServices", "events", "eventBus", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();
			global.eventBus = new EventBus();

			var s = gguServicesEnsure(false);

			expect(s.events).toBe(global.events);

			gguTestRestoreGlobals(snap);
		});

		test("gguServicesEnsure falls back to global.eventBus when global.events is not a struct", function()
		{
			var snap = gguTestSnapshotGlobals([ "gguServices", "events", "eventBus", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = undefined;
			global.eventBus = new EventBus();

			var s = gguServicesEnsure(false);

			expect(s.events).toBe(global.eventBus);

			gguTestRestoreGlobals(snap);
		});

		test("gguService(name) returns field from global.gguServices", function()
		{
			var snap = gguTestSnapshotGlobals([ "gguServices", "events", "eventNames", "app" ]);

			global.app = gguTestMakeAppStub(false);
			global.events = new EventBus();
			gguServicesEnsure(false);

			var ev = gguService("events");

			expect(ev).toBe(global.events);

			gguTestRestoreGlobals(snap);
		});
	});
});
