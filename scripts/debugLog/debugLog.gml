function debugLog(msg)
{
	if(is_struct(global.debugConsole) && is_method(global.debugConsole.log))
	{
		global.debugConsole.log(msg);
	}
	else
	{
		show_debug_message(string(msg));
	}
}
