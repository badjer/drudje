require_relative 'drudje_io.rb'

class Drudje
	# TODO: Separate file access to separate object
	# so that we can test everything
	attr_accessor :src, :dest, :extension, :io, :lib, :pattern
	def initialize(src, dest, ext, lib, pattern)
    lib = src if lib == nil
		@extension = ext
    @src = src.end_with?('/') ? src.chomp('/') : src
    @dest = dest.end_with?('/') ? dest.chomp('/') : dest
		@io = DrudjeIo.new
    @lib = lib
    @pattern = pattern || File.join(src, '*.' + extension)
	end

	def render(template, args)
		template.gsub(/\[\[=([^\]]+)\]\]/){
			if(args[$1] != nil)
				args[$1]
			else
				''
			end
		}
	end

	def unquote(str)
		if str.start_with?('"', "'")
			str = str.slice(1..-1)
		end
		if str.end_with?('"', "'")
			str = str.slice(0..-2)
		end
		str
	end

	def get_args(call_str)
		arg_str = call_str.strip.partition(/[\n\r\s]+/)[2]
		if is_empty_args(arg_str)
			{}
		elsif is_arg_hash(arg_str)
			get_arg_hash arg_str
		else
			{'contents' => arg_str}
		end
	end

	def is_empty_args(arg_str)
		arg_str =~ /\A[\s\n\r]*\z/
	end

	def is_arg_hash(arg_str)
		arg_str =~ /\A([^ ]+=.+[\s\n\r]*)+\z/
	end

	def get_arg_hash(arg_str)
		parts = arg_str.scan(/(?:"(?:\\.|[^"])*"|[^"\s\n\r])+/)
		res = {}
		parts.each{|part|
			key, eq, val = part.partition('=')
			res[key] = unquote(val)
		}
		res
	end

	def template_file(call_str)
		parts = call_str.strip.partition(/[\s\n\r]+/)
		File.join self.lib, parts[0] + '.' + self.extension
	end

	def output_file(file)
    path = File.dirname file
    if path =~ Regexp.new("\/" + self.src + "\/")
      destpath = path.gsub Regexp.new("\/" + self.src + "\/"), "/" + self.dest + "/"
    elsif path =~ Regexp.new("^" + self.src + "\/")
      destpath = path.gsub Regexp.new("^" + self.src + "\/"), self.dest + "/"
    else
      destpath = self.dest
    end
		base = File.basename file
		File.join destpath, base
	end

	def expand(call_str)
		template = io.read template_file(call_str)
		args = get_args call_str
		render template, args
	end

	def process_pass(str)
		str.gsub(/\[\[([^\[\]]+)\]\]/){ expand($1) }
	end

	def process(str)
		processed = process_pass(str)
		while(processed != str)
		str = processed
			processed = process_pass(str)
		end
		processed
	end

	def run
		files = Dir.glob(self.pattern)
    puts "No files found matching " + self.pattern.to_s if files.length == 0
		files.each do |file|
      outfile = output_file(file)
			puts 'Processing file ' + file + ' to ' + outfile
			contents = self.io.read file
			processed = process contents
			self.io.write outfile, processed
		end
	end
end
