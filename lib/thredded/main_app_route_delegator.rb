# frozen_string_literal: true
module Thredded
  # If thredded is rendered within an application layout, this module allows
  # referring to the routes in the layout directly, without having to use `main_app.`.
  module MainAppRouteDelegator
    def self.add_main_app_proxies
      path_methods = Rails.application.routes.url_helpers.methods.select { |s| s.to_s.ends_with?('_path', '_url') }
      path_methods.each do |method_name|
        send(:define_method, method_name) do |*args|
          main_app.send(method_name, *args)
        end
      end
    end
  end
end
