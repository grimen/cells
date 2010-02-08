# encoding: utf-8

gem 'activesupport', '<= 2.3.5'
require 'active_support'

gem 'actionpack', '<= 2.3.5'
require 'action_controller'

gem 'actionpack', '<= 2.3.5'
require 'action_view'

require 'cells/cell'
require 'cells/helpers'
require 'cell'

module Cells
  # Any config should be placed here using +mattr_accessor+.

  # Default view paths for Cells.
  DEFAULT_VIEW_PATHS = [
    File.join('app', 'cells'),
    File.join('app', 'cells', 'layouts')
  ]

  class << self
    # Holds paths in which Cells should look for cell views (i.e. view template files).
    #
    # == Default:
    #
    #   * +app/cells+
    #   * +app/cells/layouts+
    #
    def self.view_paths
      ::Cell::Base.view_paths
    end
    def self.view_paths=(paths)
      ::Cell::Base.view_paths = paths
    end
  end

  # Cells setup/configuration helper for initializer.
  #
  # == Usage/Exmaples:
  #
  #   Cells.setup do |config|
  #     config.cell_view_paths << Rails.root.join('lib', 'cells')
  #   end
  #
  def self.setup
    yield(self)
  end
end

Cell::Base.view_paths = Cells::DEFAULT_VIEW_PATHS if Cell::Base.view_paths.blank?

require 'cells/rails'
