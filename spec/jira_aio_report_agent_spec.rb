require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::JiraAioReportsAgent do
  before(:each) do
    @valid_options = Agents::JiraAioReportsAgent.new.default_options
    @checker = Agents::JiraAioReportsAgent.new(:name => "JiraAioReportsAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
