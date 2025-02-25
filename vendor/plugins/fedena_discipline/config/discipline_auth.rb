authorization do

  role :admin do
    includes :discipline
  end
  role :employee do
    includes :discipline_view
  end
  role :student do
    includes :discipline_view
  end
  role :parent do
    includes :discipline_view
  end
  role :discipline do
     has_permission_on [:discipline_complaints],
      :to => [
      :index,
      :new,
      :edit,
      :create,
      :update,
      :download_attachment,
      :delete_attachment,
      :search_complaint_ajax,
      :show,
      :reply,
      :decision,
      :decision_remove,
      :decision_close,
      :destroy,
      :search_complainee,
      :search_accused,
      :search_juries,
      :search_users,
      :create_comment,
      :destroy_comment,
      :list_comments
    ]
  end
  role :discipline_view do
    has_permission_on [:discipline_complaints],
      :to => [
      :index,
      :search_complaint_ajax,
      :reply,
      :create_comment,
      :destroy_comment,
      :decision,
      :decision_remove,
      :decision_close,
      :list_comments
      ]
      has_permission_on :discipline_complaints, :to=>[:show,:download_attachment], :join_by=> :or do
        if_attribute :discipline_participation_user_ids=> contains {user.id}
        if_attribute :discipline_participation_user_ids=> contains {user.parent_record.user_id if user.parent and user.parent_record}
      end
  end
end
