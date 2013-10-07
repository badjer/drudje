#!/usr/bin/env ruby
require 'fileutils'

class Drudje
	attr_accessor :src, :dest, :extension

	def render_template(template, args)
		template.gsub(/\[\[=([^\]]+)\]\]/){
			if(args[$1] != nil)
				args[$1]
			else
				''
			end
		}
	end

	def get_template(call_str)
		template_file = File.join src, call_str.strip.partition(/\s/)[0] + extension
		throw "Could not find " + template_file + " (from template call " + call_str + ")" if !File.exists?(template_file)
		template = File.read template_file
	end

	def remove_quotes(str)
		if str.start_with?('"')
			str = str.slice(1..-1)
		end
		if str.end_with?('"')
			str = str.slice(0..-2)
		end
		str
	end

	def get_args(call_str)
		arg_str = call_str.strip.partition(' ')[2]
		if is_arg_hash(arg_str)
			get_arg_hash arg_str
		else
			{'contents' => arg_str}
		end
	end

	def is_arg_hash(arg_str)
		puts "arg_str is " + arg_str
		arg_str =~ /^([^ ]+=.+ *)+$/
	end

	def get_arg_hash(arg_str)
		parts = arg_str.scan(/(?:"(?:\\.|[^"])*"|[^" ])+/)
		puts "parts is " + parts.to_s
		res = {}
		parts.each{|part|
			key, val = part.split('=')
			res[key] = remove_quotes(val)
		}
		res
	end

	def insert_template(call_str)
		puts "insert_template " + call_str
		template = get_template call_str
		args = get_args call_str
		puts "args: " + args.to_s
		render_template template, args
	end

	def process_pass(str)
		str.gsub(/\[\[([^\[\]]+)\]\]/){ insert_template($1) }
	end

	def process(str)
		processed = process_pass(str)
		while(processed != str)
		str = processed
			processed = process_pass(str)
		end
		processed
	end

	def write(file, str)
		dest_file = File.join dest, file
		dest_path = File.dirname dest_file
		FileUtils.mkdir_p(dest_path) unless File.exists?(dest_path)
		puts "Writing to " + dest_file
		File.write dest_file, str
	end	
end

#d = Drudje.new
#d.src = "./example"
#d.dest = "./public"
#d.extension = ".html"
#
#file = "index.html"
#full_file = File.join d.src, file
#contents = File.read full_file
#
#res = d.process(contents)
#puts res
#d.write(file, res)
