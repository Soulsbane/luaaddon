module luaaddon.addonmanager;

import luaaddon.luaaddon;

class LuaAddonManager
{
	void register(LuaAddon addon)
	{
		addons_ ~= addon;
	}

private:
	LuaAddon[] addons_;
}

unittest
{
	LuaAddon addon = new LuaAddon;
	LuaAddonManager manager = new LuaAddonManager;

	manager.register(addon);
}
