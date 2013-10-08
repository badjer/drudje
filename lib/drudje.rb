require_relative 'drudje_io.rb'

class Drudje
	# TODO: Separate file access to separate object
	# so that we can test everything
	attr_accessor :src, :dest, :extension, :io
	def initialize(src, dest, ext)
		@extension = ext
		@src = src
		@dest = dest
		@io = DrudjeIo.new
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
		arg_str =~ /\A([^ ]+=.+ *)+\z/
	end

	def get_arg_hash(arg_str)
		parts = arg_str.scan(/(?:"(?:\\.|[^"])*"|[^" ])+/)
		res = {}
		parts.each{|part|
			key, val = part.split('=')
			res[key] = unquote(val)
		}
		res
	end

	def template_file(call_str)
		parts = call_str.strip.partition(/[\s\n\r]+/)
		File.join self.src, parts[0] + self.extension
	end

	def output_file(file)
		base = File.basename file
		File.join self.dest, base
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
		pattern = File.join self.src, '*' + self.extension
		files = Dir.glob(pattern)
		files.each do |file|
			puts "Processing file " + file
			contents = self.io.read file
			processed = process contents
			self.io.write output_file(file), processed
		end
	end
end
