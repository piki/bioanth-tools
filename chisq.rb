#!/usr/bin/ruby
#
# chisq: calculate \chi^2 and \phi values for each site-pair for each
# trait in two or more input files.
#
# Usage:
#  chisq file1 file2 [file3 [file4 [...]]]
#
# Output is a CSV file containing one master table:
#       traits --->
# pairs
#   |   X^2 phi   X^2 phi     ...
#   v     ...       ...       ...
#
# Use split-input-file.rb if you have a single file containing all sites,
# with a one-line header and site names in column 1.

require 'csv'

def run
	if ARGV.length < 2
		$stderr.puts "Usage:"
		$stderr.puts "  #{$0} file1 file2 [file3 [...]]"
		exit 1
	end

	shortnames = ARGV.collect { |fn| File.basename(fn, '.csv') }
	files = ARGV.collect{|fn| TraitFile.new(fn)}
	traits_significant_count = Array.new(files[0].ntraits, 0)
	puts "\"\",#{files[0].trait_names.join(',,')}"
	files.each_index{|i|
		(i+1..files.length-1).each{|j|
			print "#{shortnames[i]}/#{shortnames[j]}"
			(0..files[0].ntraits-1).each{|t|
				a = files[i].count_yes(t).to_f
				b = files[i].count_measured(t) - a
				c = files[j].count_yes(t).to_f
				d = files[j].count_measured(t) - c
				n = a + b + c + d
				#puts "a=#{a}   b=#{b}   c=#{c}   d=#{d}"
				if (a+b>0 && c+d>0 && a+c>0 && b+d>0)
					chisq = (a*d - b*c)**2 * n / ((a+b) * (c+d) * (a+c) * (b+d))
					phi = (chisq/n)**0.5
					print ",#{chisq},#{phi}"
					if chisq > 3.84146 then traits_significant_count[t] += 1 end
				else
					print ",,"
				end
			}
			puts
		}
	}
	puts "Significant,#{traits_significant_count.join(',,')}"
end

def mmd(file1, file2)
	if file1.ntraits != file2.ntraits
		raise "Unequal numbers of traits"
	end
	if file1 == file2; return 0; end
	#(0..file1.ntraits-1).each{|i|
		#puts "#{i}: n1=#{file1.count_measured(i)} n2=#{file2.count_measured(i)} #{(file1.theta(i) - file2.theta(i)) ** 2 -
			#(1.0/(file1.count_measured(i)+0.5) + 1.0/(file2.count_measured(i)+0.5))}"
	#}
	((0..file1.ntraits-1).collect{|i|
		(file1.theta(i) - file2.theta(i)) ** 2 -
			(1.0/(file1.count_measured(i)+0.5) + 1.0/(file2.count_measured(i)+0.5))
	}.sum) / file1.ntraits
end

def varmmd(file1, file2)
	if file1.ntraits != file2.ntraits
		raise "Unequal numbers of traits"
	end
	if file1 == file2; return 0; end
	2.0 / file1.ntraits**2 *
		(0..file1.ntraits-1).collect{|i|
			(1.0/(file1.count_measured(i)+0.5) + 1.0/(file2.count_measured(i)+0.5)) ** 2
		}.sum
end

def sdmmd(file1, file2)
	varmmd(file1, file2)**0.5
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
		while !(line = file.shift).empty?
			@data.push(line[start_column..-1].collect{|x| x.to_i})
		end
	end

	def theta(trait)
		k = count_yes(trait).to_f
		n = count_measured(trait).to_f
		0.5 * Math.asin(1 - 2*k / (n + 1)) +
			0.5 * Math.asin(1 - 2*(k + 1) / (n + 1))
	end

	def count_measured(trait)
		@data.count_that {|person| person[trait] == 1 || person[trait] == 0}
	end

	def count_yes(trait)
		@data.count_that {|person| person[trait] == 1}
	end

	def thetas
		(0..ntraits-1).collect{|i| theta(i)}
	end

	def ntraits; @data[0].length end

	attr_reader :trait_names
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
