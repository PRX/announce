module Announce
  class Railtie < Rails::Railtie

    rake_tasks do
      load "tasks/announce.rake"
    end
  end
end