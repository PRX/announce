module Announce
  class Railtie < Rails::Railtie
    rake_tasks { load "tasks/announce.rake" }
  end
end
