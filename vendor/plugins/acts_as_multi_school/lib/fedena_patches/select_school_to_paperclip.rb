module FedenaPatches
  module SelectSchoolToPaperclip
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :paperclip_attachment_return, :ms
        end
      end
    end

    module ClassMethods
      def paperclip_attachment_return_with_ms(env)
        request_host=env["HTTP_HOST"]
        domain = SchoolDomain.find_by_domain(request_host)
        @linkable = domain.linkable unless domain.blank?
        if @linkable and domain.linkable_type=="School"
          MultiSchool.current_school= @linkable
          paperclip_attachment_return_without_ms(env)
        else
          [404, {"Content-Type" => "text/html"}, ["Not Found"]]
        end
      end
    end
  end
end