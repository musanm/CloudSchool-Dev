Gretel::Crumbs.layout do

  crumb :galleries_index do
    link I18n.t('galleries.gallery'), {:controller=>"galleries",:action=>"index"}
  end

   crumb :galleries_photo_add do
    link I18n.t('galleries.add_photo'), {:controller=>"galleries",:action=>"photo_add"}
    parent :galleries_index
  end

   crumb :galleries_photo_create do
    link I18n.t('galleries.add_photo'), {:controller=>"galleries",:action=>"photo_create"}
    parent :galleries_index
  end

  crumb :galleries_category_new do
    link I18n.t('galleries.add_category'), {:controller=>"galleries",:action=>"category_new"}
    parent :galleries_index
  end

  crumb :galleries_category_create do
    link I18n.t('galleries.add_category'), {:controller=>"galleries",:action=>"category_create"}
    parent :galleries_index
  end

  crumb :galleries_category_show do |category|
    link category.name_was, {:controller=>"galleries",:action=>"category_show",:id=>category.id}
    parent :galleries_index
  end

  crumb :galleries_category_edit do |category|
    link I18n.t('galleries.edit_category'), {:controller=>"galleries",:action=>"category_edit",:id=>category.id}
    parent :galleries_category_show,category
  end

  crumb :galleries_category_update do |category|
    link I18n.t('galleries.edit_category'), {:controller=>"galleries",:action=>"category_update",:id=>category.id}
    parent :galleries_category_show,category
  end

  crumb :galleries_add_photo do |category|
    link I18n.t('galleries.add_photo'), {:controller=>"galleries",:action=>"add_photo",:id=>category.id}
    parent :galleries_category_show,category
  end

  crumb :galleries_edit_photo do |list|
    link I18n.t('galleries.edit_photo'), {:controller=>"galleries",:action=>"edit_photo",:id=>list.first.id}
    parent :galleries_category_show,list.last
  end
end