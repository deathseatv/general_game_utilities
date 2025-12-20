function gmtlTimeMakeEmitBus()
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

function gmtlTimeMakeApplyToken()
{
	var token =
	{
		calls : [],

		run : function()
		{
			var entry =
			{
				isPaused : self.manager.isPaused,
				timeScale : self.manager.timeScale
			};

			var n = array_length(self.calls);
			self.calls[n] = entry;
		},

		manager : undefined
	};

	token.bound = method(token, token.run);
	return token;
}

function gmtlTimeTests()
{
	suite(function()
	{
		section("TimeManager", function()
		{
			test("constructs with defaults", function()
			{
				var tm = new TimeManager();

				expect(tm.isPaused).toBeFalsy();
				expect(tm.timeScale).toBe(1.0);
			});

			test("setPaused toggles state, calls apply, emits time/paused", function()
			{
				var tm = new TimeManager();
				var bus = gmtlTimeMakeEmitBus();
				var applyTok = gmtlTimeMakeApplyToken();

				applyTok.manager = tm;

				tm.apply = applyTok.bound;
				tm.init(bus);

				var ok = tm.setPaused(true);
				expect(ok).toBeTruthy();
				expect(tm.isPaused).toBeTruthy();

				expect(array_length(applyTok.calls)).toBe(1);
				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].eventName).toBe("time/paused");
				expect(bus.emits[0].payload.paused).toBeTruthy();

				ok = tm.setPaused(true);
				expect(ok).toBeFalsy();
				expect(array_length(applyTok.calls)).toBe(1);
				expect(array_length(bus.emits)).toBe(1);

				ok = tm.setPaused(false);
				expect(ok).toBeTruthy();
				expect(tm.isPaused).toBeFalsy();

				expect(array_length(applyTok.calls)).toBe(2);
				expect(array_length(bus.emits)).toBe(2);
				expect(bus.emits[1].payload.paused).toBeFalsy();
			});

			test("setTimeScale clamps [0, 1], calls apply, emits time/scaleChanged only on change", function()
			{
				var tm = new TimeManager();
				var bus = gmtlTimeMakeEmitBus();
				var applyTok = gmtlTimeMakeApplyToken();

				applyTok.manager = tm;

				tm.apply = applyTok.bound;
				tm.init(bus);

				var ok = tm.setTimeScale(1.5);
				expect(ok).toBeFalsy();
				expect(tm.timeScale).toBe(1.0);
				expect(array_length(bus.emits)).toBe(0);

				ok = tm.setTimeScale(0.75);
				expect(ok).toBeTruthy();
				expect(tm.timeScale).toBe(0.75);

				expect(array_length(applyTok.calls)).toBe(1);
				expect(array_length(bus.emits)).toBe(1);
				expect(bus.emits[0].eventName).toBe("time/scaleChanged");
				expect(bus.emits[0].payload.prev).toBe(1.0);
				expect(bus.emits[0].payload.value).toBe(0.75);

				ok = tm.setTimeScale(-5);
				expect(ok).toBeTruthy();
				expect(tm.timeScale).toBe(0.0);

				expect(array_length(applyTok.calls)).toBe(2);
				expect(array_length(bus.emits)).toBe(2);
				expect(bus.emits[1].payload.prev).toBe(0.75);
				expect(bus.emits[1].payload.value).toBe(0.0);

				ok = tm.setTimeScale(0.0);
				expect(ok).toBeFalsy();
				expect(array_length(applyTok.calls)).toBe(2);
			});

			test("pause/entered and pause/exited events drive pause state", function()
			{
				var bus = new EventBus();
				var tm = new TimeManager();

				tm.apply = function() { };
				tm.init(bus);

				expect(tm.isPaused).toBeFalsy();

				bus.emit("pause/entered", { }, noone);
				expect(tm.isPaused).toBeTruthy();

				bus.emit("pause/exited", { }, noone);
				expect(tm.isPaused).toBeFalsy();
			});

			test("time/setScale event routes into setTimeScale", function()
			{
				var bus = new EventBus();
				var tm = new TimeManager();

				tm.apply = function() { };
				tm.init(bus);

				bus.emit("time/setScale", { value : 0.25 }, noone);
				expect(tm.timeScale).toBe(0.25);
			});
		});
	});
}
