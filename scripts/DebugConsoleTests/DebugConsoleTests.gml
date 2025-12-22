function gmtlDebugConsoleTests()
{
	suite(function()
	{
		section("DebugConsole", function()
		{
			test("constructs with defaults", function()
			{
				var c = new DebugConsole();

				expect(c.isOpen).toBe(false);
				expect(c.pauseWhenOpen).toBe(true);
				expect(c.openKey).toBe(192);

				expect(c.maxLines).toBe(200);
				expect(array_length(c.lines)).toBe(0);

				expect(is_struct(c.commands)).toBe(true);
			});

			test("open sets isOpen, clears keyboard_string, logs open line", function()
			{
				var c = new DebugConsole();

				var kb = keyboard_string;
				keyboard_string = "abc";

				c.open();

				expect(c.isOpen).toBe(true);
				expect(keyboard_string).toBe("");

				expect(array_length(c.lines)).toBe(1);
				expect(c.lines[0]).toBe("Console opened. Type 'help'.");

				keyboard_string = kb;
			});

			test("close clears keyboard_string and closes", function()
			{
				var c = new DebugConsole();

				var kb = keyboard_string;
				keyboard_string = "abc";

				c.open();
				c.close();

				expect(c.isOpen).toBe(false);
				expect(keyboard_string).toBe("");

				keyboard_string = kb;
			});

			test("toggle refuses when canOpen is false (forces closed)", function()
			{
				var c = new DebugConsole();

				c.open();
				expect(c.isOpen).toBe(true);

				var before = array_length(c.lines);
				c.toggle(false);

				expect(c.isOpen).toBe(false);
				expect(array_length(c.lines)).toBe(before);
			});

			test("toggle opens when allowed, closes when already open", function()
			{
				var c = new DebugConsole();

				c.toggle(true);
				expect(c.isOpen).toBe(true);

				c.toggle(true);
				expect(c.isOpen).toBe(false);
			});

			test("log appends lines and trims to maxLines", function()
			{
				var c = new DebugConsole();
				c.maxLines = 3;

				c.log("a");
				c.log("b");
				c.log("c");
				c.log("d");

				expect(array_length(c.lines)).toBe(3);
				expect(c.lines[0]).toBe("b");
				expect(c.lines[1]).toBe("c");
				expect(c.lines[2]).toBe("d");
			});

			test("registerCommand stores entry and can be executed", function()
			{
				var c = new DebugConsole();

				var spy =
				{
					called : 0
				};

				var fn = method(spy, function(args, line)
				{
					self.called += 1;
				});

				c.registerCommand("PING", "ping", fn);

				expect(variable_struct_exists(c.commands, "ping")).toBe(true);

				var entry = variable_struct_get(c.commands, "ping");
				expect(entry.usage).toBe("ping");

				c.execLine("ping");
				expect(spy.called).toBe(1);
			});

			test("execLine ignores blank/whitespace", function()
			{
				var c = new DebugConsole();

				c.log("seed");
				var before = array_length(c.lines);

				c.execLine("   ");

				expect(array_length(c.lines)).toBe(before);
			});

			test("execLine logs unknown command", function()
			{
				var c = new DebugConsole();

				c.execLine("nope");

				var n = array_length(c.lines);
				expect(n >= 2).toBe(true);
				expect(c.lines[n - 2]).toBe("> nope");
				expect(c.lines[n - 1]).toBe("Unknown command: nope");
			});

			test("execLine lowercases command name and passes args + raw line", function()
			{
				var c = new DebugConsole();

				var spy =
				{
					args : undefined,
					line : ""
				};

				var fn = method(spy, function(args, line)
				{
					self.args = args;
					self.line = line;
				});

				c.registerCommand("add", "add a b", fn);

				c.execLine("AdD 2 3");

				expect(is_array(spy.args)).toBe(true);
				expect(array_length(spy.args)).toBe(2);
				expect(spy.args[0]).toBe("2");
				expect(spy.args[1]).toBe("3");
				expect(spy.line).toBe("AdD 2 3");
			});

			test("update closes console if canOpen becomes false", function()
			{
				var c = new DebugConsole();

				c.open();
				expect(c.isOpen).toBe(true);

				c.update(false);

				expect(c.isOpen).toBe(false);
			});

			test("drawGui does not crash when closed or open", function()
			{
				var c = new DebugConsole();

				c.drawGui(0, 0, 320, 180);
				expect(true).toBe(true);

				c.open();
				c.drawGui(0, 0, 320, 180);
				expect(true).toBe(true);
			});
		});
	});
}