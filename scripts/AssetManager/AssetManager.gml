function AssetManager() constructor
{
	eventBus = undefined;
	unsubs = [];
	isWired = false;

	strict = false;

	cache = {};
	cache[$ "sprite"] = {};
	cache[$ "sound"] = {};
	cache[$ "font"] = {};
	cache[$ "object"] = {};
	cache[$ "room"] = {};
	cache[$ "shader"] = {};
	cache[$ "script"] = {};
	cache[$ "sequence"] = {};
	cache[$ "path"] = {};
	cache[$ "timeline"] = {};

	tags = {};
	dynamicSprites = [];
	dynamicSounds = [];

	ev = function(key, fallback)
	{
		if(variable_global_exists("eventNames") && is_struct(global.eventNames) && variable_struct_exists(global.eventNames, key))
		{
			return global.eventNames[$ key];
		}
		return fallback;
	};

	_isCallable = function(v)
	{
		return is_callable(v);
	};

	_callUnsub = function(u)
	{
		if(_isCallable(u))
		{
			u();
		}
	};

	_errMissing = function(kind, name)
	{
		if(strict)
		{
			show_error("AssetManager missing " + string(kind) + ": " + string(name), true);
		}
	};

	_kindMap = function(kind)
	{
		if(!variable_struct_exists(cache, kind))
		{
			cache[$ kind] = {};
		}
		return cache[$ kind];
	};

	_cacheSet = function(kind, name, index)
	{
		var m = _kindMap(kind);
		m[$ name] = index;
	};

	_cacheGet = function(kind, name)
	{
		var m = _kindMap(kind);
		if(variable_struct_exists(m, name))
		{
			return m[$ name];
		}
		return -2;
	};

	_findIndex = function(name)
	{
		if(is_undefined(name) || name == "")
		{
			return -1;
		}
		return asset_get_index(name);
	};

	get = function(kind, name, fallbackName)
	{
		var cached = _cacheGet(kind, name);
		if(cached != -2)
		{
			if(cached == -1)
			{
				if(!is_undefined(fallbackName) && fallbackName != "")
				{
					return get(kind, fallbackName, undefined);
				}
				_errMissing(kind, name);
			}
			return cached;
		}

		var idx = _findIndex(name);
		_cacheSet(kind, name, idx);

		if(idx == -1)
		{
			if(!is_undefined(fallbackName) && fallbackName != "")
			{
				return get(kind, fallbackName, undefined);
			}
			_errMissing(kind, name);
		}

		return idx;
	};

	getSprite = function(name, fallbackName)
	{
		return get("sprite", name, fallbackName);
	};

	getSound = function(name, fallbackName)
	{
		return get("sound", name, fallbackName);
	};

	getFont = function(name, fallbackName)
	{
		return get("font", name, fallbackName);
	};

	exists = function(kind, name)
	{
		return get(kind, name, undefined) != -1;
	};

	register = function(kind, name, index)
	{
		if(is_undefined(name) || name == "")
		{
			return;
		}
		_cacheSet(kind, name, index);
	};

	clearCache = function()
	{
		var kinds = variable_struct_get_names(cache);
		var kCount = array_length(kinds);

		for(var i = 0; i < kCount; i += 1)
		{
			cache[$ kinds[i]] = {};
		}
	};

	tag = function(tagName, kind, name)
	{
		if(is_undefined(tagName) || tagName == "")
		{
			return;
		}

		if(!variable_struct_exists(tags, tagName))
		{
			tags[$ tagName] = [];
		}

		var list = tags[$ tagName];
		array_push(list, { kind : kind, name : name });
		tags[$ tagName] = list;
	};

	getTagged = function(tagName)
	{
		if(!variable_struct_exists(tags, tagName))
		{
			return [];
		}
		return tags[$ tagName];
	};

	warmup = function(list)
	{
		if(is_undefined(list) || !is_array(list))
		{
			return;
		}

		var n = array_length(list);

		for(var i = 0; i < n; i += 1)
		{
			var item = list[i];

			if(is_string(item))
			{
				_findIndex(item);
				continue;
			}

			if(is_struct(item))
			{
				var kind = (variable_struct_exists(item, "kind")) ? item.kind : "sprite";
				var name = (variable_struct_exists(item, "name")) ? item.name : "";
				var fallbackName = (variable_struct_exists(item, "fallback")) ? item.fallback : undefined;
				get(kind, name, fallbackName);
			}
		}
	};

	_addDynamicSprite = function(spriteIndex)
	{
		if(spriteIndex != -1)
		{
			array_push(dynamicSprites, spriteIndex);
		}
		return spriteIndex;
	};

	_addDynamicSound = function(soundIndex)
	{
		if(soundIndex != -1)
		{
			array_push(dynamicSounds, soundIndex);
		}
		return soundIndex;
	};

	addSpriteFromFile = function(filePath, imgCount, removeBack, smooth, xorig, yorig)
	{
		if(is_undefined(imgCount)) imgCount = 1;
		if(is_undefined(removeBack)) removeBack = false;
		if(is_undefined(smooth)) smooth = true;
		if(is_undefined(xorig)) xorig = 0;
		if(is_undefined(yorig)) yorig = 0;

		var spr = sprite_add(filePath, imgCount, removeBack, smooth, xorig, yorig);
		return _addDynamicSprite(spr);
	};

	addSoundFromFile = function(filePath, kind, preload)
	{
		if(is_undefined(kind)) kind = 0;
		if(is_undefined(preload)) preload = false;

		var snd = -1;

		if(function_exists("audio_sound_add"))
		{
			snd = audio_sound_add(filePath, kind, preload);
		}
		else if(function_exists("audio_add"))
		{
			snd = audio_add(filePath, kind, preload);
		}

		return _addDynamicSound(snd);
	};

	_unloadDynamicSprites = function()
	{
		var n = array_length(dynamicSprites);

		for(var i = n - 1; i >= 0; i -= 1)
		{
			var spr = dynamicSprites[i];

			if(sprite_exists(spr))
			{
				sprite_delete(spr);
			}
		}

		dynamicSprites = [];
	};


	_unloadDynamicSounds = function()
	{
		var n = array_length(dynamicSounds);

		for(var i = n - 1; i >= 0; i -= 1)
		{
			var snd = dynamicSounds[i];

			// Different runtimes expose different delete fns; try both safely.
			// If neither exists in your runtime, comment these out and manage sound ids manually.
			if(audio_sound_exists(snd))
			{
				// 2023+ name
				if(is_undefined(audio_sound_delete))
				{
					// fallback older name
					audio_delete_sound(snd);
				}
				else
				{
					audio_sound_delete(snd);
				}
			}
		}

		dynamicSounds = [];
	};


	unloadDynamic = function()
	{
		_unloadDynamicSprites();
		_unloadDynamicSounds();
	};

	clearWiring = function()
	{
		var n = array_length(unsubs);
		for(var i = 0; i < n; i += 1)
		{
			_callUnsub(unsubs[i]);
		}
		unsubs = [];
		isWired = false;
	};

	wire = function()
	{
		clearWiring();

		if(!is_struct(eventBus))
		{
			return;
		}

		var on = function(name, fn)
		{
			var u = eventBus.on(name, fn);
			if(_isCallable(u))
			{
				array_push(unsubs, u);
			}
		};

		on(ev("assetsClearCache", "assets/clearCache"), function()
		{
			clearCache();
		});

		on(ev("assetsWarmup", "assets/warmup"), function(payload)
		{
			warmup(payload);
		});

		on(ev("assetsUnloadDynamic", "assets/unloadDynamic"), function()
		{
			unloadDynamic();
		});

		on(ev("assetsRegister", "assets/register"), function(payload)
		{
			if(is_struct(payload))
			{
				var kind = (variable_struct_exists(payload, "kind")) ? payload.kind : "sprite";
				var name = (variable_struct_exists(payload, "name")) ? payload.name : "";
				var index = (variable_struct_exists(payload, "index")) ? payload.index : -1;
				register(kind, name, index);
			}
		});

		isWired = true;
	};

	init = function(bus)
	{
		eventBus = bus;
		wire();
		return self;
	};

	destroy = function()
	{
		unloadDynamic();
		clearWiring();
		clearCache();

		tags = {};
		eventBus = undefined;
	};
}
