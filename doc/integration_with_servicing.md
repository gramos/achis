Servicing integration with Achis.
=================================

Add the provider in achis:
--------------------------

[Adding a new provider doc](https://github.com/Katlean/achis/blob/adding_a_new_provider_doc/doc/adding_a_new_provider.md)

Make a new release in achis.
----------------------------

```ruby
edit lib/achis/version.rb
gem_push=no rake release
```
Update achis version.
---------------------

The first step is update the achis version in the Gemfile:

```ruby
gem 'achis', git: 'git@github.com:Katlean/achis.git', tag: 'v1.0.0.beta9'
```
Add the rake task.
------------------

The next step is create the Rake task that will run
in a daily cron:
For the purpose of this example we are going to create
a new provider named "MockProvider".

```ruby

# lib/tasks/ach_mock_provider.rake
namespace :ach do
  namespace :mock_provider do

  desc 'Process MockProvider payments'
  task :payments, [:date] => [:environment] do |task, args|
    Ach::ProcessorFactory.process_payments_for :MockProvider, :date => args[:date]
  end

  desc 'Process MockProvider returns'
  task :returns, [:date] => [:environment] do |task, args|
    Ach::ProcessorFactory.process_returns_for :MockProvider, :date => args[:date]
  end

  desc 'Process MockProvider returns for yesterday'
  task :returns_for_yesterday => :environment do |task|
    processing_date = Date.today - 1
    Ach::ProcessorFactory.process_returns_for :MockProvider, :date => processing_date.to_s
  end

  desc 'Process MockProvider returns for today'g
  task :returns_for_today => :environment do |task|
    processing_date = Date.today
    Ach::ProcessorFactory.process_returns_for :MockProvider, :date => processing_date.to_s
  end
end
```
After this step you can test the new provider runing the rake task.
