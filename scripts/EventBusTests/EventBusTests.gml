function gmtlEventBusMakeSpy()
{
	var spy =
	{
		count : 0,
		lastPayload : undefined,
		lastEvent : "",
		lastSender : noone,

		handle : function(payload, eventName, sender)
		{
			count += 1;
			lastPayload = payload;
			lastEvent = eventName;
			lastSender = sender;
		}
	};

	spy.bound = method(spy, spy.handle);
	return spy;
}

function gmtlEventBusTests()
{
	suite(function()
	{
		section("EventBus", function()
		{
			test("on + emit fires once, returns count, forwards args", function()
			{
				var bus = new EventBus();
				var spy = gmtlEventBusMakeSpy();
				var senderId = 1234;

				bus.on("a", spy.bound);

				var fired = bus.emit("a", { x : 1 }, senderId);

				expect(spy.count).toBe(1);
				expect(fired).toBe(1);
				expect(spy.lastEvent).toBe("a");
				expect(spy.lastSender).toBe(senderId);
			});

			test("unsubscribe removes listener", function()
			{
				var bus = new EventBus();
				var spy = gmtlEventBusMakeSpy();

				var unsub = bus.on("a", spy.bound);
				unsub();

				var fired = bus.emit("a", { }, 1234);

				expect(spy.count).toBe(0);
				expect(fired).toBe(0);
			});

			test("once fires only once", function()
			{
				var bus = new EventBus();
				var spy = gmtlEventBusMakeSpy();

				bus.once("a", spy.bound);

				bus.emit("a", { }, 1234);
				bus.emit("a", { }, 1234);

				expect(spy.count).toBe(1);
			});

			test("context binding works (3rd arg)", function()
			{
				var bus = new EventBus();
				var ctx = { total : 0 };

				var add = function(value)
				{
					total += value;
				};

				bus.on("a", add, ctx);
				bus.emit("a", 5, 1234);

				expect(ctx.total).toBe(5);
			});

			test("clear(eventName) clears only that event", function()
			{
				var bus = new EventBus();
				var spyA = gmtlEventBusMakeSpy();
				var spyB = gmtlEventBusMakeSpy();

				bus.on("a", spyA.bound);
				bus.on("b", spyB.bound);

				bus.clear("a");

				var firedA = bus.emit("a", { }, 1234);
				var firedB = bus.emit("b", { }, 1234);

				expect(firedA).toBe(0);
				expect(firedB).toBe(1);
				expect(spyA.count).toBe(0);
				expect(spyB.count).toBe(1);
			});

			test("clear() clears all events", function()
			{
				var bus = new EventBus();
				var spyA = gmtlEventBusMakeSpy();
				var spyB = gmtlEventBusMakeSpy();

				bus.on("a", spyA.bound);
				bus.on("b", spyB.bound);

				bus.clear();

				expect(bus.emit("a", { }, 1234)).toBe(0);
				expect(bus.emit("b", { }, 1234)).toBe(0);
			});

			test("invalid subscriptions are no-ops", function()
			{
				var bus = new EventBus();
				var spy = gmtlEventBusMakeSpy();

				var unsubBadName = bus.on("", spy.bound);
				unsubBadName();

				var unsubBadFn = bus.on("a", undefined);
				unsubBadFn();

				expect(bus.emit("a", { }, 1234)).toBe(0);
				expect(spy.count).toBe(0);
			});
		});
	});
}
