function gmtlGuiManagerMakeWidgetStub(widgetName, callLogRef)
{
	var widgetRef =
	{
		name : widgetName,
		callLogRef : callLogRef,

		layer : 0,

		initCalls : 0,
		lastGuiRef : undefined,
		lastBusRef : undefined,

		updateCalls : 0,
		drawCalls : 0,
		destroyCalls : 0,

		resizeCalls : 0,
		lastResizeW : -1,
		lastResizeH : -1,

		dirtyCalls : 0
	};

	widgetRef.init = method(widgetRef, function(guiRef, busRef)
	{
		self.initCalls += 1;
		self.lastGuiRef = guiRef;
		self.lastBusRef = busRef;

		var n = array_length(self.callLogRef.entries);
		self.callLogRef.entries[n] = "init:" + self.name;
	});

	widgetRef.update = method(widgetRef, function()
	{
		self.updateCalls += 1;

		var n = array_length(self.callLogRef.entries);
		self.callLogRef.entries[n] = "update:" + self.name;
	});

	widgetRef.drawGui = method(widgetRef, function()
	{
		self.drawCalls += 1;

		var n = array_length(self.callLogRef.entries);
		self.callLogRef.entries[n] = "draw:" + self.name;
	});

	widgetRef.destroy = method(widgetRef, function()
	{
		self.destroyCalls += 1;

		var n = array_length(self.callLogRef.entries);
		self.callLogRef.entries[n] = "destroy:" + self.name;
	});

	widgetRef.onGuiResize = method(widgetRef, function(newGuiW, newGuiH)
	{
		self.resizeCalls += 1;
		self.lastResizeW = newGuiW;
		self.lastResizeH = newGuiH;

		var n = array_length(self.callLogRef.entries);
		self.callLogRef.entries[n] = "resize:" + self.name;
	});

	widgetRef.markDirty = method(widgetRef, function()
	{
		self.dirtyCalls += 1;

		var n = array_length(self.callLogRef.entries);
		self.callLogRef.entries[n] = "dirty:" + self.name;
	});

	return widgetRef;
}

function gmtlGuiManagerTests()
{
	suite(function()
	{
		section("GuiManager", function()
		{
			test("init stores events ref", function()
			{
				var busRef = { token : "bus" };
				var gui = new GuiManager();

				gui.init(busRef);

				expect(gui.events).toBe(busRef);
			});

			test("addWidget calls widget.init(gui, events) and stores layer", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetA = gmtlGuiManagerMakeWidgetStub("a", callLogRef);

				var ok = gui.addWidget("widgetA", widgetA, 12);

				expect(ok).toBeTruthy();
				expect(widgetA.layer).toBe(12);
				expect(widgetA.initCalls).toBe(1);
				expect(widgetA.lastGuiRef).toBe(gui);
				expect(widgetA.lastBusRef).toBe(busRef);
				expect(callLogRef.entries[0]).toBe("init:a");
			});

			test("addWidget rejects invalid key or non-struct widget", function()
			{
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				expect(gui.addWidget("", {}, 0)).toBeFalsy();
				expect(gui.addWidget("ok", undefined, 0)).toBeFalsy();
				expect(gui.addWidget("ok2", 5, 0)).toBeFalsy();
			});

			test("addWidget replaces existing key (calls destroy on old)", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetA = gmtlGuiManagerMakeWidgetStub("a", callLogRef);
				var widgetB = gmtlGuiManagerMakeWidgetStub("b", callLogRef);

				expect(gui.addWidget("sameKey", widgetA, 0)).toBeTruthy();
				expect(gui.addWidget("sameKey", widgetB, 0)).toBeTruthy();

				expect(widgetA.destroyCalls).toBe(1);
				expect(gui.getWidget("sameKey")).toBe(widgetB);

				expect(callLogRef.entries[0]).toBe("init:a");
				expect(callLogRef.entries[1]).toBe("destroy:a");
				expect(callLogRef.entries[2]).toBe("init:b");
			});

			test("removeWidget calls destroy and removes", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetA = gmtlGuiManagerMakeWidgetStub("a", callLogRef);

				gui.addWidget("widgetA", widgetA, 0);

				expect(gui.removeWidget("widgetA")).toBeTruthy();
				expect(widgetA.destroyCalls).toBe(1);
				expect(is_undefined(gui.getWidget("widgetA"))).toBeTruthy();

				expect(gui.removeWidget("widgetA")).toBeFalsy();
			});

			test("drawGui runs in ascending layer order", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetLow = gmtlGuiManagerMakeWidgetStub("low", callLogRef);
				var widgetHigh = gmtlGuiManagerMakeWidgetStub("high", callLogRef);

				gui.addWidget("lowKey", widgetLow, 10);
				gui.addWidget("highKey", widgetHigh, 20);

				callLogRef.entries = [];
				gui.drawGui();

				expect(callLogRef.entries[0]).toBe("draw:low");
				expect(callLogRef.entries[1]).toBe("draw:high");
			});

			test("update runs widget.update in ascending layer order", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetLow = gmtlGuiManagerMakeWidgetStub("low", callLogRef);
				var widgetHigh = gmtlGuiManagerMakeWidgetStub("high", callLogRef);

				gui.addWidget("lowKey", widgetLow, 10);
				gui.addWidget("highKey", widgetHigh, 20);

				gui.guiW = display_get_gui_width();
				gui.guiH = display_get_gui_height();

				callLogRef.entries = [];
				gui.update();

				expect(callLogRef.entries[0]).toBe("update:low");
				expect(callLogRef.entries[1]).toBe("update:high");
			});

			test("update detects gui resize and notifies widgets (onGuiResize + markDirty)", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetA = gmtlGuiManagerMakeWidgetStub("a", callLogRef);
				gui.addWidget("widgetA", widgetA, 0);

				var curW = display_get_gui_width();
				var curH = display_get_gui_height();

				gui.guiW = curW + 1;
				gui.guiH = curH + 1;

				callLogRef.entries = [];
				gui.update();

				expect(widgetA.resizeCalls).toBe(1);
				expect(widgetA.lastResizeW).toBe(curW);
				expect(widgetA.lastResizeH).toBe(curH);
				expect(widgetA.dirtyCalls).toBe(1);

				expect(callLogRef.entries[0]).toBe("resize:a");
				expect(callLogRef.entries[1]).toBe("dirty:a");
				expect(callLogRef.entries[2]).toBe("update:a");
			});

			test("destroy destroys all widgets and clears", function()
			{
				var callLogRef = { entries : [] };
				var busRef = { token : "bus" };
				var gui = new GuiManager();
				gui.init(busRef);

				var widgetA = gmtlGuiManagerMakeWidgetStub("a", callLogRef);
				var widgetB = gmtlGuiManagerMakeWidgetStub("b", callLogRef);

				gui.addWidget("widgetA", widgetA, 0);
				gui.addWidget("widgetB", widgetB, 0);

				callLogRef.entries = [];
				gui.destroy();

				expect(widgetA.destroyCalls).toBe(1);
				expect(widgetB.destroyCalls).toBe(1);

				expect(array_length(gui.widgetOrder)).toBe(0);
				expect(array_length(variable_struct_get_names(gui.widgets))).toBe(0);
			});
		});
	});
}
