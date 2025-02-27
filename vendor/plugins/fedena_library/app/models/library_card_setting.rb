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
class LibraryCardSetting < ActiveRecord::Base
  belongs_to :course
  belongs_to :student_category
  validates_presence_of :books_issueable,:time_period,:student_category_id
  validates_numericality_of :time_period,:only_integer =>true, :greater_than =>0, :allow_nil => true
  validates_uniqueness_of :student_category_id, :scope => [:course_id],:case_sensitive => false

end
