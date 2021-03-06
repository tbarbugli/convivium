require 'digest/sha1'

class User < ActiveRecord::Base
  
  # ---------------------------------------
  # The following code has been generated by role_requirement.
  # You may wish to modify it to suit your need
  has_and_belongs_to_many :roles
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    return true if @_list.include?("admin")
    (@_list.include?(role_in_question.to_s) )
  end
  # ---------------------------------------
  
  
  
  
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken


  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  # TODO handle destroy on users (what about related expenses and cats and bla blabla ?)
  
  has_many :expenses, :foreign_key=>:creator_id
  has_many :categories, :foreign_key=>:creator_id
  has_and_belongs_to_many :expensegroups 
  
  after_save do |user| 
    Expensegroup.create( :name=>user.login + " personal expense", :users=>[ user ], :personal=>user ) 
    user.roles << Role.find_by_name("admin")  # OK we need to know that admin role exists!!!!
  end   
  
  # TODO handle after_destroy, what about alla datas collected ?

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation



  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def is_owner?(id,model)
    object = model.find id
    if object.methods.include? 'creator'
      if object.creator == self
        true
      else
        false
      end
    end
  end

  protected         
    
end
