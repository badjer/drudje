require 'spec_helper'

describe Drudje do
	before :each do
		@drudje = Drudje.new('src', 'dest', '.html')
	end

	describe "#new" do
		it "should return an object" do
			@drudje.should be
		end
	end

	describe "#unquote" do
		it "should remove double quotes" do
			res = @drudje.unquote('"Hi"')
			res.should == 'Hi'
		end
		it "should leave strings with no quotes" do
			res = @drudje.unquote('Hi')
			res.should == 'Hi'
		end
		it "should work for empty strings" do
			res = @drudje.unquote('')
			res.should == ''
		end
	end

	describe "#get_args" do
		it "should parse an empty string as {}" do
			res = @drudje.get_args "template"
			res.should == {}
		end
		it "should get a hash from hash args" do
			res = @drudje.get_args "template a=1 b=2"
			res.should == {'a' => '1', 'b' => '2'}
		end
		it "should unquote args" do
			res = @drudje.get_args "template a='1'"
			res.should == {'a' => '1'}
		end
		it "should handle args with spaces if they're double-quoted" do
			res = @drudje.get_args 'template a="some text"'
			res.should == {'a' => 'some text'}
		end
		it "should return {contents => foo} for non-hash args" do
			res = @drudje.get_args 'template <h1>Hi</h1>'
			res.should == {'contents' => '<h1>Hi</h1>'}
		end
		it "should return {contents => ...} for html args" do
			res = @drudje.get_args "template <a href='hi'>hi</a>"
			res.should == {'contents' => "<a href='hi'>hi</a>"}
		end
		it "should return {contents => ...} with newline" do
			res = @drudje.get_args "template\n<a href='hi'>hi</a>"
			res.should == {'contents' => "<a href='hi'>hi</a>"}
		end
		it "should return {contents => ...} with double newlines" do
			res = @drudje.get_args "template\n\n<h1>hi</h1>"
			res.should == {'contents' => "<h1>hi</h1>"}
		end
		it "should handle hash arguments with newline" do
			res = @drudje.get_args "template a=1\nb=2"
			res.should == {'a' => '1', 'b' => '2'}
		end
		it "should handle quoted arguments with = in them" do
			res = @drudje.get_args 'template url="/page?z=1"'
			res.should == {'url' => '/page?z=1'}
		end
	end

	describe "#output_file" do
		it "should be destination path + file name" do
			res = @drudje.output_file 'template.html'
			res.should == 'dest/template.html'
		end
		it "should work with qualified paths" do
			res = @drudje.output_file 'src/template.html'
			res.should == 'dest/template.html'
		end
	end


	describe "#template_file" do
		it "should be src path + call name" do
			res = @drudje.template_file 'template'
			res.should == 'src/template.html'
		end
		it "should work with args" do
			res = @drudje.template_file 'template a=1 b=2'
			res.should == 'src/template.html'
		end
		it "should work with contents block" do
			res = @drudje.template_file 'template <h1>Hi world</h1>'
			res.should == 'src/template.html'
		end
		it "should work with newlines" do
			res = @drudje.template_file "template\n<br/>"
			res.should == 'src/template.html'
		end
	end

	describe "#render" do
		it "should do value replacement" do
			res = @drudje.render 'Hi [[=name]]', {'name' => 'world'}
			res.should == 'Hi world'
		end
		it "should ignore template calls" do
			res = @drudje.render 'Hi [[template]]', {'template' => 'world'}
			res.should == 'Hi [[template]]'
		end
		it "should insert '' if it can't find a value" do
			res = @drudje.render 'Hi [[=name]]', {'a' => 'world'}
			res.should == 'Hi '
		end
	end

	describe "#expand" do
		before :each do
			@drudje.io = double(DrudjeIo)
			@drudje.io.stub(:read).and_return('hello [[=name]]')
		end

		it "should do template expansion" do
			res = @drudje.expand 'template'
			res.should == 'hello '
		end
		it "should do value replacement" do
			res = @drudje.expand 'template name=world'
			res.should == 'hello world'
		end
	end

	describe "#process" do
		before :each do
			@drudje.io = double(DrudjeIo)
			@drudje.io.stub(:read) {|name|
				case name
				when 'src/greet.html' 
					'hello [[=name]]'
				when 'src/title.html' 
					'<h1>HI</h1>'
				when 'src/small.html'
					'<small>[[=contents]]</small>'
				end
			}
		end

		it "should replace content (no args)" do
			res = @drudje.process '<div>[[title]]</div>'
			res.should == '<div><h1>HI</h1></div>'
		end
		it "should replace content (hash args)" do
			res = @drudje.process '<div>[[greet name=world]]</div>'
			res.should == '<div>hello world</div>'
		end
		it "should replace content (contents arg)" do
			res = @drudje.process '<p>hi [[small world]]</p>'
			res.should == '<p>hi <small>world</small></p>'
		end
		it "should replace nested content (no args)" do
			res = @drudje.process '<p>[[small [[title]] ]]</p>'
			res.should == '<p><small><h1>HI</h1></small></p>'
		end
		it "should replace nested content (hash args)" do
			res = @drudje.process '<p>[[small [[greet name=foo]] ]]</p>'
			res.should == '<p><small>hello foo</small></p>'
		end
		it "should replace nested content (contents args)" do
			res = @drudje.process '<p>[[small [[small <br/>]] ]]</p>'
			res.should == '<p><small><small><br/></small></small></p>'
		end
	end
	
end
