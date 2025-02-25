
Paperclip.interpolates :timestamp do |attachment,style|
  attachment_update_at = attachment.name.to_s + "_updated_at"
  attachment.instance.send(attachment_update_at).present? ? attachment.instance.send(attachment_update_at).strftime('%Y%m%d%H%m%S') : nil
end
Paperclip.interpolates :attachment_fullname do |attachment,style|
  file_name=attachment.name.to_s + "_file_name"
  CGI::escape(attachment.instance.send(file_name))
end
if  FedenaSetting.s3_enabled?
  require 'aws/s3'
  require 'aws_extension'
  require 'cloudfront_signer'

  {
    :storage=>:s3,
    :s3_credentials=>{
      :bucket => Config.bucket_private,
      :access_key_id =>  Config.access_key_id,
      :secret_access_key => Config.secret_access_key
    },
    :s3_host_alias=>Config.cloudfront_private,
    :url => ':s3_alias_url',
    :s3_permissions=>:private

  }.each do |k,v|
    Paperclip::Attachment.default_options.merge! k=>v
  end

  AWS::CF::Signer.configure do |config|
    config.key_path = FedenaSetting::S3.cloudfront_signing_key_path
    config.key_pair_id  = FedenaSetting::S3.cloudfront_signing_key_pair_id
    config.default_expires = 3600
  end

  Paperclip.interpolates(:s3_alias_url) do |attachment, style|
    #    timestamp=attachment.instance.updated_at.present? ? attachment.instance.updated_at.strftime('%Y%m%d%H%m%S') : nil
#    url ="#{attachment.s3_protocol}://#{attachment.s3_host_alias}/#{attachment.path(style).gsub(%r{^/}, "")}"
    url ="#{attachment.s3_protocol}://#{attachment.s3_host_alias}/#{URI.encode(attachment.path(style)).gsub('+','%2B').gsub(%r{^/}, "")}"
    AWS::CF::Signer.sign_url(url)
  end unless Paperclip::Interpolations.respond_to? :s3_alias_url

  ActiveRecord::Base.instance_eval do
    def has_attached_file name, options = {}
      super name, options
      attachment_definitions[name][:url] = ":s3_alias_url"
      attachment_definitions[name][:path] = options[:path].gsub(':basename', ':timestamp/:basename')
    end
  end
end
