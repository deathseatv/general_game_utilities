function makeFlowPauseHarness()
{
	var h =
	{
		bus : new EventBus(),

		input : new InputManager(),
		gameState : new GameStateManager(),
		menus : new MenuManager(),
		flow : new FlowManager(),
		keybinds : new KeybindsManager(),

		init : function()
		{
			if(variable_struct_exists(self.menus, "setKeybinds") && is_callable(self.menus.setKeybinds))
			{
				self.menus.setKeybinds(self.keybinds);
			}

			initInputInSystems(self.input, self.bus, self.keybinds);

			self.gameState.init(self.bus);
			self.gameState.setState(self.gameState.states.playing);

			self.menus.init(self.bus);
			self.menus.close();

			self.flow.init(self.bus,
			{
				mode : "events",
				menus : self.menus,
				gameState : self.gameState,
				input : self.input
			});

			self.flow.wire();
		},

		pressEscapeFrame : function()
		{
			simulateKeyPress(vk_escape);

			var splitInput = is_struct(self.input)
				&& variable_struct_exists(self.input, "beginFrame")
				&& is_callable(self.input.beginFrame)
				&& variable_struct_exists(self.input, "dispatchEvents")
				&& is_callable(self.input.dispatchEvents);

			if(splitInput)
			{
				if(variable_struct_exists(self.input, "clearConsumed") && is_callable(self.input.clearConsumed))
				{
					self.input.clearConsumed();
				}

				self.input.beginFrame();
				self.input.dispatchEvents();
			}
			else
			{
				self.input.update();
			}

			keyboard_clear(vk_escape);
		}
	};

	h.init();
	return h;
}


function gmtlFlowPauseTests()
{
	var makeFlowPauseHarness = function()
	{
		var h =
		{
			bus : new EventBus(),

			input : new InputManager(),
			gameState : new GameStateManager(),
			menus : new MenuManager(),
			flow : new FlowManager(),
			keybinds : new KeybindsManager(),

			prevGlobalInput : undefined,
			prevGlobalKeybinds : undefined,

			init : function()
			{
				self.prevGlobalInput = variable_global_exists("input") ? global.input : undefined;
				self.prevGlobalKeybinds = variable_global_exists("keybinds") ? global.keybinds : undefined;

				global.input = self.input;
				global.keybinds = self.keybinds;

				if(variable_struct_exists(self.menus, "setKeybinds") && is_callable(self.menus.setKeybinds))
				{
					self.menus.setKeybinds(self.keybinds);
				}

				initInputInSystems(self.input, self.bus, self.keybinds);

				self.gameState.init(self.bus);
				self.gameState.setState(self.gameState.states.playing);

				self.menus.init(self.bus);
				self.menus.close();

				self.flow.init(self.bus,
				{
					mode : "direct",
					menus : self.menus,
					gameState : self.gameState,
					input : self.input,
					wire : true
				});
			},

			cleanup : function()
			{
				if(is_undefined(self.prevGlobalInput))
				{
					if(variable_global_exists("input"))
					{
						variable_global_remove("input");
					}
				}
				else
				{
					global.input = self.prevGlobalInput;
				}

				if(is_undefined(self.prevGlobalKeybinds))
				{
					if(variable_global_exists("keybinds"))
					{
						variable_global_remove("keybinds");
					}
				}
				else
				{
					global.keybinds = self.prevGlobalKeybinds;
				}
			},

			pressEscapeFrame : function()
			{
				simulateKeyPress(vk_escape);

				var splitInput = is_struct(self.input)
					&& variable_struct_exists(self.input, "beginFrame")
					&& is_callable(self.input.beginFrame)
					&& variable_struct_exists(self.input, "dispatchEvents")
					&& is_callable(self.input.dispatchEvents);

				if(splitInput)
				{
					if(variable_struct_exists(self.input, "clearConsumed") && is_callable(self.input.clearConsumed))
					{
						self.input.clearConsumed();
					}

					self.input.beginFrame();
					self.menus.update();
					self.input.dispatchEvents();
				}
				else
				{
					self.input.update();
					self.menus.update();
				}

				keyboard_clear(vk_escape);
			}
		};

		h.init();
		return h;
	};

	suite(function()
	{
		section("Flow - Pause", function()
		{
			test("Esc during gameplay pauses + shows pause menu", function()
			{
				var h = makeFlowPauseHarness();

				expect(h.gameState.state).toBe(h.gameState.states.playing);
				expect(h.menus.isOpen).toBeFalsy();

				h.pressEscapeFrame();

				expect(h.gameState.state).toBe(h.gameState.states.paused);
				expect(h.menus.isOpen).toBeTruthy();
				expect(h.menus.currentMenuId).toBe("pause");

				h.cleanup();
			});

			test("Esc while paused unpauses + closes pause menu", function()
			{
				var h = makeFlowPauseHarness();

				h.pressEscapeFrame();
				expect(h.gameState.state).toBe(h.gameState.states.paused);
				expect(h.menus.isOpen).toBeTruthy();

				h.pressEscapeFrame();

				expect(h.gameState.state).toBe(h.gameState.states.playing);
				expect(h.menus.isOpen).toBeFalsy();

				h.cleanup();
			});
		});
	});
}
