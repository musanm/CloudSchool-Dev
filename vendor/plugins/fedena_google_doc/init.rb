require 'oauth2'
require File.join(File.dirname(__FILE__), "lib", "fedena_google_doc")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_google_doc",
  :description=>"Fedena Google Doc",
  :auth_file=>"config/google_docs_auth.rb",
  :more_menu=>{ :title=>"google_docs", :controller=>"google_docs", :action=>"index", :target_id=>"more-parent" },
  :sub_menus=>[{:title=>"view_all_docs",:controller=>"google_docs",:action=>"index",:target_id=>"fedena_google_doc"},
    {:title=>"upload_document",:controller=>"google_docs",:action=>"upload",:target_id=>"fedena_google_doc"}]
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end
