p = Palette.find_by_name("book_return_due")
if p.present?
  p.palette_queries.destroy_all


  p.instance_eval do
    user_roles [:admin,:employee,:student] do
      with do
        all(:conditions=>["user_id = ? AND due_date = ? AND (status='Issued' OR status='Renewed')",later(%Q{Authorization.current_user.id}),:cr_date],:limit=>:lim,:offset=>:off)
      end
    end
    user_roles [:parent] do
      with do
        all(:conditions=>["user_id = ? AND due_date = ? AND (status='Issued' OR status='Renewed')",later(%Q{Authorization.current_user.guardian_entry.current_ward.user_id}),:cr_date],:limit=>:lim,:offset=>:off)
      end
    end
  end

  p.save
end
