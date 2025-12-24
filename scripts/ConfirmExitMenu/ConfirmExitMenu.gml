function ConfirmExitMenu() : Menu("confirmExit", "EXIT GAME?", { background : true, backAction : "main" }) constructor
{
	build = function(menuManager)
	{
		self.addAction(menuManager, "Yes", method(menuManager, menuManager.actionExit));
		self.addAction(menuManager, "No", method(menuManager, menuManager.actionExitCancel));
	};
}
