class CreateApplicantGuardians < ActiveRecord::Migration
  def self.up
    create_table :applicant_guardians do |t|
      t.integer :school_id
      t.references :applicant
      t.string     :first_name
      t.string     :last_name
      t.string     :relation

      t.string     :email
      t.string     :office_phone1
      t.string     :office_phone2
      t.string     :mobile_phone

      t.string     :office_address_line1
      t.string     :office_address_line2
      t.string     :city
      t.string     :state
      t.references :country

      t.date       :dob
      t.string     :occupation
      t.string     :income
      t.string     :education
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_guardians
  end
end
