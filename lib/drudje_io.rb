require 'fileutils'

class DrudjeIo
	def read(file)
		throw "Could not find " + file if !File.exists?(file)
		File.read file
	end
	def write(file, str)
		path = File.dirname file
		FileUtils.mkdir_p(path) unless File.exists?(path)
		File.write file, str
	end
end
