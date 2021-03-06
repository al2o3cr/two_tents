class AddAdminUser < ActiveRecord::Migration
  def self.up
    p = Participant.new(:lastname => "administrator", 
                        :firstname => "administrator")
    p.save
    u = User.new(:login => "administrator", 
                 :password => "administrator", 
                 :password_confirmation => "administrator", 
                 :email => "administrator@example.com")
    u.participant = p
    u.save_without_validation!
  end

  def self.down
    User.find(:first, :conditions => {:login => "administrator"}).destroy
    Participant.find(:first, 
                     :conditions => {:lastname => "administrator"}).destroy
  end
end
