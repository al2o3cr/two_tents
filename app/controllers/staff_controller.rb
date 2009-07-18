# This controller handles the login/logout function of the site.  
class StaffController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem

  before_filter :login_required

  def index
  end
end
