module luaaddon.tocparser;

import std.stdio;
import std.file;
import std.path;
import std.array;
import std.string;
import std.regex;
import std.algorithm;

struct TocParser
{
	void processText(const string text)
	{
		auto lines = text.lineSplitter();

		foreach(line; lines)
		{
			line = strip(line);

			if(line.empty)
			{
				continue;
			}
			else if(line.startsWith("#"))
			{
				auto re = matchFirst(line, linePattern_);

				if(!re.empty)
				{
					const string key = re["key"];
					const string value = re["value"];

					fields_[key] = value;
				}
			}
			else // Line is a file name
			{
				filesList_ ~= line;
			}
		}
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
	Regex!char linePattern_ = regex(r"##\s+(?P<key>.*):\s+(?P<value>.*)");
}
