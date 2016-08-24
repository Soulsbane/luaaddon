module luaaddon.tocparser;

import std.stdio;
import std.file;
import std.string;
import std.regex : matchFirst, ctRegex;
import std.algorithm;

enum _TocLinePattern = r"##\s+(?P<key>.*):\s+(?P<value>.*)";

struct TocParser
{
	void processText(const string text)
	{
		auto lines = text.lineSplitter();
		auto linePattern = ctRegex!(_TocLinePattern);

		foreach(line; lines)
		{
			line = strip(line);

			if(line.empty)
			{
				continue;
			}
			else if(line.startsWith("#"))
			{
				auto re = matchFirst(line, linePattern);

				if(!re.empty)
				{
					const string key = re["key"];
					const string value = re["value"];

					fields_[key] = value;
				}
			}
			else // Line is a file name
			{
				if(line.length != line.countchars(" ")) // Make sure line isn't only whitespace
				{
					filesList_ ~= line;
				}
			}
		}
	}

	bool loadString(const string text)
	{
		if(text.length)
		{
			processText(text);
			return true;
		}

		return false;
	}

	bool loadFile(const string fileName)
	{
		if(fileName.exists)
		{
			processText(fileName.readText);
			return true;
		}

		return false;
	}

	bool hasField(const string name)
	{
		if(name in fields_)
		{
			return true;
		}

		return false;
	}

	string getValue(const string name, string defaultValue = string.init)
	{
		if(hasField(name))
		{
			return fields_[name];
		}

		return defaultValue;
	}

	string[] getFilesList()
	{
		return filesList_;
	}

	void dump()
	{
		writeln("=====================Key Value Fields=======================");
		foreach(key, value; fields_)
		{
			writeln(key, " => ", value);
		}

		writeln("========================Files List==========================");
		each!writeln(filesList_);
	}

private:
	string[] filesList_;
	string[string] fields_;
}
