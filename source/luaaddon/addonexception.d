module luaaddon.addonexception;

import std.exception;

class LuaAddonException : Exception
{
public:
	this(string msg, string file =__FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow
	{
		super("LuaAddonException: " ~ msg, file, line, next);
	}
}

