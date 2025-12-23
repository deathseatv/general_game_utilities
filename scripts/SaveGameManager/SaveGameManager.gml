function SaveGameManager() constructor
{
	eventBus = undefined;

	saveVersion = 1;
	activeSlot = 1;

	filePrefix = "save_slot_";
	fileExt = ".json";
	tempExt = ".tmp";

	providers = {};
	migrations = {};

	lastError = "";

	clearError = function()
	{
		lastError = "";
	};

	setError = function(msg)
	{
		lastError = string(msg);
	};

	setActiveSlot = function(slot)
	{
		if(!is_real(slot))
		{
			return false;
		}

		activeSlot = max(0, floor(slot));
		return true;
	};

	setFilePrefix = function(prefix)
	{
		if(is_undefined(prefix))
		{
			return false;
		}

		filePrefix = string(prefix);
		return true;
	};

	makeFileName = function(slot)
	{
		var s = is_real(slot) ? floor(slot) : activeSlot;
		s = max(0, s);

		return filePrefix + string(s) + fileExt;
	};

	makeTempFileName = function(slot)
	{
		return makeFileName(slot) + tempExt;
	};

	registerProvider = function(_id, provider)
	{
		if(is_undefined(_id) || _id == "")
		{
			return false;
		}

		if(!is_struct(provider))
		{
			return false;
		}

		if(!variable_struct_exists(provider, "save") || !is_callable(provider.save))
		{
			return false;
		}

		providers[$ string(_id)] = provider;
		return true;
	};

	unregisterProvider = function(_id)
	{
		if(is_undefined(_id) || _id == "")
		{
			return false;
		}

		if(variable_struct_exists(providers, _id))
		{
			variable_struct_remove(providers, _id);
			return true;
		}

		return false;
	};

	registerMigration = function(fromVersion, migrateFn)
	{
		if(!is_real(fromVersion))
		{
			return false;
		}

		if(!is_callable(migrateFn))
		{
			return false;
		}

		var v = floor(fromVersion);
		if(v < 0)
		{
			return false;
		}

		migrations[$ string(v)] = migrateFn;
		return true;
	};

	buildSaveStruct = function()
	{
		var data = {};

		var ids = variable_struct_get_names(providers);
		var n = array_length(ids);

		for(var i = 0; i < n; i += 1)
		{
			var _id = ids[i];
			var p = providers[$ _id];

			if(!is_struct(p) || !is_callable(p.save))
			{
				continue;
			}

			var part = p.save();

			if(!is_undefined(part))
			{
				data[$ _id] = part;
			}
		}

		return
		{
			version : saveVersion,
			timestamp : date_current_datetime(),
			data : data
		};
	};

	migrateToCurrent = function(saveStruct)
	{
		if(!is_struct(saveStruct))
		{
			setError("Invalid save root");
			return undefined;
		}

		if(!variable_struct_exists(saveStruct, "version") || !is_real(saveStruct.version))
		{
			saveStruct.version = 0;
		}

		var v = floor(saveStruct.version);

		while(v < saveVersion)
		{
			var key = string(v);

			if(!variable_struct_exists(migrations, key))
			{
				setError("Missing migration for version " + key);
				return undefined;
			}

			var fn = migrations[$ key];
			var next = fn(saveStruct);

			if(!is_struct(next))
			{
				setError("Migration " + key + " returned invalid data");
				return undefined;
			}

			saveStruct = next;

			v += 1;
			saveStruct.version = v;
		}

		return saveStruct;
	};

	applySaveStruct = function(saveStruct)
	{
		if(!is_struct(saveStruct))
		{
			setError("Invalid save");
			return false;
		}

		if(!variable_struct_exists(saveStruct, "data") || !is_struct(saveStruct.data))
		{
			saveStruct.data = {};
		}

		var ids = variable_struct_get_names(providers);
		var n = array_length(ids);

		for(var i = 0; i < n; i += 1)
		{
			var _id = ids[i];
			var p = providers[$ _id];

			if(!is_struct(p) || !variable_struct_exists(p, "load") || !is_callable(p.load))
			{
				continue;
			}

			var part = variable_struct_exists(saveStruct.data, _id) ? saveStruct.data[$ _id] : undefined;
			p.load(part);
		}

		return true;
	};

	writeTextFile = function(path, text)
	{
		var f = file_text_open_write(path);
		if(f < 0)
		{
			return false;
		}

		file_text_write_string(f, text);
		file_text_close(f);

		return true;
	};

	readTextFile = function(path)
	{
		if(!file_exists(path))
		{
			return undefined;
		}

		var f = file_text_open_read(path);
		if(f < 0)
		{
			return undefined;
		}

		var out = "";

		while(!file_text_eof(f))
		{
			out += file_text_readln(f);

			if(!file_text_eof(f))
			{
				out += "\n";
			}
		}

		file_text_close(f);
		return out;
	};

	safeWrite = function(path, text, slot)
	{
		var tmp = makeTempFileName(slot);

		if(file_exists(tmp))
		{
			file_delete(tmp);
		}

		if(!writeTextFile(tmp, text))
		{
			setError("Write temp failed");
			return false;
		}

		if(file_exists(path))
		{
			file_delete(path);
		}

		var ok = file_rename(tmp, path);

		if(!ok)
		{
			if(file_exists(tmp))
			{
				file_delete(tmp);
			}

			setError("Rename temp failed");
			return false;
		}

		return true;
	};

	hasSave = function(slot)
	{
		return file_exists(makeFileName(slot));
	};

	deleteSave = function(slot)
	{
		clearError();

		var path = makeFileName(slot);

		if(!file_exists(path))
		{
			return true;
		}

		var ok = file_delete(path);

		if(!ok)
		{
			setError("Delete failed");
		}

		return ok;
	};

	save = function(slot)
	{
		clearError();

		var s = is_real(slot) ? floor(slot) : activeSlot;
		s = max(0, s);

		var path = makeFileName(s);
		var root = buildSaveStruct();

		var json = json_stringify(root);
		if(is_undefined(json) || json == "")
		{
			setError("JSON stringify failed (provider data must be JSON-safe)");
			emitSaveFailed(s);
			return false;
		}

		if(!safeWrite(path, json, s))
		{
			emitSaveFailed(s);
			return false;
		}

		emitSaved(s);
		return true;
	};

	load = function(slot)
	{
		clearError();

		var s = is_real(slot) ? floor(slot) : activeSlot;
		s = max(0, s);

		var path = makeFileName(s);

		if(!file_exists(path))
		{
			setError("Save not found");
			emitLoadFailed(s);
			return false;
		}

		var text = readTextFile(path);
		if(is_undefined(text))
		{
			setError("Read failed");
			emitLoadFailed(s);
			return false;
		}

		var root = json_parse(text);
		if(!is_struct(root))
		{
			setError("JSON parse failed");
			emitLoadFailed(s);
			return false;
		}

		var migrated = migrateToCurrent(root);
		if(!is_struct(migrated))
		{
			emitLoadFailed(s);
			return false;
		}

		if(!applySaveStruct(migrated))
		{
			emitLoadFailed(s);
			return false;
		}

		emitLoaded(s, migrated.version);
		return true;
	};

	emit = function(eventName, payload)
	{
		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.emit(eventName, payload, noone);
	};

	emitSaved = function(slot)
	{
		emit("saveGame/saved", { slot : slot });
	};

	emitSaveFailed = function(slot)
	{
		emit("saveGame/saveFailed", { slot : slot, error : lastError });
	};

	emitLoaded = function(slot, version)
	{
		emit("saveGame/loaded", { slot : slot, version : version });
	};

	emitLoadFailed = function(slot)
	{
		emit("saveGame/loadFailed", { slot : slot, error : lastError });
	};

	onSave = function(payload, eventName, sender)
	{
		var slot = is_struct(payload) && variable_struct_exists(payload, "slot") ? payload.slot : activeSlot;
		save(slot);
	};

	onLoad = function(payload, eventName, sender)
	{
		var slot = is_struct(payload) && variable_struct_exists(payload, "slot") ? payload.slot : activeSlot;
		load(slot);
	};

	onDelete = function(payload, eventName, sender)
	{
		var slot = is_struct(payload) && variable_struct_exists(payload, "slot") ? payload.slot : activeSlot;
		deleteSave(slot);
	};

	onSetSlot = function(payload, eventName, sender)
	{
		if(is_struct(payload) && variable_struct_exists(payload, "slot"))
		{
			setActiveSlot(payload.slot);
		}
	};

	init = function(bus)
	{
		eventBus = bus;

		if(is_undefined(eventBus))
		{
			return;
		}

		eventBus.on("saveGame/save", method(self, self.onSave));
		eventBus.on("saveGame/load", method(self, self.onLoad));
		eventBus.on("saveGame/delete", method(self, self.onDelete));
		eventBus.on("saveGame/setSlot", method(self, self.onSetSlot));
	};
}
