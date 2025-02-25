namespace :fedena_mobile do
  desc "Install Fedena Mobile"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_mobile/public ."
  end
end