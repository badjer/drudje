require 'spec_helper'

describe Drudje do
	describe "#new" do
		it "should return an object" do
			d = Drudje.new
			d.should be
		end
	end
end
