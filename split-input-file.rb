#!/usr/bin/ruby
#
# split-input-file: convert a unified file to a collection of files, each
# containing one site.
#
# The input file must contain a one-line header, followed by one line per
# individual, with the site name in column 1.  The output files will be in
# the same format (including the header), but with one site each.
#
# Usage:
#   split-input-file Foo.csv
#
# It will create X.csv, Y.csv, Z.csv, etc., for sites X, Y, and Z.

hdr = ARGF.gets
filemap = {}
ARGF.each {|line|
	next if line.chomp == ""   # skip blank lines
	key = line.split(',')[0]
	if !filemap[key]
		puts "New file: #{key}.csv"
		filemap[key] = File.new("#{key}.csv", "w")
		filemap[key].print(hdr);
	end
	filemap[key].print(line);
}
