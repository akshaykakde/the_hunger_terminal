class Company < ApplicationRecord
  
  validates_with LandlineValidator
  # validates :name, :landline, :email, :address, presence: true
  # validates :start_ordering_at, :review_ordering_at, :end_ordering_at,  presence: true
  validates :name, uniqueness:{case_sensitive: false}
  validates :landline, uniqueness: true
  validates :landline, length: {is: 10}
  validates :name, :address, presence: true
  validate :create_company_admin, on: :create
  validates_format_of :email,:with => Devise.email_regexp
  validates :subsidy, inclusion: { in: 0..100, message: "value must be between 0 to 100" }
  # validates :start_ordering_at, :review_ordering_at, :end_ordering_at, :subsidy,  presence: true

  has_one :address,  as: :location, dependent: :destroy
  has_many :employees , class_name: "User", dependent: :destroy
  has_many :terminals, dependent: :destroy
  has_many :orders, dependent: :destroy

  accepts_nested_attributes_for :address, :employees

  before_validation :remove_space
  
  private 
    def remove_space
      #squish method is not for nil classes
      if(self.name == nil)
        return
      end
      self.name = name.squish
    end

    def create_company_admin
      self.employees.first.role = "company_admin"
      self.employees.first.is_active = true
    end
end
