require "vote_fu"
require "dispatcher"

module FedenaBlog
  
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_blog do
      ::User.instance_eval { include UserExtension }
      ::Student.instance_eval { include StudentExtension }
    end
  end

  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_one :blog
        has_many :blog_comments
        acts_as_voter
      end
    end
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee" or record.class.to_s == "Student"
        return true if record.user.blog.present?
        return true if record.user.blog_comments.showable.present?
        if record.user.blog.present?
        return true if record.user.blog.blog_posts.present?
        end
      end
    end
    return false
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_blog_dependency, :student, :warning_message => :blog_activity_present ) do
          self.blog_dependencies
        end
      end
    end

    def blog_dependencies
      return false if self.user.blog.present? or self.user.blog_comments.showable.present?
      if self.user.blog.present?
        return false if self.user.blog.blog_posts.present?
      end
      return true
    end
  end
end

