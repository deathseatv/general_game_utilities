function gmtlMenuManagerMakeSpy()
{
	var spy =
	{
		count : 0,
		lastPayload : undefined,
		lastEventName : "",
		lastSender : noone,

		handle : function(payload, eventName, sender)
		{
			count += 1;
			lastPayload = payload;
			lastEventName = eventName;
			lastSender = sender;
		}
	};

	spy.bound = method(spy, spy.handle);
	return spy;
}

function gmtlMenuManagerMakeRangeToken(startValue)
{
	var token =
	{
		value : startValue,

		get : function()
		{
			return self.value;
		},

		set : function(v)
		{
			self.value = v;
		}
	};

	token.getBound = method(token, token.get);
	token.setBound = method(token, token.set);

	return token;
}

function gmtlMenuManagerMakeActionToken()
{
	var token =
	{
		calls : 0,

		run : function()
		{
			self.calls += 1;
		}
	};

	token.bound = method(token, token.run);
	return token;
}

function gmtlMenuManagerTests()
{
	suite(function()
	{
		section("MenuManager", function()
		{
			test("constructs with default menus registered", function()
			{
				var mm = new MenuManager();

				expect(variable_struct_exists(mm.menus, "intro")).toBeTruthy();
				expect(variable_struct_exists(mm.menus, "main")).toBeTruthy();
				expect(variable_struct_exists(mm.menus, "options")).toBeTruthy();
				expect(variable_struct_exists(mm.menus, "volume")).toBeTruthy();
				expect(variable_struct_exists(mm.menus, "keybinds")).toBeTruthy();
				expect(variable_struct_exists(mm.menus, "pause")).toBeTruthy();
				expect(variable_struct_exists(mm.menus, "loading")).toBeTruthy();

				expect(mm.isOpen).toBeFalsy();
				expect(mm.currentMenuId).toBe("");
			});

			test("show(menuId) opens and resets selection/stack", function()
			{
				var mm = new MenuManager();

				mm.show("main");
				mm.push("options");

				expect(mm.currentMenuId).toBe("options");
				expect(array_length(mm.menuStack)).toBe(1);

				mm.show("main");

				expect(mm.isOpen).toBeTruthy();
				expect(mm.currentMenuId).toBe("main");
				expect(array_length(mm.menuStack)).toBe(0);
				expect(mm.selectedIndex).toBe(0);
				expect(mm.hoverIndex).toBe(-1);
			});

			test("push/pop navigates menus using a stack", function()
			{
				var mm = new MenuManager();

				mm.addMenu("a", "A", { background : true, backAction : "close" });
				mm.addMenu("b", "B", { background : true, backAction : "pop" });
				mm.addMenu("c", "C", { background : true, backAction : "pop" });

				mm.show("a");
				mm.push("b");
				mm.push("c");

				expect(mm.currentMenuId).toBe("c");
				expect(array_length(mm.menuStack)).toBe(2);

				mm.pop();
				expect(mm.currentMenuId).toBe("b");
				expect(array_length(mm.menuStack)).toBe(1);

				mm.pop();
				expect(mm.currentMenuId).toBe("a");
				expect(array_length(mm.menuStack)).toBe(0);
			});

			test("addMenu + addActionItem allows extending menus easily", function()
			{
				var mm = new MenuManager();
				var action = gmtlMenuManagerMakeActionToken();

				mm.addMenu("testMenu", "TEST", { background : true, backAction : "close" });
				mm.addActionItem("testMenu", "Do Thing", action.bound);

				mm.show("testMenu");
				mm.selectedIndex = 0;
				mm.activateSelection();

				expect(action.calls).toBe(1);
			});

			test("disabled action item does not activate", function()
			{
				var mm = new MenuManager();
				var action = gmtlMenuManagerMakeActionToken();

				mm.addMenu("testMenu", "TEST", { background : true, backAction : "close" });
				mm.addActionItem("testMenu", "Do Thing", action.bound, { enabled : false });

				mm.show("testMenu");
				mm.selectedIndex = 0;
				mm.activateSelection();

				expect(action.calls).toBe(0);
			});

			test("range item adjusts and clamps", function()
			{
				var mm = new MenuManager();
				var tok = gmtlMenuManagerMakeRangeToken(0.5);

				mm.addMenu("rangeMenu", "RANGE", { background : true, backAction : "close" });
				mm.addRangeItem("rangeMenu", "Value", tok.getBound, tok.setBound, { step : 0.25, min : 0.0, max : 1.0 });

				mm.show("rangeMenu");
				mm.selectedIndex = 0;

				mm.adjustSelection(1);
				expect(tok.value).toBe(0.75);

				mm.adjustSelection(1);
				expect(tok.value).toBe(1.0);

				mm.adjustSelection(1);
				expect(tok.value).toBe(1.0);

				mm.adjustSelection(-1);
				expect(tok.value).toBe(0.75);

				mm.adjustSelection(-10);
				expect(tok.value).toBe(0.0);
			});

			test("back() respects backAction close", function()
			{
				var mm = new MenuManager();

				mm.show("main");
				expect(mm.isOpen).toBeTruthy();

				mm.back();

				expect(mm.isOpen).toBeFalsy();
				expect(mm.currentMenuId).toBe("");
			});

			test("back() respects backAction pop", function()
			{
				var mm = new MenuManager();

				mm.show("main");
				mm.push("options");

				expect(mm.currentMenuId).toBe("options");
				expect(array_length(mm.menuStack)).toBe(1);

				mm.back();

				expect(mm.currentMenuId).toBe("main");
				expect(array_length(mm.menuStack)).toBe(0);
			});

			test("back() respects backAction main", function()
			{
				var mm = new MenuManager();

				mm.addMenu("credits", "CREDITS", { background : true, backAction : "main" });
				mm.show("credits");

				mm.back();

				expect(mm.currentMenuId).toBe("main");
				expect(mm.isOpen).toBeTruthy();
			});

			test("init subscribes to EventBus and reacts to menu events", function()
			{
				var bus = new EventBus();
				var mm = new MenuManager();

				mm.init(bus);

				bus.emit("menu/show", { menuId : "main" }, noone);
				expect(mm.currentMenuId).toBe("main");

				bus.emit("menu/show", { menuId : "pause" }, noone);
				expect(mm.currentMenuId).toBe("pause");

				bus.emit("menu/close", { }, noone);
				expect(mm.isOpen).toBeFalsy();
			});

			test("getKeyForAction falls back when keybind is invalid (0)", function()
			{
				var mm = new MenuManager();

				mm.keybinds =
				{
					getKey : function(actionName)
					{
						return 0;
					}
				};

				var vk = mm.getKeyForAction("pause", vk_escape);

				expect(vk).toBe(vk_escape);
			});
		});
	});
}
