drudje
======

Simple script for composing text files.


Installation
======

		gem install drudje

If you're using rbenv, you'll need to rehash:

		rbenv rehash

Usage
======

		drudje sourcedir destdir [extension]

sourcedir is a directory that holds source files that you'd like to process
Note that it is not recursive

destdir is the directory that the processed files are written to

extension is an optional param and defaults to '.html' Only files in 
sourcedir with that extension will be processed.


Template format
======

To call a template, place this in your source document:

		[[templatename]]

This will look for a file in the source directory with the name templatename.html
(it'll use whatever extension specified by the extension command-line arg). You can also
use templates from subfolders:

		[[controls/textbox]]

This will look for a template named controls/textbox.html under the source directory.

You can pass arguments to a template by specifying them as key-value pairs:

		[[templatename arg1=foo arg2="this is arg 2"]]

Arguments can be barewords, or wrapped in quotes if you want them to contain spaces.

You can use arguments in your template like this:

		[[=arg1]]

If the "arguments" aren't key-value pairs, then the entire blob of text after the 
template name is passed as an argument called "contents". This allows you to do
things like wrapping

		[[paragraph Hello <strong>world!</strong>]]

And you can use the contents argument just like any other:

		<p>[[=contents]]</p>

