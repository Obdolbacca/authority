require 'spec_helper'
require 'support/example_model'
require 'support/user'

describe Authority do

  it "has a default list of abilities" do
    Authority.abilities.should be_a(Hash)
  end

  it "does not allow modification of the Authority.abilities hash directly" do
    expect { Authority.abilities[:exchange] = 'fungible' }.to raise_error(
      StandardError, /modify frozen/
    ) # can't modify frozen hash - exact error type and message depends on Ruby version
  end

  it "has a convenience accessor for the ability verbs" do
    Authority.verbs.map(&:to_s).sort.should eq(['create', 'delete', 'read', 'update'])
  end

  it "has a convenience accessor for the ability adjectives" do
    Authority.adjectives.sort.should eq(%w[creatable deletable readable updatable])
  end

  describe "configuring Authority" do

    it "has a configuration accessor" do
      Authority.should respond_to(:configuration)
    end

    it "has a `configure` method" do
      Authority.should respond_to(:configure)
    end

    it "requires the remainder of library internals after configuration" do
      Authority.should_receive(:require_authority_internals!)
      Authority.configure
    end
  end

  describe "enforcement" do

    before :each do
      @user = User.new
    end

    describe "if given options" do

      it "checks the user's authorization, passing along the options" do
        options = { :for => 'context' }
        @user.should_receive(:can_delete?).with(ExampleModel, options).and_return(true)
        Authority.enforce(:delete, ExampleModel, @user, options)
      end

    end

    describe "if not given options" do

      it "checks the user's authorization, passing no options" do
        @user.should_receive(:can_delete?).with(ExampleModel).and_return(true)
        Authority.enforce(:delete, ExampleModel, @user)
      end

    end

    it "raises a SecurityViolation if the action is unauthorized" do
      expect { Authority.enforce(:update, ExampleModel, @user) }.to raise_error(Authority::SecurityViolation)
    end

    it "doesn't raise a SecurityViolation if the action is authorized" do
      expect { Authority.enforce(:read, ExampleModel, @user) }.not_to raise_error(Authority::SecurityViolation)
    end

  end

  describe Authority::SecurityViolation do

    before :each do
      @user               = "I am a user"
      @action             = :keelhaul
      @resource           = "I am a resource"
      @security_violation = Authority::SecurityViolation.new(@user, @action, @resource)
    end

    it "has a reader for the user" do
      @security_violation.user.should eq(@user)
    end

    it "has a reader for the action" do
      @security_violation.action.should eq(@action)
    end

    it "has a reader for the resource" do
      @security_violation.resource.should eq(@resource)
    end

    it "uses them all in its message" do
      @security_violation.message.should eq("#{@user} is not authorized to #{@action} this resource: #{@resource}")
    end

  end

end
