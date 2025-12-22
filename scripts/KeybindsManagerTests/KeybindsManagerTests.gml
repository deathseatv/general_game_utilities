function gmtlKeybindsTests()
{
	suite(function()
	{
		section("KeybindsManager", function()
		{
			test("constructs with defaults copied into binds", function()
			{
				var kb = new KeybindsManager();

				expect(kb.binds.pause).toBe(kb.defaults.pause);
				expect(kb.binds.recenter).toBe(kb.defaults.recenter);
				expect(kb.binds.toggleFullscreen).toBe(kb.defaults.toggleFullscreen);
			});

			test("getKey returns undefined for unknown action", function()
			{
				var kb = new KeybindsManager();
				expect(kb.getKey("nope")).toBeEqual(undefined);
			});

			test("setKey swaps on conflict", function()
			{
				var kb = new KeybindsManager();

				expect(kb.binds.pause).toBe(vk_escape);
				expect(kb.binds.recenter).toBe(vk_space);

				var ok = kb.setKey("pause", vk_space);
				expect(ok).toBeTruthy();

				expect(kb.binds.pause).toBe(vk_space);
				expect(kb.binds.recenter).toBe(vk_escape);
			});

			test("toStruct/fromStruct roundtrips", function()
			{
				var kb = new KeybindsManager();
				kb.setKey("toggleFullscreen", vk_f9);

				var s = kb.toStruct();
				var kb2 = new KeybindsManager();
				kb2.fromStruct(s);

				expect(kb2.getKey("toggleFullscreen")).toBe(vk_f9);
			});
		});
	});
}
