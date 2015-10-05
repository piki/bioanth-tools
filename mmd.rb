#!/usr/bin/ruby
#
# mmd: calculate theta values, mean measure of divergence (MMD), and MMD
# standard devation for 2 or more input files.
#
# Usage:
#   mmd file1 file2 [file3 [file4 [...]]]
#
# Output is a CSV file containing separate tables for thetas, MMD,
# sdMMD, MMD/Standardized MMD (above/below diagonal) and trait frequencies.
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
	puts "Thetas,#{files[0].trait_names.join(',')}"
	files.each_index{|i|
		puts "#{shortnames[i]},#{files[i].thetas.join ','}"
	}

	puts "\nMMDs,#{shortnames.join ','}"
	files.each_index{|i|
		puts "#{shortnames[i]},#{(0..files.length-1).collect{|j| mmd(files[i], files[j])}.join ','}"
	}

	puts "\nsd MMDs,#{shortnames.join ','}"
	files.each_index{|i|
		puts "#{shortnames[i]},#{(0..files.length-1).collect{|j| sdmmd(files[i], files[j])}.join ','}"
	}

	puts "\n\"MMD/Standardized MMD\",#{shortnames.join ','}"
	files.each_index{|i|
		puts "#{shortnames[i]},#{(0..files.length-1).collect{|j|
			j<i ? mmd(files[i], files[j])/sdmmd(files[i], files[j]) :
			j==i ? "-" :
			mmd(files[i], files[j])}.join ','
		}"
	}

	puts "\nTrait frequencies"
	puts "Trait,#{shortnames.join ','}"
	(0..files[0].ntraits-1).each{|t|
		print "#{files[0].trait_names[t]}," +
		files.collect{|f|
			nyes = f.count_yes(t)
			nmeasured = f.count_measured(t)
			sprintf "%d/%d=%.1f", nyes, nmeasured, nmeasured>0 ? 100*nyes.to_f/nmeasured : 0;
		}.join(',') + "\n"
	}
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
		while !(line = file.shift).nil?
			@data.push(line[start_column..-1].collect{|x| x.to_i})
		end
	end

	def theta(trait)
		k = count_yes(trait).to_f
		n = count_measured(trait).to_f
		ret = 0.5 * Math.asin(1 - 2*k / (n + 1)) + 0.5 * Math.asin(1 - 2*(k + 1) / (n + 1))
		ret > 0 && ret < 1e-15 ? 0 : ret
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
