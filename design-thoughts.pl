# new function organization:
#
#	Keep IO and non-IO functions seperate (haskell, eat your heart out) for testing purposes. I think
#	IO functions can be represented by "file access" functions and non-IO functions can be represented
#	by "map manipulation" functions.
#
#	The purpose is to enable unit testing before moving forward with more complicated development.
#	Also it might enable replacing the file access functions with ones specific to the other
#	operating systems.
#
#	The file access code should remain relatively constant. The map manipulation code should be unit
#	tested heavily. The useful functionality of this project will exist at the intersection of the IO
#	and non-IO code. This intersection should be as small as possible
#
#	The complete separation of the two types of functions should be supported by the names of variables
#	and functions as much as possible.
#
#	Parsing functions/syntax defintions are an additional non-IO component of the project. These can
#	be unit tested and made replaceable.
#
#   file access functions (IO):
#		getFileContent(String path) - gets the content of one file located at a given path
#		getFolderContent(String path) - gets the contents of the files (as a map) at a given
#										path (for each item at a given folderPath,
#										calls either getFileContent or getFolderContent)
#		writeFile(String path, String content) - writes the given content to a given path
#		writeFiles(Map files) - calls writeFile once for each key:value (path:content) entry
#								in the given files map
#
#	map manipulation functions (non-IO):
#		populateTemplate(String templates, Map templates) - populates a given template with content from a
#															given templates map (calls itself recursively
#															to populate unpopulated template dependencies
#															of the given template)
#		populateTemplates(Map templates) - calls populateTemplate once for each template in a given
#										   templates map
#		locateTemplates(Map templates) - generates a map from a templates map that associates the final
#										 filePath with the final fileContent
#		identifyTemplates(Map templates) - generates a hash corresponding template names to template
#										   contents
#
#	syntax definitions:
#		String locationPattern - regex that identifies the final path for the template after
#								 population has been completed, if this isn't present in a file,
#								 it won't be written anywhere, something like "LOCATION('FILE_PATH')"
#		String identityPattern - regex that identifies the name/title/identity of a file for use in
#								 the templates map, something like "IDENTITY('IDENTITY_NAME')"
#		String dependencyPattern - regex that identifies the pattern for dependencies in a template,
#								   something like "DEPENDENCY('DEPENDENCY_NAME')"
#		String urlPattern - determines if a given path is a url or not (not a url => filepath) (for later)
#
#	intersections:
#		processFiles(String path) - write(locate(populate(read(root_folder_path))))

# syntax consideration:
# 	Should be easy to understand and write. Should not intersect with the syntax of other
#	languages (especially HTML and CSS)
#
# internet aspect:
# option to cache external/web references in the project structure, store cached content in
# plaintext files, maybe something like (URL IDENTITY CACHE_TIME CONTENT), might be performant and
# definitely makes the development cycle shorting and simpler with no external dependencies, option
# to adjust cache expiration time, option to cache external links (regex may be a challenge there),
# option to silent/warn/error on dead links and/or cache misses. also does a lot to harden a
# website (and the internet) against link rot (also less maintenance).
#
# something like NET_LINK("INTERNET_URL") for caching pure links and NET_DEPENDENCY("INTERNET_URL")
# for external links as dependencies
#
# A far future consideration is supporting inferior systems by abstracting the newline related logic
# to consider characters other than "\n"
#
# Should there be an empty check for the arrays and hashes being passed in?
#
# I think it makes sense to have locateTemplates() operate on a hash of identified templates, their
# identities are essentially the unique key to each template, and I can reasonably expect any future
# attribute to operate on the hash of identified templates.
