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
class Book < ActiveRecord::Base
  acts_as_taggable
  belongs_to :book_movement
  has_many :book_reservations, :dependent => :destroy
  has_many :book_additional_details, :dependent => :destroy
  validates_presence_of :book_number, :title, :author
  validates_uniqueness_of :book_number
  validates_uniqueness_of :barcode,:allow_blank => true
  before_destroy :delete_dependency
  attr_accessor :book_query
  named_scope :borrowed, :conditions => { :status => "Borrowed" }
  named_scope :available, :conditions => ["status=? or status= ?","Available","Reserved"]

  cattr_reader :per_page
  attr_accessor :book_add_type

  @@per_page = 25

  def validate
    if self.tag_list.present?
      t = self.tag_list
      t.each do|tag|
        if (tag.length > 30)
          self.errors.add_to_base(:custom_tag_tool_long)
          return false
        end
      end
    end
    
    if self.book_add_type =="barcode"
      self.errors.add_to_base(:barcode_is_needed) unless self.barcode.present?
      return false
    end
  end

  def get_student_id
    return Student.first(:conditions => ["admission_no LIKE BINARY(?)",self.book_movement.user.username]).id
  end

  def get_employee_id
    return  Employee.first(:conditions => ["employee_number LIKE BINARY(?)",self.book_movement.user.username]).id
  end

  def delete_dependency
    movements = BookMovement.find_all_by_book_id(self.id)
    BookMovement.destroy_all(:id => movements.map(&:id))
  end

end
