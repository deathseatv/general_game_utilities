function gmtlSceneManagerMakeEmitBus()
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

function gmtlSceneManagerMakeCallToken()
{
	var token =
	{
		loadCalls : [],
		reloadCalls : 0,
		nextCalls : 0,

		load : function(sceneId)
		{
			var n = array_length(self.loadCalls);
			self.loadCalls[n] = sceneId;
			return true;
		},

		reload : function()
		{
			self.reloadCalls += 1;
			return true;
		},

		next : function()
		{
			self.nextCalls += 1;
			return true;
		}
	};

	token.loadBound = method(token, token.load);
	token.reloadBound = method(token, token.reload);
	token.nextBound = method(token, token.next);

	return token;
}

function gmtlSceneManagerTests()
{
	suite(function()
	{
		section("SceneManager", function()
		{
			test("constructs with expected defaults", function()
			{
				var sm = new SceneManager();

				expect(sm.fadeFrames).toBe(20);
				expect(sm.fadeAlpha).toBe(0.0);

				expect(sm.isTransitioning).toBeFalsy();
				expect(sm.isLoading).toBeFalsy();

				expect(sm.phase).toBe("idle");

				expect(sm.pendingRoom).toBe(-1);
				expect(sm.pendingFromRoom).toBe(-1);
				expect(sm.pendingMode).toBe("");
			});

			test("setFadeFrames clamps to >= 1 and ignores non-real", function()
			{
				var sm = new SceneManager();

				sm.setFadeFrames(0);
				expect(sm.fadeFrames).toBe(1);

				sm.setFadeFrames(-10);
				expect(sm.fadeFrames).toBe(1);

				sm.setFadeFrames(5);
				expect(sm.fadeFrames).toBe(5);

				sm.setFadeFrames("nope");
				expect(sm.fadeFrames).toBe(5);
			});

			test("resolveRoom passes numeric ids through, string uses asset_get_index", function()
			{
				var sm = new SceneManager();

				expect(sm.resolveRoom(123)).toBe(123);
				expect(sm.resolveRoom(undefined)).toBe(-1);

				var r = sm.resolveRoom("rm_not_real_probably");
				expect(is_real(r)).toBeTruthy();
			});

			test("load invalid sceneId returns false and does not start transition", function()
			{
				var sm = new SceneManager();

				var ok = sm.load(undefined);

				expect(ok).toBeFalsy();
				expect(sm.isTransitioning).toBeFalsy();
				expect(sm.phase).toBe("idle");
			});

			test("load starts fadeOut, sets pending fields, emits scene/willLoad", function()
			{
				var sm = new SceneManager();
				var bus = gmtlSceneManagerMakeEmitBus();

				sm.setEventBus(bus);

				var targetRoom = 1;

				var ok = sm.load(targetRoom);

				expect(ok).toBeTruthy();

				expect(sm.isTransitioning).toBeTruthy();
				expect(sm.isLoading).toBeTruthy();
				expect(sm.phase).toBe("fadeOut");
				expect(sm.fadeAlpha).toBe(0.0);

				expect(sm.pendingFromRoom).toBe(room);
				expect(sm.pendingRoom).toBe(targetRoom);
				expect(sm.pendingMode).toBe("load");

				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].eventName).toBe("scene/willLoad");
				expect(bus.emits[0].payload.from).toBe(room);
				expect(bus.emits[0].payload.to).toBe(targetRoom);
				expect(bus.emits[0].payload.mode).toBe("load");
			});

			test("reload starts transition with mode reload and pendingRoom == current room", function()
			{
				var sm = new SceneManager();
				var bus = gmtlSceneManagerMakeEmitBus();

				sm.setEventBus(bus);

				var ok = sm.reload();

				expect(ok).toBeTruthy();
				expect(sm.pendingFromRoom).toBe(room);
				expect(sm.pendingRoom).toBe(room);
				expect(sm.pendingMode).toBe("reload");

				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].payload.mode).toBe("reload");
			});

			test("next starts transition with mode next and pendingRoom == -1", function()
			{
				var sm = new SceneManager();
				var bus = gmtlSceneManagerMakeEmitBus();

				sm.setEventBus(bus);

				var ok = sm.next();

				expect(ok).toBeTruthy();
				expect(sm.pendingFromRoom).toBe(room);
				expect(sm.pendingRoom).toBe(-1);
				expect(sm.pendingMode).toBe("next");

				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].payload.mode).toBe("next");
			});

			test("update progresses fadeOut to switch without invoking room change", function()
			{
				var sm = new SceneManager();
				sm.setFadeFrames(2);

				var ok = sm.load(1);
				expect(ok).toBeTruthy();

				sm.update();
				expect(sm.phase).toBe("fadeOut");
				expect(sm.fadeAlpha).toBe(0.5);

				sm.update();
				expect(sm.phase).toBe("switch");
				expect(sm.fadeAlpha).toBe(1.0);
				expect(sm.isTransitioning).toBeTruthy();
				expect(sm.isLoading).toBeTruthy();
			});

			test("onRoomStart emits scene/didLoad only when isLoading is true", function()
			{
				var sm = new SceneManager();
				var bus = gmtlSceneManagerMakeEmitBus();

				sm.setEventBus(bus);

				sm.isLoading = false;
				sm.pendingMode = "load";
				sm.onRoomStart();
				expect(array_length(bus.emits)).toBe(0);

				sm.isLoading = true;
				sm.pendingMode = "load";
				sm.onRoomStart();

				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].eventName).toBe("scene/didLoad");
				expect(bus.emits[0].payload.room).toBe(room);
				expect(bus.emits[0].payload.mode).toBe("load");
			});

			test("init subscribes to EventBus and routes scene events to API", function()
			{
				var bus = new EventBus();
				var sm = new SceneManager();
				var token = gmtlSceneManagerMakeCallToken();

				sm.load = token.loadBound;
				sm.reload = token.reloadBound;
				sm.next = token.nextBound;

				sm.init(bus);

				bus.emit("scene/load", { sceneId : 777 }, noone);
				expect(array_length(token.loadCalls)).toBe(1);
				expect(token.loadCalls[0]).toBe(777);

				bus.emit("scene/reload", { }, noone);
				expect(token.reloadCalls).toBe(1);

				bus.emit("scene/next", { }, noone);
				expect(token.nextCalls).toBe(1);

				bus.emit("state/changed", { state : "playing" }, noone);
				expect(true).toBeTruthy();
			});
		});
	});
}
