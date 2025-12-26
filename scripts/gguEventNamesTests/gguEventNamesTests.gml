suite(function()
{
	section("GguEventNames", function()
	{
		test("gguEventNamesDefaults returns a struct with known keys", function()
		{
			var defaults = gguEventNamesDefaults();

			expect(is_struct(defaults)).toBeTruthy();
			expect(defaults.menuShow).toBe("menu/show");
			expect(defaults.gamePause).toBe("game/pause");
			expect(defaults.pauseEntered).toBe("pause/entered");
			expect(defaults.gameplayEnter).toBe("gameplay/enter");
		});

		test("gguEventNamesEnsure creates global.eventNames when missing", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			if(variable_global_exists("eventNames"))
			{
				gguTestGlobalUnset("eventNames");
			}

			var ensured = gguEventNamesEnsure();

			expect(variable_global_exists("eventNames")).toBeTruthy();
			expect(is_struct(global.eventNames)).toBeTruthy();
			expect(is_struct(ensured)).toBeTruthy();
			expect(ensured.menuShow).toBe("menu/show");

			gguTestRestoreGlobals(snap);
		});

		test("gguEventNamesEnsure replaces non-struct global.eventNames with defaults", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			global.eventNames = 123;

			var ensured = gguEventNamesEnsure();

			expect(is_struct(global.eventNames)).toBeTruthy();
			expect(is_struct(ensured)).toBeTruthy();
			expect(ensured.menuShow).toBe("menu/show");

			gguTestRestoreGlobals(snap);
		});

		test("gguEventNamesEnsure merges missing keys without overwriting existing keys", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			global.eventNames =
			{
				menuShow : "menu/customShow"
			};

			var ensured = gguEventNamesEnsure();

			expect(ensured.menuShow).toBe("menu/customShow");
			expect(ensured.menuClose).toBe("menu/close");
			expect(ensured.gamePause).toBe("game/pause");

			gguTestRestoreGlobals(snap);
		});

		test("gguEventName returns override from global.eventNames when present", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			global.eventNames =
			{
				menuShow : "menu/customShow"
			};

			var v = gguEventName("menuShow");

			expect(v).toBe("menu/customShow");

			gguTestRestoreGlobals(snap);
		});

		test("gguEventName returns defaults when not overridden", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			if(variable_global_exists("eventNames"))
			{
				gguTestGlobalUnset("eventNames");
			}

			var v = gguEventName("menuShow");

			expect(v).toBe("menu/show");

			gguTestRestoreGlobals(snap);
		});

		test("gguEventName returns fallback for unknown key when fallback provided", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			if(variable_global_exists("eventNames"))
			{
				gguTestGlobalUnset("eventNames");
			}

			var v = gguEventName("doesNotExist", "some/fallback");

			expect(v).toBe("some/fallback");

			gguTestRestoreGlobals(snap);
		});

		test("gguEventName returns empty string for unknown key without fallback", function()
		{
			var snap = gguTestSnapshotGlobals([ "eventNames" ]);

			global.eventNames = { };

			var v = gguEventName("doesNotExist");
			
			// show_debug_message("gguEventName(doesNotExist) = " + string(v) + " | undef=" + string(is_undefined(v)) + " | str=" + string(is_string(v)) + " | real=" + string(is_real(v)));

			expect(is_undefined(v) || v == "").toBeTruthy();

			gguTestRestoreGlobals(snap);
		});

	});
});
