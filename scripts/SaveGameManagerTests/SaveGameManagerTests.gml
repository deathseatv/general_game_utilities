function gmtlSaveGameMakeSpy()
{
	var spy =
	{
		emits : [],

		run : function(payload, eventName, sender)
		{
			var n = array_length(self.emits);
			self.emits[n] = { eventName : eventName, payload : payload, sender : sender };
		}
	};

	spy.bound = method(spy, spy.run);
	return spy;
}

function gmtlSaveGameMakeProvider(initialValue)
{
	return
	{
		value : initialValue,

		save : function()
		{
			return { value : self.value };
		},

		load : function(data)
		{
			if(is_struct(data) && variable_struct_exists(data, "value"))
			{
				self.value = data.value;
			}
		}
	};
}


function gmtlSaveGameMakePrefix()
{
	return "gmtl_save_" + string(get_timer()) + "_" + string(irandom(1000000)) + "_";
}

function gmtlSaveGameCleanup(prefix, slot)
{
	var path = string(prefix) + string(slot) + ".json";
	var tmp = path + ".tmp";

	if(file_exists(tmp))
	{
		file_delete(tmp);
	}

	if(file_exists(path))
	{
		file_delete(path);
	}
}

function gmtlSaveGameTests()
{
	suite(function()
	{
		section("SaveGameManager", function()
		{
			test("save writes file and load restores provider data", function()
			{
				var prefix = gmtlSaveGameMakePrefix();
				var slot = 1;
				gmtlSaveGameCleanup(prefix, slot);

				var p = gmtlSaveGameMakeProvider(7);

				var sm = new SaveGameManager();
				sm.setFilePrefix(prefix);
				sm.registerProvider("p", p);

				var ok = sm.save(slot);
				expect(ok).toBeTruthy();
				expect(file_exists(prefix + string(slot) + ".json")).toBeTruthy();
				expect(file_exists(prefix + string(slot) + ".json.tmp")).toBeFalsy();

				p.value = 0;

				ok = sm.load(slot);
				expect(ok).toBeTruthy();
				expect(p.value).toBe(7);

				gmtlSaveGameCleanup(prefix, slot);
			});

			test("deleteSave removes save file", function()
			{
				var prefix = gmtlSaveGameMakePrefix();
				var slot = 9992;
				gmtlSaveGameCleanup(prefix, slot);

				var p = gmtlSaveGameMakeProvider(3);

				var sm = new SaveGameManager();
				sm.setFilePrefix(prefix);
				sm.registerProvider("p", p);

				sm.save(slot);
				expect(file_exists(prefix + string(slot) + ".json")).toBeTruthy();

				var ok = sm.deleteSave(slot);
				expect(ok).toBeTruthy();
				expect(file_exists(prefix + string(slot) + ".json")).toBeFalsy();

				gmtlSaveGameCleanup(prefix, slot);
			});

			test("load migrates when migration registered", function()
			{
				var prefix = gmtlSaveGameMakePrefix();
				var slot = 9993;
				gmtlSaveGameCleanup(prefix, slot);

				var p1 = gmtlSaveGameMakeProvider(10);

				var sm1 = new SaveGameManager();
				sm1.setFilePrefix(prefix);
				sm1.saveVersion = 1;
				sm1.registerProvider("p", p1);
				sm1.save(slot);

				var p2 = gmtlSaveGameMakeProvider(0);

				var sm2 = new SaveGameManager();
				sm2.setFilePrefix(prefix);
				sm2.saveVersion = 2;
				sm2.registerProvider("p", p2);

				sm2.registerMigration(1, function(root)
				{
					if(is_struct(root)
						&& variable_struct_exists(root, "data")
						&& is_struct(root.data)
						&& variable_struct_exists(root.data, "p")
						&& is_struct(root.data.p)
						&& variable_struct_exists(root.data.p, "value"))
					{
						root.data.p.value += 5;
					}

					return root;
				});

				var ok = sm2.load(slot);
				expect(ok).toBeTruthy();
				expect(p2.value).toBe(15);

				gmtlSaveGameCleanup(prefix, slot);
			});

			test("bus save/load events call methods and emit saved/loaded", function()
			{
				var prefix = gmtlSaveGameMakePrefix();
				var slot = 9994;
				gmtlSaveGameCleanup(prefix, slot);

				var bus = new EventBus();

				var savedSpy = gmtlSaveGameMakeSpy();
				var loadedSpy = gmtlSaveGameMakeSpy();

				bus.on("saveGame/saved", savedSpy.bound);
				bus.on("saveGame/loaded", loadedSpy.bound);

				var p = gmtlSaveGameMakeProvider(2);

				var sm = new SaveGameManager();
				sm.setFilePrefix(prefix);
				sm.registerProvider("p", p);
				sm.init(bus);

				bus.emit("saveGame/save", { slot : slot }, noone);

				expect(array_length(savedSpy.emits)).toBe(1);
				expect(savedSpy.emits[0].payload.slot).toBe(slot);

				p.value = 0;

				bus.emit("saveGame/load", { slot : slot }, noone);

				expect(array_length(loadedSpy.emits)).toBe(1);
				expect(loadedSpy.emits[0].payload.slot).toBe(slot);
				expect(p.value).toBe(2);

				gmtlSaveGameCleanup(prefix, slot);
			});
		});
	});
}
