# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaMobile
  module MobileApplication

    def self.included(base)
      base.instance_eval do
        layout :what_layout
      end
    end

    private

    def what_layout
      select_layout
      return 'mobile'  if @ret==true
      'application'
    end

    def select_layout
      user_agents=["android","ipod","opera mini","blackberry","palm","hiptop","avantgo","plucker", "xiino","blazer","elaine", "windows ce; ppc;", "windows ce; smartphone;","windows ce; iemobile", "up.browser","up.link","mmp","symbian","smartphone", "midp","wap","vodafone","o2","pocket","kindle", "mobile","pda","psp","treo"]
      @ret=false
      if FedenaPlugin.can_access_plugin?("fedena_mobile")
        user_agents.each do |ua|
          if request.env["HTTP_USER_AGENT"].downcase=~ /#{ua}/i
            @ret=true
            return
          end
        end
      end
    end
  end
end
