class AvailablePlugin < ActiveRecord::Base
  serialize :plugins
  belongs_to :associated, :polymorphic => true

  before_save :check_plugins

  def check_plugins
    self.plugins = [] if self.plugins.nil?
  end

  def after_initialize
    check_plugins
    plugins_will_change!
  end

end
