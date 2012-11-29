require 'spec_helper'
require 'support/example_model'
require 'support/user'

describe Authority::Abilities do

  before :each do
    @user = User.new
  end

  describe "authorizer" do

    it "has a class attribute getter for authorizer_name" do
      ExampleModel.should respond_to(:authorizer_name)
    end

    it "has a class attribute setter for authorizer_name" do
      ExampleModel.should respond_to(:authorizer_name=)
    end

    it "has a default authorizer_name of 'ApplicationAuthorizer'" do
      ExampleModel.authorizer_name.should eq("ApplicationAuthorizer")
    end

    it "constantizes the authorizer name as the authorizer" do
      ExampleModel.instance_variable_set(:@authorizer, nil)
      ExampleModel.authorizer_name.should_receive(:constantize)
      ExampleModel.authorizer
    end

    it "memoizes the authorizer to avoid reconstantizing" do
      ExampleModel.authorizer
      ExampleModel.authorizer_name.should_not_receive(:constantize)
      ExampleModel.authorizer
    end

    it "raises a friendly error if the authorizer doesn't exist" do
      class NoAuthorizerModel < ExampleModel; end ;
      NoAuthorizerModel.instance_variable_set(:@authorizer, nil)
      NoAuthorizerModel.authorizer_name = 'NonExistentAuthorizer'
      expect { NoAuthorizerModel.authorizer }.to raise_error(Authority::NoAuthorizerError)
    end

  end

  describe "class methods" do

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "responds to `#{method_name}`" do
        ExampleModel.should respond_to(method_name)
      end

      describe "if given an options hash" do

        it "delegates `#{method_name}` to its authorizer class, passing the options" do
          ExampleModel.authorizer.should_receive(method_name).with(@user, ExampleModel, :lacking => 'nothing')
          ExampleModel.send(method_name, @user, :lacking => 'nothing')
        end

      end

      describe "if not given an options hash" do

        it "delegates `#{method_name}` to its authorizer class, passing no options" do
          ExampleModel.authorizer.should_receive(method_name).with(@user, ExampleModel)
          ExampleModel.send(method_name, @user)
        end

      end

    end

  end

  describe "instance methods" do

    before :each do
      @example_model = ExampleModel.new
      @authorizer    = ExampleModel.authorizer.new(@example_model)
    end

    Authority.adjectives.each do |adjective|
      method_name = "#{adjective}_by?"

      it "responds to `#{method_name}`" do
        @example_model.should respond_to(method_name)
      end

      describe "if given an options hash" do

        it "delegates `#{method_name}` to a new authorizer instance, passing the options" do
          ExampleModel.authorizer.stub(:new).and_return(@authorizer)
          @authorizer.should_receive(method_name).with(@user, :with => 'mayo')
          @example_model.send(method_name, @user, :with => 'mayo')
        end

      end

      describe "if not given an options hash" do
        
        it "delegates `#{method_name}` to a new authorizer instance, passing no options" do
          ExampleModel.authorizer.stub(:new).and_return(@authorizer)
          @authorizer.should_receive(method_name).with(@user)
          @example_model.send(method_name, @user)
        end

      end

    end

    it "provides an accessor for its authorizer" do
      @example_model.should respond_to(:authorizer)
    end

    # When checking instance methods, we want to ensure that every check uses a new
    # instance of the authorizer. Otherwise, you might check, make a change to the
    # model instance, check again, and get an outdated answer.
    it "always creates a new authorizer instance when accessing the authorizer" do
      @example_model.class.authorizer.should_receive(:new).with(@example_model).twice
      2.times { @example_model.authorizer }
    end

  end

end
