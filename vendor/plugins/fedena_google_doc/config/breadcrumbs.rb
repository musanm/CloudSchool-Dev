Gretel::Crumbs.layout do
  crumb :google_docs_index do
    link I18n.t('google_docs'), {:controller=>"google_docs",:action=>"index"}
  end

  crumb :google_docs_upload do
    link I18n.t('upload_document'), {:controller=>"google_docs",:action=>"upload"}
    parent :google_docs_index
  end
  
end