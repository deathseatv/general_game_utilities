function OptionsMenu() : Menu("options", "OPTIONS", { background : true, backAction : "pop" }) constructor
{
	build = function(menuManager)
	{
		self.addSubmenu(menuManager, "Volume", "volume");
		self.addSubmenu(menuManager, "Keybinds", "keybinds");
		self.addAction(menuManager, "Back", method(menuManager, menuManager.actionBack));
	};
}
