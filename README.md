# Authority

## SUPER ALPHA VERSION

## Overview

Authority gives you a clean and easy way to say, in your Rails app, **who** is allowed to do **what** with your models.

It assumes that you already have some kind of user object in your application.

The goals of Authority are:

- To allow broad, class-level rules. Examples: 
  - "Basic users cannot delete **any** Widget."
  - "Only admin users can create Offices."

- To allow fine-grained, instance-level rules. Examples: 
  - "Management users can only edit schedules in their jurisdiction."
  - "Users can't create playlists more than 20 songs long unless they've paid."

- To provide a clear syntax for permissions-based views. Example:
  - `link_to 'Edit Widget', edit_widget_path(@widget) if current_user.can_edit?(@widget)`

- To gracefully handle any access violations: display a "you can't do that" screen and log the violation.

- To do all of this **without cluttering** either your controllers or your models. This is done by letting Authorizer classes do most of the work. More on that below.

## Installation

Add this line to your application's Gemfile:

    gem 'authority'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install authority

## How it works

In broad terms, the authorization process flows like this:

- A request comes to a model, either the class or an instance, saying "can this user do this action to you?"
- The model passes that question to its Authorizer
- The Authorizer checks whatever user properties and business rules are relevant to answer that question.
- The answer is passed back up to the model, then back to the original caller

## Usage

### Users

Your user model (whatever you call it) should `include Authority::UserAbilities`. This defines methods like `can_edit?(resource)`, which are just nice shortcuts for `resource.editable_by?(user)`. (TODO: Add this module).

### Models

In your models, simply `include Authority::Abilities`. This sets up both class-level and instance-level methods like `creatable_by?(user)`, etc, all of which delegate to the model's corresponding authorizer. For example, the `Rabbit` model would delegate to `RabbitAuthorizer`.

### Controllers

#### Basic Usage

In your controllers, add this method call:

`check_authorization_on ModelName`

That sets up a `:before_filter` that calls your class-level methods before each action. For instance, before running the `update` action, it will check whether `ModelName` is `updatable_by?` the current user at a class level. A return value of false means "this user can never update models of this class."

If that's all you need, one line does it.

#### In-action usage

If you need to check some attributes of a model instance to decide if an action is permissible, you can use `check_authorization_for(:action, @model_instance, @user)` (TODO: determine this)

### Authorizers

Authorizers should be added under `app/authorizers`, one for each of your models. Each authorizer should correspond to a single model. So if you have `app/models/laser_cannon.rb`, you should have, at minimum:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer
    end

These are where your actual authorization logic goes. You do have to specify your own business rules, but Authority comes with the following baked in:

- All class-level methods defined on `Authority::Authorizer` return false by default; you must override them in your Authorizers to grant permissions. This whitelisting approach will keep you from accidentally allowing things you didn't intend.
- All instance-level methods defined on `Authority::Authorizer` call their corresponding class-level method by default.

This combination means that, with this code:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer
    end

... you can already do the following:

    current_user.can_create?(LaserCannon)    # false; all inherited class-level permissions are false
    current_user.can_create?(@laser_cannon)  # false; instance-level permissions check class-level ones by default

If you update your authorizer as follows:

    # app/authorizers/laser_cannon_authorizer.rb
    class LaserCannonAuthorizer < Authority::Authorizer

      def self.creatable_by?(user) # class-level permission
        true
      end

      def deletable_by?(user)      # instance_level permission
        user.first_name == 'Larry' && Date.today.friday?
      end

    end

... you can now do this following:

    current_user.can_create?(LaserCannon)    # true, per class method above
    current_user.can_create?(@laser_cannon)  # true; inherited instance method calls class method
    current_user.can_delete?(@laser_cannon)  # Only Larry, and only on Fridays

## TODO

- Add a module, to be included in whatever user class an app has, which defines all the `can_(verb)` methods.
- Determine exact syntax for checking rules during a controller action.
- Add ability to customize default authorization
- Add customizable logger for authorization violations

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request