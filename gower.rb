#!/usr/bin/ruby
#
# gower: calculate diversion percentage for all pairs of individuals
# in an input file.  The input file can be many sites or just one.
#
# Usage:
#   gower file
#
# Output is a CSV file containing the diversion percentages as a matrix.
#
# Use split-input-file.rb if you have a single file containing all sites,
# with a one-line header and site names in column 1.

require 'csv'

def run
	if ARGV.length != 1
		$stderr.puts "Usage:"
		$stderr.puts "  #{$0} file1"
		exit 1
	end

	tf = TraitFile.new(ARGV[0])
	puts tf.skel_id.collect{|id| ",\"#{id}\""}.join 
	(0..tf.npeople-1).each {|i|
		tot = 0
		count = 0
		puts("\"#{tf.skel_id[i]}\"," + (0..tf.npeople-1).collect {|j|
			t = tf.similarity(i, j)
			if !t.nan?
				tot += t
				count += 1
				t
			else
				"-"
			end
		}.join(','))     #  + ",#{tot/count.to_f}")
	}
end

class TraitFile
	def initialize(fn)
		file = CSV.open(fn, 'r')

		# read the header and try to figure out where the traits start.  the field
		# for the first trait starts with a "1", and all columns after that are
		# additional traits.
		line = file.shift
		start_column = nil
		line.each_index {|i|
			if (/^\d+\b/ =~ line[i])
				start_column = i
				break
			end
		}
		@trait_names = line[start_column..-1]
		if !start_column
			raise "#{fn}: No first trait column found.  Header missing or invalid."
		end
		$stderr.puts "#{fn}: Traits start in column #{start_column+1}"

		@data = []
		@skel_id = []
		while !(line = file.shift).empty?
			@skel_id.push(line[0])
			@data.push(line[start_column..-1].collect{|x| x.to_i})
		end
	end

	def similarity(person1, person2)
		valid = 0
		same = 0
		@data[person1].each_index {|i|
			if @data[person1][i] != 2 && @data[person2][i] != 2
				valid += 1
				if @data[person1][i] == @data[person2][i]
					same += 1
				end
			end
		}
		same.to_f / valid
	end

	def ntraits; @data[0].length end
	def npeople; @data.length end

	attr_reader :trait_names, :skel_id
end

class Array
	def count_that
		n = 0
		each {|x| if yield x; n += 1; end}
		n
	end
	def sum
		n = 0
		each {|x| n += x}
		n
	end
end

run
