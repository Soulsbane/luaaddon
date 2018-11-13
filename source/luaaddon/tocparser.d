/**
	Provides functionality for parsing TOC(Table of Contents) files like those found in World of Warcraft.
*/
module luaaddon.tocparser;

import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.conv : to;
import std.array;
import std.regex : matchFirst, ctRegex, regex;
import std.algorithm;
import std.encoding : utfBOM;

import dstringutils.utils;

struct TocField
{
	string key;
	string value;
}

struct DefaultNamedMethods
{
	size_t Version; //NOTE: Since DLang already has a version keyword we have to use a caps version.
	string author;
	string description;
	string name;
}

/// Parses TOC(Table of Contents) files like those found in World of Warcraft.
/// Note that in order to use this without passing a struct you must initialize it like so: TocParser!() parser;
struct TocParser(NamedMethods = DefaultNamedMethods)
{
	mixin(generateNamedMethods!NamedMethods);

	/**
		Processes text containing the TOC format.

		Params:
			text = The text to be processed.
	*/
	void processText(const string text) pure @safe
	{
		auto lines = text.lineSplitter();

		foreach(line; lines)
		{
			line = strip(line);

			// INFO: Remove BOM here if present.
			if(!line.empty && line.front == utfBOM)
			{
				line.popFront();
			}

			if(line.startsWith("##"))
			{
				auto values = line.chompPrefix("##").strip.splitter(":").array;
				if(values.length == 2)
				{
					immutable string key = values[0].strip;
					immutable string value = values[1].strip;
					TocField field;

					field.key = key;
					field.value = value;
					fields_ ~= field;
				}
			}
			else if(line.empty || (line.startsWith("##") && !line.canFind(":"))) // Line is a comment or empty.
			{
				continue;
			}
			else // Line is a file name
			{
				if(!line.hasOnlySpaces()) // Make sure line isn't only whitespace
				{
					filesList_ ~= line;
				}
			}
		}
	}

	/**
		Loads and processes a string containing the TOC text.

		Params:
			text = The text to process.

		Returns:
			True if the text has a length(not empty) false otherwise.
	*/
	bool loadString(const string text) pure @safe
	{
		if(text.length)
		{
			processText(text);
			return true;
		}

		return false;
	}

	/**
		Loads and processes a file that contains the TOC text.

		Params:
			fileName = The name of the file to process.

		Returns:
			True if the file could be found false otherwise.
	*/
	bool loadFile(const string fileName)
	{
		if(fileName.exists)
		{
			processText(fileName.readText);
			fileName_ = fileName;

			return true;
		}

		return false;
	}

	/**
		Saves the values to the same file that values were read from.
	*/
	void save()
	{
		save(fileName_);
	}

	/**
		Saves the values to the given file name.

		Params:
			fileName = Name of the file to save to.
	*/
	void save(const string fileName)
	{
		if(fileName.length)
		{
			auto file = File(fileName, "w+");

			fields_.each!(field => file.write("## ", field.key, ": ", field.value, "\n"));
			filesList_.each!(fileName => file.writeln(fileName));
		}
	}

	/**
		Checks if a TOC field can be found.

		Params:
			name = The name of the field to find.

		Returns:
			True if the field was found false otherwise.
	*/
	bool hasField(const string name) pure nothrow @safe
	{
		foreach(field; fields_)
		{
			if(field.key == name)
			{
				return true;
			}
		}

		return false;
	}

	/**
		Finds the TOC Field and returns its index.

		Params:
			name = The name of the field to find.

		Returns:
			Its index or -1
	*/
	int hasFieldWithIndex(const string name)
	{
		foreach(int i, field; fields_)
		{
			if(field.key == name)
			{
				return i;
			}
		}

		return -1;
	}

	/**
		Removes a field and its value from the TOC file.

		Params:
			name = The name of the field to remove.
	*/
	void removeField(const string name)
	{
		immutable int fieldIndex = hasFieldWithIndex(name);

		if(fieldIndex >= 0)
		{
			//TODO: When save support is implemented we should save here.
			fields_ = fields_.remove!(a => a.key == name);
		}
	}

	/**
		Inserts a field and its value into the TOC file.

		Params:
			name = The name of the field to insert.
			value = The value of the field.
	*/
	void addField(const string fieldName, const string value)
	{
		TocField toc;

		toc.key = fieldName;
		toc.value = value;
		fields_ ~= toc;
	}
	/**
		Sets a fields value.

		Params:
			fieldName = Name of the field to set.
			value = The value to set the field to.
	*/
	void setValue(const string fieldName, const string value)
	{
		immutable int index = hasFieldWithIndex(fieldName);

		if(index >= 0)
		{
			fields_[index].value = value;
		}
	}

	/**
		Gets the value for a given field.

		Params:
			name = Name of the field to get the value for.
			defaultValue = The default value if the field wasn't found.

		Returns:
			The fields value if it was found otherwise the defaultValue.
	*/
	T getValue(T = string)(const string name, T defaultValue = T.init) pure @safe
	{
		immutable int fieldIndex = hasFieldWithIndex(name);

		if(fieldIndex != -1)
		{
			return fields_[fieldIndex].value.to!T;
		}

		return defaultValue;
	}

	/// Useful when you want to use getValue!T to convey the calls meaning better.
	alias as = getValue;

	/**
		Gets the list of file that a TOC file contains.

		Returns:
			A list of files that a TOC file contains.
	*/
	string[] getFilesList() pure @safe
	{
		return filesList_;
	}

	/**
		Gets a fields value.

		Params:
			name = Name of the field to return.

		Returns:
			The value of the specified field.
	*/
	TocField opIndex(size_t index) nothrow pure @safe
	{
		return fields_[index];
	}

	/**
		Gets a fields value.

		Params:
			name = Name of the field to get.

		Returns:
			The value of the specified field.
	*/
	string opIndex(const string name)
	{
		return getValue(name, string.init);
	}

	/**
		Removes all fields from TocParser.
	*/
	void clear() nothrow pure @safe
	{
		fields_ = [];
	}

	/**
		The number of fields TocParser has.
	*/
	size_t length() const nothrow pure @safe @property
	{
		return fields_.length;
	}

	/**
		True of there are no fields. False otherwise.
	*/
	bool empty() const nothrow pure @safe @property
	{
		return fields_.length == 0;
	}

	/**
		Gets the first field in TocParaser.
	*/
	ref TocField front() nothrow pure @safe
	{
		return fields_[0];
	}

	/**
		Removes the first field in TocParser.
	*/
	void popFront() nothrow pure @safe
	{
		fields_ = fields_[1..$];
	}

	/**
		Gets the last field in TocParser.
	*/
	ref TocField back() nothrow pure @safe
	{
		return fields_[$-1];
	}

	/**
		Removes the last field in TocParser.
	*/
	void popBack() nothrow pure @safe
	{
		fields_ = fields_[0..$-1];
	}

	TocParser save() nothrow pure @safe
	{
		return this;
	}

private:
	string[] filesList_;
	TocField[] fields_;
	string fileName_;
}

/*
	This function generates the following code based on the passed struct.

	struct Methods
	{
		string author;
	}

	string getAuthor(const string name, string defaultValue = string.init) pure @safe
	{
		immutable int fieldIndex = hasFieldWithIndex("Author");

		if(fieldIndex != -1)
		{
			return fields_[fieldIndex].value.to!string;
		}

		return defaultValue; // There is no field Author in TOC file.
	}

	void setAuthor(const string value)
	{
		immutable int index = hasFieldWithIndex("Author");

		if(index >= 0)
		{
			fields_[index].value = value;
		}
	}

	NOTE: The struct members names must match the toc field you are looking for.
	Example:
		##Author: Takayoshi Ohmura

		struct Authors
		{
			string author; // Must be the same
			string authors // will generate getAuthors and setAuthors reguardless of what the TOC file looks like.
			//This is due to the methods being generated at compile time.
		}

*/
private string generateNamedMethods(T)()
{
	string code;

	foreach (i, memberType; typeof(T.tupleof))
	{
		immutable string memType = memberType.stringof;
		immutable string memName = T.tupleof[i].stringof;
		immutable string memNameCapitalized = memName[0].toUpper.to!string ~ memName[1..$];

		code ~= format(q{
			%s get%s(%s defaultValue = %s.init) pure @safe
			{
				immutable int fieldIndex = hasFieldWithIndex("%s");

				if(fieldIndex != -1)
				{
					return fields_[fieldIndex].value.to!%s;
				}

				return defaultValue; // There is no field Author in TOC file.
			}
		}, memType, memNameCapitalized, memType, memType, memNameCapitalized, memType);

		code ~= format(q{
			void set%s(T)(T value)
			{
				immutable int index = hasFieldWithIndex("%s");

				if(index >= 0)
				{
					fields_[index].value = value.to!string;
				}
			}
		}, memNameCapitalized, memNameCapitalized);
	}

	return code;
}

///
unittest
{
	immutable string tocData = "
		\n##Author: Alan
		\n##Description: A short description.
		\n##Number: 100
		\n##RemoveIt: Remove this field.
		\nfile.d
		\napp.d
		\napp.lua
	";

	TocParser!() parser;

	parser.loadString(tocData);
	assert(parser.empty() == false);
	assert(parser[0].value == "Alan");
	assert(parser["Number"] == "100");
	assert(parser.hasField("Author") == true);
	assert(parser.hasField("NotAuthor") == false);
	assert(parser.getValue("Author") == "Alan");
	assert(parser.getValue("Animal", "Cat") == "Cat");
	assert(parser.as!uint("Number") == 100);
	assert(parser.getFilesList().length == 3);
	assert(parser["Author"] == "Alan");
	assert(parser["Programmer"] == string.init);

	parser.setValue("Number", "111");
	assert(parser.as!uint("Number") == 111);
	assert(parser.getValue("Number") == "111");

	assert(parser.hasField("RemoveIt") == true);
	parser.removeField("RemoveIt");
	assert(parser.hasField("RemoveIt") == false);

	assert(parser.hasField("InsertIt") == false);
	parser.addField("InsertIt", "Hello");
	assert(parser.hasField("InsertIt") == true);
	parser.clear();
	assert(parser.empty() == true);

	immutable string empty;
	TocParser!() emptyParser;

	assert(emptyParser.loadString(empty) == false);

	struct Methods
	{
		string author;
		uint number;
		uint count;
	}

	TocParser!Methods parserWithMethods;

	parserWithMethods.loadString(tocData);
	assert(parserWithMethods.getAuthor() == "Alan");
	assert(parserWithMethods.getNumber() == 100);
	assert(parserWithMethods.getCount(777) == 777);
	parserWithMethods.setCount("1234");
	assert(parserWithMethods.getCount(1234) == 1234);

	parserWithMethods.setCount(1335); // Doesn't work since the TOC file has no count field.
	assert(parserWithMethods.getCount(1335) == 1335);
	parserWithMethods.setAuthor("Bob");
	assert(parserWithMethods.getAuthor() == "Bob");

//	writeln(generateNamedMethods!Methods);
//	parserWithMethods.save("my.toc");
}
