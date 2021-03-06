class ParticipantsController < ApplicationController
  before_filter :login_required
  
  # GET /participants
  # GET /participants.xml
  def index
    @participants = Participant.paginate :all, :page => params[:page], :order => "lastname ASC, firstname ASC"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @participants }
    end
  end

  # GET /participants/1
  # GET /participants/1.xml
  def show
    @participants = Participant.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @participants }
    end
  end

  # GET /participants/new
  # GET /participants/new.xml
  def new
    @participant = Participant.new 
  end

  def new_from_user
    @participant = Participant.new
    
  end

  # GET /participants/1/edit
  def edit
    @participant = Participant.find(params[:id])
  end

  def create_from_user
    @family = Family.find(params[:participant][:family]) rescue nil
   # params[:participant][:family] = @family
    @participant = Participant.new(params[:participant])

    respond_to do |format|
      if @participant.save
        AuditTrail.audit("Participant #{@participant.fullname} created by #{current_user.login}", participant_url(@participant))
        flash[:notice] = "Participant #{@participant.fullname} was successfully created."
        format.html { redirect_to new_user_path(:participant => @participant) }
        puts "DBG redirecting to #{new_user_path(:participant => @participant)}"
        format.xml  { render :xml => @participant, :status => :created, :location => @participant }
      else
        puts "DBG new"
        format.html { render :action => "new" }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  rescue Exception => e
    logger.error "ERROR creating from user"
    logger.error e.backtrace.join("\n\t")
    raise e    
  end

  # POST /participants
  # POST /participants.xml
  def create
    @family = Family.find(params[:participant][:family]) rescue nil
    params[:participant][:family] = @family
    @participant = Participant.new(params[:participant])

    respond_to do |format|
      if @participant.save
        AuditTrail.audit("Participant #{@participant.fullname} created by #{current_user.login}", edit_participant_url(@participant))
        flash[:notice] = "Participant #{@participant.fullname} was successfully created."
        format.html { redirect_to new_user_path(:participant => @participant) }
      else
        msg = @participant.errors.join(", ")
        logger.error msg
        puts msg
        flash[:error] = msg
        format.html { render :action => "new" }
        format.xml  { render :xml => @participant.errors, :status => :unprocessable_entity }
      end
    end
  rescue Exception => e
    logger.error "ERROR creating family \n#{@family.inspect} \n participant \n #{@participant.inspect}"
    logger.error e.backtrace.join("\n\t")
    raise e
  end

  # PUT /participants/1
  # PUT /participants/1.xml
  def update
    @participants = Participant.find(params[:id])

    respond_to do |format|
      if @participants.update_attributes(params[:participant])
        AuditTrail.audit("Participant #{@participants.fullname} updated by #{current_user.login}", edit_participant_url(@participants))
        flash[:notice] = 'Participants was successfully updated.'
        format.html { redirect_to(participants_url) }
        format.xml  { head :ok }
        format.js   do
          flash.discard
          render(:update) do |page|
            element = "#{@participants.class}_#{@participants.id}_#{params[:participant].keys[0]}"
            page.replace_html(element,
                              :partial => 'flipflop',
                              :locals => {:p => @participants,
                                :type => params[:participant].keys[0] } )
          end
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @participants.errors, :status => :unprocessable_entity }
      end
    end
  rescue Exception => e
    logger.error "ERROR updating family \n#{@family.inspect} \n participant \n #{@participant.inspect}"
    logger.error e.backtrace.join("\n\t")
    raise e
  end

  # DELETE /participants/1
  # DELETE /participants/1.xml
  def destroy
    begin
      @participant_to_delete = Participant.find(params[:id])
      @family_to_delete = @participant_to_delete.family if @participant_to_delete.only_member_of_associated_family?

      # TODO look into whether this can be done in a validation, given that we only delete family if participant is only member.
      Participant.transaction do
        errors = []
        participant_deleted = @participant_to_delete.destroy
        family_deleted = nil
        if participant_deleted
          AuditTrail.audit("Participant #{@participant_to_delete.fullname} removed by #{current_user.login}")
          flash[:success] = "Participant #{@participant_to_delete.fullname} deleted"
          if @family_to_delete
            family_name = @family_to_delete.familyname
            family_deleted = @family_to_delete.destroy
            if family_deleted
              AuditTrail.audit(
                      "Family #{family_name} removed by #{current_user.login} while deleting last family member #{@participant_to_delete.fullname}")
              flash[:success] << ", and family #{family_name} also deleted"
            else
              errors << @family_to_delete.errors.full_messages if @family_to_delete.errors
            end
          end
        else
          errors << @participant_to_delete.errors.full_messages if @participant_to_delete.errors
        end
        if not errors.blank?
          flash[:error] = errors
          logger.error errors.join("\n\t")
        end
      end
    rescue Exception => e
      flash[:error] = "Error deleting #{@participant_to_delete.fullname}: #{e.to_s}"
      logger.error "Error deleting #{@participant_to_delete.fullname}"
      logger.error e.backtrace.join("\n\t")
    end
    respond_to do |format|
      format.html { redirect_to(participants_url) }
      format.xml  { head :ok }
    end
  end
end
