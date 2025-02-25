#Copyright 2010 Foradian Technologies Private Limited
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.
class BooksController < ApplicationController
  before_filter :login_required
  before_filter :check_book_status, :only =>[ :edit , :update ]
  filter_access_to :all

  def index
    @books = Book.paginate(:page => params[:page],:include=>:tags)
    @count = @books.total_entries
  end

  def new
    @tagg = []
    @book = Book.find(:last)
    @book_number = @book.book_number.next unless @book.nil?
    unless params[:author].nil?
      @book_title = params[:title]
      @author = params[:author]
      @detail = Book.find_by_author_and_title(@author, @book_title)
      @tagg = @detail.tag_list
    else
      @book_title = ''
      @author = ''
    end
    @book = Book.new
    @tags = Tag.find(:all)
  end

  def list_barcode_field
    p params[:create_type]
    if params[:create_type]=="barcode"
      render :update do |page|
        page.replace_html 'barcode_field' , :partial=>'list_barcode_field'
        page.replace_html 'count_area', ''
      end
    else
      render :update do |page|
        page.replace_html 'barcode_field' , ''
        page.replace_html 'count_area', :partial=>'list_count_field'
      end
    end
  end

  def create   
    @tagg = []
    @book = Book.find(:last)
    @book_number = @book.book_number.next unless @book.nil?
    @book_number = params[:book][:book_number] unless params[:book][:book_number].nil?
    unless params[:author].nil?
      @book_title = params[:title]
      @author = params[:author]
      @detail = Book.find_by_author_and_title(@author, @book_title)
      @tagg = @detail.tag_list
    else
      @book_title = ''
      @author = ''
    end
    @book = Book.new
    @tags = Tag.find(:all)
    @book = Book.new(params[:book])
    @created_books = Array.new
    @count = params[:tag][:count].to_i
    @custom_tags = params[:tag][:list]
    tags = @custom_tags.split(',')
    unless params[:tag][:count] == ""
      saved = 0
      temp_book_number = params[:book][:book_number]
      tags << params[:book][:tag_list]
      @count.times do |c|
        book_number = temp_book_number
        if @book = Book.create(:title=> params[:book][:title], :author=> params[:book][:author], :tag_list =>tags, :book_number =>book_number, :status=>'Available',:barcode=>params[:book][:barcode],:book_add_type=>params[:book][:book_add_type])
          unless @book.id.nil?
            saved += 1
            Book.update(@book.id, :tag_list => tags)
            temp_book_number = temp_book_number.next
            @created_books = @created_books.push @book.id
          end
        end
      end
      if  saved == @count
        flash[:notice]="#{t('flash1')}"
        redirect_to additional_data_books_path(:id => @created_books)
      else
        @book_barcode=params[:book][:barcode]
        @book_add_type=params[:book][:book_add_type]
        render 'new'
      end
    else
      @book.errors.add_to_base("#{t('flash5')}")
      render 'new'
    end
  end

  def edit
    @book = Book.find(params[:id])
    @tags = Tag.find(:all)
  end

  def update
    @book = Book.find(params[:id])
    @tags = Tag.all
    @custom_tags = params[:tag][:list]
    tags = @custom_tags.split(',')
    params[:book][:tag_list]=[] if params[:book][:tag_list].blank?
    params[:book][:tag_list] << tags unless tags.blank?
    if @book.update_attributes(params[:book])
      flash[:notice]="#{t('flash2')}"
      redirect_to edit_additional_data_books_path(:id => @book.id)
    else
      render 'edit'
    end
  end

  def manage_barcode
    if request.post?
      if params[:search][:search_by] == 'tag'
        @books=Book.find_tagged_with(params[:search][:name]) if params[:search][:name].length>=3
      elsif params[:search][:search_by] == 'title'
        @books=Book.find(:all,:conditions=>['books.title LIKE ?',"%#{params[:search][:name]}%"]) if params[:search][:name].length>=3
      elsif params[:search][:search_by] == 'author'
        @books=Book.find(:all,:conditions=>['books.author LIKE ?',"%#{params[:search][:name]}%"]) if params[:search][:name].length>=3
      else
        if params[:search][:name].length>=3
          @books = Book.find(:all,:conditions=>['books.book_number LIKE ?',"%#{params[:search][:name]}%"],:limit=>200)
        else
          @books = Book.find(:all,:conditions=>['books.book_number LIKE ?',"#{params[:search][:name]}"])
        end
      end
      render :update do |page|
        page.replace_html 'book-list', :partial => 'barcode_manage'
      end
    end
  end

  def update_barcode
    @book_errors = []
    @book_current_value= []
    params[:book].each_pair do|k,val|
      @books_to_update=Book.find(k)
      unless @books_to_update.barcode==val["barcode"]
        unless @books_to_update.update_attributes(val)
          @book_errors.push(k)
          @book_current_value[k.to_i]=val["barcode"]
        end
      end
    end
    if @book_errors.empty?
      render :update do |page|
        page.replace_html 'book-list', :text=>"<p class='flash-msg'>#{t('books.books_updated')}<p>"
      end
    else
      @books = Book.find_all_by_id(params[:book_ids].split(","))
      render :update do |page|
        page.replace_html 'book-list', :partial=>"barcode_manage"
      end
    end
  end

  def additional_data
    @book = Book.new
    @books = Book.find_all_by_id(params[:id])
    @additional_fields = BookAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC")
    if @additional_fields.empty?
      flash[:notice] = "Books created successfully."
      redirect_to books_path and return
    end
    if request.post?
      @books.each do |book|
        @error=false
        @book_additional_details = BookAdditionalDetail.find_all_by_book_id(book.id)
        mandatory_fields = BookAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :is_active=>true})
        mandatory_fields.each do|m|
          unless params[:book_additional_details][m.id.to_s.to_sym].present?
            @book.errors.add_to_base("#{m.name} must contain atleast one selected option.")
            @error=true
          else
            if params[:book_additional_details][m.id.to_s.to_sym][:additional_info]==""
              @book.errors.add_to_base("#{m.name} cannot be blank.")
              @error=true
            end
          end
        end
        unless @error==true
          params[:book_additional_details].each_pair do |k, v|
            addl_info = v['additional_info']
            addl_field = BookAdditionalField.find_by_id(k)
            if addl_field.input_type == "has_many"
              addl_info = addl_info.join(", ")
            end
            prev_record = BookAdditionalDetail.find_by_book_id_and_book_additional_field_id(book.id, k)
            unless prev_record.nil?
              unless addl_info.present?
                prev_record.destroy
              else
                prev_record.update_attributes(:additional_info => addl_info)
              end
            else
              addl_detail = BookAdditionalDetail.new(:book_id => book.id,
                :book_additional_field_id => k,:additional_info => addl_info)
              addl_detail.save if addl_detail.valid?
            end
          end
        else
          render :additional_data and return
        end
      end
      flash[:notice] = "Book saved with additional data successfully"
      redirect_to books_path
    end
  end

  def edit_additional_data
    @book = Book.find(params[:id])
    @additional_fields = BookAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC")
    @book_additional_details = BookAdditionalDetail.find_all_by_book_id(@book.id)
    if @additional_fields.blank?
      flash[:notice] = t('book_updated')
      redirect_to @book
    end
    if request.post?
      @error=false
      mandatory_fields = BookAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :is_active=>true})
      mandatory_fields.each do|m|
        unless params[:book_additional_details][m.id.to_s.to_sym].present?
          @book.errors.add_to_base("#{m.name} must contain atleast one selected option.")
          @error=true
        else
          if params[:book_additional_details][m.id.to_s.to_sym][:additional_info]==""
            @book.errors.add_to_base("#{m.name} cannot be blank.")
            @error=true
          end
        end
      end
      unless @error==true
        params[:book_additional_details].each_pair do |k, v|
          addl_info = v['additional_info']
          addl_field = BookAdditionalField.find_by_id(k)
          if addl_field.input_type == "has_many"
            if addl_info.reject(&:empty?).empty?
              addl_info=nil
            else
              addl_info = addl_info.reject(&:empty?).join(", ")
            end
          end
          prev_record = BookAdditionalDetail.find_by_book_id_and_book_additional_field_id(@book.id, k)
          unless prev_record.nil?
            unless addl_info.present?
              prev_record.destroy
            else
              prev_record.update_attributes(:additional_info => addl_info)
            end
          else
            addl_detail = BookAdditionalDetail.new(:book_id => @book.id,
              :book_additional_field_id => k,:additional_info => addl_info)
            addl_detail.save if addl_detail.valid?
          end
        end
      else
        render :edit_additional_data and return
      end

      flash[:notice] = "Book saved with additional data successfully"
      redirect_to books_path
    end
  end

  def show
    @book = Book.find(params[:id])
    @lender = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @lender ||= ArchivedStudent.first(:conditions => ["admission_no LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @lender ||= Employee.first(:conditions => ["employee_number LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @lender ||= ArchivedEmployee.first(:conditions => ["employee_number LIKE BINARY(?)",@book.book_movement.user.username]) unless @book.book_movement_id.nil?
    @reservations = BookReservation.find_all_by_book_id(@book.id)
    @book_reserved = BookReservation.find_by_book_id(@book.id)
    @additional_details = BookAdditionalDetail.find_all_by_book_id(@book.id)
  end

  def destroy
    @book = Book.find(params[:id])
    if @book.book_movement_id.nil? #or @book.status=='Lost'
      @book.destroy
      flash[:notice] ="#{t('flash3')}"
    else
      flash[:warn_notice] ="#{t('flash4')}"
    end
    redirect_to books_path
  end

  def sort_by
    sort = params[:sort][:on]
    @books = Book.search(:status_like=>"#{sort}").paginate(:all,:page=>params[:page],:include=>:tags)
    @count = @books.total_entries
    render(:update) do |page|
      page.replace_html 'books', :partial=>'books'
    end
  end

  def add_additional_details
    @all_details = BookAdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = BookAdditionalField.new
    @book_additional_field_option = @additional_field.book_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = BookAdditionalField.new(params[:book_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "Additional field added successfully"
        redirect_to :controller => "books", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = BookAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = BookAdditionalField.find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = BookAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = BookAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = BookAdditionalField.new
    @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = BookAdditionalField.find(params[:id])
    @book_additional_field_option = @additional_field.book_additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:book_additional_field])
        flash[:notice] = "Additional field updated successfully"
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    books = BookAdditionalDetail.find(:all ,:conditions=>"book_additional_field_id = #{params[:id]}")
    if books.blank?
      BookAdditionalField.find(params[:id]).destroy
      @additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
      @inactive_additional_details = BookAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
      flash[:notice]="Additional field deleted successfully"
      redirect_to :action => "add_additional_details"
    else
      flash[:notice]="Additional field is in use and cannot be deleted"
      redirect_to :action => "add_additional_details"
    end
  end
  
  def library_transactions
    @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:conditions=>["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}' and finance_type='BookMovement'"],:order=>'created_at desc')
  end

  def search_library_transactions
    @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:joins=>'LEFT OUTER JOIN students ON students.id = payee_id',:conditions => ["(students.admission_no LIKE ? OR students.first_name LIKE ?) and finance_type=?",
        "#{params[:query]}%","#{params[:query]}%",'BookMovement'],:order=>'created_at desc')  unless params[:query] == ''
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial => "books/search_library_transactions"
    end
    #render :partial => "books/search_library_transactions"
  end

  def library_transaction_filter_by_date
    @start_date=params[:s_date]
    @end_date=params[:e_date]
    @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:joins=>'LEFT OUTER JOIN students ON students.id = payee_id',:conditions=>["(finance_transactions.created_at >='#{@start_date}' and finance_transactions.created_at <'#{@end_date.to_date+1.day}') and (finance_type='BookMovement' and payee_id=students.id)"],:order=>'created_at desc')
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial => "books/library_transactions_date_filter"
    end
  end
  #render :partial => "books/library_transactions"
  def delete_library_transaction
    @financetransaction=FinanceTransaction.find(params[:id])
    if @financetransaction
      @financetransaction.destroy
    end
    if params[:s_date].present?
      @start_date=params[:s_date]
      @end_date=params[:e_date]
      @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:joins=>'LEFT OUTER JOIN students ON students.id = payee_id',:conditions=>["(finance_transactions.created_at >='#{@start_date}' and finance_transactions.created_at <='#{@end_date}') and (finance_type='BookMovement' and payee_id=students.id)"],:order=>'created_at desc')
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "books/library_transactions_date_filter"
      end
    elsif params[:query].present?
      @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:joins=>'LEFT OUTER JOIN students ON students.id = payee_id',:conditions => ["(students.admission_no LIKE ? OR students.first_name LIKE ?) and finance_type=?",
          "#{params[:query]}%","#{params[:query]}%",'BookMovement'],:order=>'created_at desc')  unless params[:query] == ''
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "books/search_library_transactions"
      end
    else
      @transactions=FinanceTransaction.paginate(:per_page=>20,:page=>params[:page],:conditions=>["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}' and finance_type='BookMovement'"],:order=>'created_at desc')
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "books/library_transactions"
      end
    end
  end
  private

  def check_book_status
    @book = Book.find(params[:id])
    redirect_to :action => :show , :id => @book.id  if @book.status == 'Borrowed'
  end

end
