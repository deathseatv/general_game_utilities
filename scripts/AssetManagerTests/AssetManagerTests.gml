function gmtlAssetManagerSnapshotGlobals(names)
{
	var snap =
	{
		names : names,
		exists : [],
		values : []
	};

	var n = array_length(names);

	for(var i = 0; i < n; i += 1)
	{
		var k = names[i];

		snap.exists[i] = variable_global_exists(k);

		if(snap.exists[i])
		{
			snap.values[i] = variable_global_get(k);
		}
		else
		{
			snap.values[i] = undefined;
		}
	}

	return snap;
}

function gmtlAssetManagerRestoreGlobals(snap)
{
	var n = array_length(snap.names);

	for(var i = 0; i < n; i += 1)
	{
		var k = snap.names[i];

		if(snap.exists[i])
		{
			variable_global_set(k, snap.values[i]);
		}
		else if(variable_global_exists(k))
		{
			variable_global_remove(k);
		}
	}
}

function gmtlAssetManagerMakeRuntimeSprite()
{
	var w = 4;
	var h = 4;

	var surf = surface_create(w, h);

	surface_set_target(surf);
	draw_clear_alpha(c_white, 1);
	surface_reset_target();

	var spr = sprite_create_from_surface(surf, 0, 0, w, h, false, false, 0, 0);

	surface_free(surf);

	return spr;
}

function gmtlAssetManagerDeleteSpriteSafe(spr)
{
	if(spr == -1)
	{
		return;
	}

	if(sprite_exists(spr))
	{
		sprite_delete(spr);
	}
}

function gmtlAssetManagerTests()
{
	suite(function()
	{
		section("AssetManager", function()
		{
			test("constructs with expected defaults", function()
			{
				var am = new AssetManager();

				expect(am.eventBus).toBe(undefined);
				expect(is_array(am.unsubs)).toBeTruthy();
				expect(array_length(am.unsubs)).toBe(0);
				expect(am.isWired).toBeFalsy();

				expect(am.strict).toBeFalsy();

				expect(is_struct(am.cache)).toBeTruthy();
				expect(is_struct(am.cache.sprite)).toBeTruthy();
				expect(is_struct(am.cache.sound)).toBeTruthy();
				expect(is_struct(am.cache.font)).toBeTruthy();
				expect(is_struct(am.cache.object)).toBeTruthy();
				expect(is_struct(am.cache.room)).toBeTruthy();
				expect(is_struct(am.cache.shader)).toBeTruthy();
				expect(is_struct(am.cache.script)).toBeTruthy();
				expect(is_struct(am.cache.sequence)).toBeTruthy();
				expect(is_struct(am.cache.path)).toBeTruthy();
				expect(is_struct(am.cache.timeline)).toBeTruthy();

				expect(is_struct(am.tags)).toBeTruthy();
				expect(is_array(am.dynamicSprites)).toBeTruthy();
				expect(is_array(am.dynamicSounds)).toBeTruthy();
			});

			test("getSprite returns -1 for missing and caches result", function()
			{
				var am = new AssetManager();

				var idx = am.getSprite("gmtl_missing_sprite_name");
				expect(idx).toBe(-1);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_missing_sprite_name")).toBeTruthy();
				expect(am.cache.sprite[$ "gmtl_missing_sprite_name"]).toBe(-1);
			});

			test("register stores mapping and get returns it", function()
			{
				var am = new AssetManager();

				var spr = gmtlAssetManagerMakeRuntimeSprite();
				expect(spr == -1).toBeFalsy();
				expect(sprite_exists(spr)).toBeTruthy();

				am.register("sprite", "gmtl_runtimeSpr", spr);

				expect(am.getSprite("gmtl_runtimeSpr")).toBe(spr);
				expect(am.exists("sprite", "gmtl_runtimeSpr")).toBeTruthy();

				gmtlAssetManagerDeleteSpriteSafe(spr);
			});

			test("clearCache clears all cached name->index mappings", function()
			{
				var am = new AssetManager();

				am.register("sprite", "gmtl_a", 111);
				am.register("sound", "gmtl_b", 222);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_a")).toBeTruthy();
				expect(variable_struct_exists(am.cache.sound, "gmtl_b")).toBeTruthy();

				am.clearCache();

				expect(variable_struct_exists(am.cache.sprite, "gmtl_a")).toBeFalsy();
				expect(variable_struct_exists(am.cache.sound, "gmtl_b")).toBeFalsy();
			});

			test("fallbackName returns fallback mapping when primary missing", function()
			{
				var am = new AssetManager();

				var spr = gmtlAssetManagerMakeRuntimeSprite();
				expect(spr == -1).toBeFalsy();

				am.register("sprite", "gmtl_fallback", spr);

				var idx = am.getSprite("gmtl_primary_missing", "gmtl_fallback");
				expect(idx).toBe(spr);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_primary_missing")).toBeTruthy();
				expect(am.cache.sprite[$ "gmtl_primary_missing"]).toBe(-1);
				expect(am.cache.sprite[$ "gmtl_fallback"]).toBe(spr);

				gmtlAssetManagerDeleteSpriteSafe(spr);
			});

			test("tag and getTagged store entries", function()
			{
				var am = new AssetManager();

				am.tag("gmtl_ui", "sprite", "spr_button");
				am.tag("gmtl_ui", "sound", "snd_click");

				var list = am.getTagged("gmtl_ui");

				expect(is_array(list)).toBeTruthy();
				expect(array_length(list)).toBe(2);

				expect(list[0].kind).toBe("sprite");
				expect(list[0].name).toBe("spr_button");

				expect(list[1].kind).toBe("sound");
				expect(list[1].name).toBe("snd_click");
			});

			test("warmup caches struct entries but does not cache raw string entries", function()
			{
				var am = new AssetManager();

				am.register("sprite", "gmtl_warm_existing", 123);

				var list =
				[
					{ kind : "sprite", name : "gmtl_warm_missing" },
					{ kind : "sprite", name : "gmtl_warm_existing" },
					"gmtl_string_only_name"
				];

				am.warmup(list);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_warm_missing")).toBeTruthy();
				expect(am.cache.sprite[$ "gmtl_warm_missing"]).toBe(-1);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_warm_existing")).toBeTruthy();
				expect(am.cache.sprite[$ "gmtl_warm_existing"]).toBe(123);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_string_only_name")).toBeFalsy();
			});

			test("unloadDynamic deletes runtime sprites listed in dynamicSprites", function()
			{
				var am = new AssetManager();

				var spr = gmtlAssetManagerMakeRuntimeSprite();
				expect(spr == -1).toBeFalsy();
				expect(sprite_exists(spr)).toBeTruthy();

				am.dynamicSprites = [ spr ];
				am.unloadDynamic();

				expect(array_length(am.dynamicSprites)).toBe(0);
				expect(sprite_exists(spr)).toBeFalsy();
			});

			test("init wires EventBus and responds to default asset events", function()
			{
				var bus = new EventBus();
				var am = new AssetManager();

				am.init(bus);

				expect(am.isWired).toBeTruthy();

				bus.emit("assets/register", { kind : "sprite", name : "gmtl_evtSpr", index : 555 });
				expect(am.getSprite("gmtl_evtSpr")).toBe(555);

				bus.emit("assets/clearCache");
				expect(variable_struct_exists(am.cache.sprite, "gmtl_evtSpr")).toBeFalsy();

				bus.emit("assets/warmup", [ { kind : "sprite", name : "gmtl_evtMissing" } ]);
				expect(variable_struct_exists(am.cache.sprite, "gmtl_evtMissing")).toBeTruthy();
				expect(am.cache.sprite[$ "gmtl_evtMissing"]).toBe(-1);

				var spr = gmtlAssetManagerMakeRuntimeSprite();
				expect(spr == -1).toBeFalsy();

				am.dynamicSprites = [ spr ];
				bus.emit("assets/unloadDynamic");

				expect(array_length(am.dynamicSprites)).toBe(0);
				expect(sprite_exists(spr)).toBeFalsy();
			});

			test("init uses global.eventNames overrides for wiring", function()
			{
				var snap = gmtlAssetManagerSnapshotGlobals([ "eventNames" ]);

				global.eventNames =
				{
					assetsClearCache : "am/clear",
					assetsWarmup : "am/warm",
					assetsUnloadDynamic : "am/unload",
					assetsRegister : "am/reg"
				};

				var bus = new EventBus();
				var am = new AssetManager();

				am.init(bus);

				bus.emit("am/reg", { kind : "sprite", name : "gmtl_customEvtSpr", index : 777 });
				expect(am.getSprite("gmtl_customEvtSpr")).toBe(777);

				bus.emit("am/clear");
				expect(variable_struct_exists(am.cache.sprite, "gmtl_customEvtSpr")).toBeFalsy();

				bus.emit("am/warm", [ { kind : "sprite", name : "gmtl_customMissing" } ]);
				expect(variable_struct_exists(am.cache.sprite, "gmtl_customMissing")).toBeTruthy();
				expect(am.cache.sprite[$ "gmtl_customMissing"]).toBe(-1);

				var spr = gmtlAssetManagerMakeRuntimeSprite();
				expect(spr == -1).toBeFalsy();

				am.dynamicSprites = [ spr ];
				bus.emit("am/unload");

				expect(array_length(am.dynamicSprites)).toBe(0);
				expect(sprite_exists(spr)).toBeFalsy();

				gmtlAssetManagerRestoreGlobals(snap);
			});

			test("destroy clears wiring, clears cache, resets tags, and drops eventBus", function()
			{
				var bus = new EventBus();
				var am = new AssetManager();

				var spr = gmtlAssetManagerMakeRuntimeSprite();
				expect(spr == -1).toBeFalsy();

				am.init(bus);
				am.register("sprite", "gmtl_destroySpr", 999);
				am.tag("gmtl_destroyTag", "sprite", "gmtl_destroySpr");
				am.dynamicSprites = [ spr ];

				am.destroy();

				expect(am.isWired).toBeFalsy();
				expect(am.eventBus).toBe(undefined);

				expect(variable_struct_exists(am.cache.sprite, "gmtl_destroySpr")).toBeFalsy();
				expect(variable_struct_exists(am.tags, "gmtl_destroyTag")).toBeFalsy();

				expect(array_length(am.dynamicSprites)).toBe(0);
				expect(sprite_exists(spr)).toBeFalsy();
			});
		});
	});
}
