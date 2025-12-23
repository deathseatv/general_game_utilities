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

			test("setKey rejects vkCode <= 0 and does not mutate binds", function()
			{
				var kb = new KeybindsManager();
				var prev = kb.getKey("pause");

				var ok = kb.setKey("pause", 0);

				expect(ok).toBeFalsy();
				expect(kb.getKey("pause")).toBe(prev);
			});

			test("fromStruct ignores vkCode <= 0 (keeps defaults)", function()
			{
				var kb = new KeybindsManager();

				var data =
				{
					pause : 0
				};

				kb.fromStruct(data);

				expect(kb.getKey("pause")).toBe(kb.defaults.pause);
			});

			test("save/load roundtrips binds (safe write)", function()
			{
				var path = "gmtl_keybinds_test.json";

				if(file_exists(path))
				{
					file_delete(path);
				}
				if(file_exists(path + ".bak"))
				{
					file_delete(path + ".bak");
				}
				if(file_exists(path + ".tmp"))
				{
					file_delete(path + ".tmp");
				}

				var kb = new KeybindsManager();
				kb.fileName = path;

				kb.setKey("recenter", vk_f1);

				var ok = kb.save();
				expect(ok).toBeTruthy();
				expect(file_exists(path)).toBeTruthy();

				var kb2 = new KeybindsManager();
				kb2.fileName = path;

				ok = kb2.load();
				expect(ok).toBeTruthy();
				expect(kb2.getKey("recenter")).toBe(vk_f1);

				kb.setKey("recenter", vk_f2);
				ok = kb.save();

				expect(ok).toBeTruthy();
				expect(file_exists(path + ".bak")).toBeTruthy();

				if(file_exists(path))
				{
					file_delete(path);
				}
				if(file_exists(path + ".bak"))
				{
					file_delete(path + ".bak");
				}
				if(file_exists(path + ".tmp"))
				{
					file_delete(path + ".tmp");
				}
			});
		});
	});
}
