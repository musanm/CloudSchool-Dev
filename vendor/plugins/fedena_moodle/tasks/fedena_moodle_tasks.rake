namespace :fedena_moodle do
  desc "Install Fedena Moodle Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_moodle/public ."
  end
end
