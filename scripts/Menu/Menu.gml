function Menu(menuId, menuTitle, opts) constructor
{
	var menuKey = string(menuId);
	var titleText = string(menuTitle);

	self.menuId = menuKey;
	self.menuTitle = titleText;

	self.background = true;
	self.backAction = "pop";

	if(is_struct(opts))
	{
		if(variable_struct_exists(opts, "background"))
		{
			self.background = opts.background;
		}

		if(variable_struct_exists(opts, "backAction"))
		{
			self.backAction = string(opts.backAction);
		}
	}

	self.register = method(self, function(menuManager)
	{
		if(!is_struct(menuManager))
		{
			return false;
		}

		if(!variable_struct_exists(menuManager, "addMenu") || !is_callable(menuManager.addMenu))
		{
			return false;
		}

		menuManager.addMenu(self.menuId, self.menuTitle, { background : self.background, backAction : self.backAction });

		if(variable_struct_exists(self, "build") && is_callable(self.build))
		{
			self.build(menuManager);
		}

		return true;
	});

	self.build = function(menuManager)
	{
	};

	self.addAction = function(menuManager, label, actionFn, opts)
	{
		return menuManager.addActionItem(self.menuId, label, actionFn, opts);
	};

	self.addSubmenu = function(menuManager, label, targetMenuId, opts)
	{
		return menuManager.addSubmenuItem(self.menuId, label, targetMenuId, opts);
	};

	self.addRange = function(menuManager, label, getFn, setFn, opts)
	{
		return menuManager.addRangeItem(self.menuId, label, getFn, setFn, opts);
	};

	self.addLabel = function(menuManager, label)
	{
		return menuManager.addLabelItem(self.menuId, label);
	};

	self.addKeybind = function(menuManager, label, actionName, opts)
	{
		return menuManager.addKeybindItem(self.menuId, label, actionName, opts);
	};
}
