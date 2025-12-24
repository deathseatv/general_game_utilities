function KeybindsMenu() : Menu("keybinds", "KEYBINDS", { background : true, backAction : "pop" }) constructor
{
	build = function(menuManager)
	{
		self.addKeybind(menuManager, "Recenter", "recenter");
		self.addKeybind(menuManager, "Toggle Fullscreen", "toggleFullscreen");
		self.addAction(menuManager, "Reset to Defaults", method(menuManager, function()
		{
			var kb = self.getKeybinds();
			if(is_struct(kb)
				&& variable_struct_exists(kb, "resetDefaults")
				&& is_callable(kb.resetDefaults))
			{
				kb.resetDefaults();

				if(variable_struct_exists(kb, "save")
					&& is_callable(kb.save))
				{
					kb.save();
				}
			}
		}));
		self.addLabel(menuManager, "(Press Enter to rebind)");
		self.addAction(menuManager, "Back", method(menuManager, menuManager.actionBack));
	};
}
