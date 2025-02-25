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
#
#under the License.
# FedenaLibrary
require 'dispatcher'
module FedenaLibrary
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_library do
      ::Student.instance_eval { has_many :book_movements, :through=>:user }
      ::Student.instance_eval { has_many :book_reservations, :through=>:user }
      ::Employee.instance_eval { has_many :book_movements, :through=>:user }
      ::Employee.instance_eval { has_many :book_reservations, :through=>:user }
      ::Employee.instance_eval { before_destroy :clear_book_movements }
      ::Student.instance_eval { include FedenaLibraryBookMovement }
      ::Student.instance_eval { before_destroy :clear_book_movements }
      ::Employee.instance_eval { include FedenaLibraryBookMovement }
      ::User.instance_eval { include UserExtension }
      ::Student.instance_eval { include StudentExtension }
    end
  end

  def self.dependency_delete(student)
    user_id = student.user.id
    BookMovement.destroy_all(:user_id => user_id)
    BookReservation.destroy_all(:user_id => user_id)
  end
  #  def self.student_profile_hook #library card is not used anymore in fedena.
  #    "shared/student_profile"
  #  end

  def self.student_dependency_hook
    "shared/student_dependency"
  end

  def self.employee_dependency_hook
    "shared/employee_dependency"
  end
  
  def self.dependency_check(record,type)
    if record.class.to_s == "Student" or record.class.to_s == "Employee"
      return true if record.book_movements.all(:conditions=>"status = 'Renewed' or status = 'Issued' ").present?
    end
    return false
  end


  module FedenaLibraryBookMovement
    def issued_books
      self.book_movements.all(:conditions=>"status = 'Issued' or status = 'Renewed'")
    end
    def  clear_book_movements
      self.book_reservations.destroy_all
    end
  end

  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :book_movements, :dependent=>:destroy
        has_many :book_reservations, :dependent=>:destroy
        before_destroy :clear_book_movements
      end
    end
      
    def  clear_book_movements
      self.book_movements.destroy_all
      self.book_reservations.destroy_all
    end
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_library_dependency, :student, :warning_message => :library_activity_present ) do
          self.library_dependencies
        end
      end
    end

    def library_dependencies
      return false if self.book_movements.all(:conditions=>"status = 'Renewed' or status = 'Issued' ").present?
      return true
    end
  end
end

