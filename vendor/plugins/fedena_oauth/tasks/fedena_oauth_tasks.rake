namespace :fedena_oauth do
  desc "Install Fedena Google Oauth"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_oauth/public ."
  end
end
