class TeamsParticipantsController < ApplicationController
  include AuthorizationHelper

  def action_allowed?
    # Allow duty updation for a team if current user is student, else require TA or above privileges.
    if %w[update_duties].include?(params[:action])
      current_user_has_student_privileges?
    else
      current_user_has_ta_privileges?
    end
  end

  def auto_complete_for_user_name
    team = Team.find(session[:team_id])
    @users = team.get_possible_team_members(params[:user][:name])
    render inline: "<%= auto_complete_result @users, 'name' %>", layout: false
  end

  # Example: update duties for a participant (e.g., manager, designer, programmer, tester)
  def update_duties
    teams_participant = TeamsParticipant.find(params[:teams_participant_id])
    teams_participant.update_attribute(:duty_id, params[:teams_participant]['duty_id'])
    redirect_to controller: 'student_teams', action: 'view', student_id: params[:participant_id]
  end

  def list
    @team = Team.find(params[:id])
    @assignment = Assignment.find(@team.parent_id)
    @teams_participants = TeamsParticipant.page(params[:page]).per_page(10).where(team_id: params[:id])
  end

  def new
    @team = Team.find(params[:id])
  end

  def create
    user = User.find_by(name: params[:user][:name].strip)
    unless user
      url_create = url_for(controller: 'users', action: 'new')
      flash[:error] = "\"#{params[:user][:name].strip}\" is not defined. Please <a href=\"#{url_create}\">create</a> this user before continuing."
      redirect_back fallback_location: root_path
      return
    end

    team = Team.find(params[:id])
    if team.is_a?(AssignmentTeam)
      assignment = Assignment.find(team.parent_id)
      if assignment.user_on_team?(user)
        flash[:error] = "This user is already assigned to a team for this assignment"
        redirect_back fallback_location: root_path
        return
      end
      if AssignmentParticipant.find_by(user_id: user.id, parent_id: assignment.id).nil?
        url_assignment_participant_list = url_for(controller: 'participants', action: 'list', id: assignment.id, model: 'Assignment', authorization: 'participant')
        flash[:error] = "\"#{user.name}\" is not a participant of the current assignment. Please <a href=\"#{url_assignment_participant_list}\">add</a> this user before continuing."
      else
        begin
          add_member_return = team.add_member(user, team.parent_id)
        rescue ActiveRecord::RecordInvalid => e
          flash[:error] = "The user #{user.name} is already a member of the team #{team.name}"
          redirect_back fallback_location: root_path
          return
        rescue => e
          flash[:error] = "An error occurred: #{e.message}"
          redirect_back fallback_location: root_path
          return
        end
        flash[:error] = 'This team already has the maximum number of members.' if add_member_return == false
      end
    else # CourseTeam
      course = Course.find(team.parent_id)
      if course.user_on_team?(user)
        flash[:error] = "This user is already assigned to a team for this course"
        redirect_back fallback_location: root_path
        return
      end
      if CourseParticipant.find_by(user_id: user.id, parent_id: course.id).nil?
        url_course_participant_list = url_for(controller: 'participants', action: 'list', id: course.id, model: 'Course', authorization: 'participant')
        flash[:error] = "\"#{user.name}\" is not a participant of the current course. Please <a href=\"#{url_course_participant_list}\">add</a> this user before continuing."
      else
        begin
          add_member_return = team.add_member(user, team.parent_id)
        rescue ActiveRecord::RecordInvalid => e
          flash[:error] = "The user #{user.name} is already a member of the team #{team.name}"
          redirect_back fallback_location: root_path
          return
        rescue => e
          flash[:error] = "An error occurred: #{e.message}"
          redirect_back fallback_location: root_path
          return
        end
        flash[:error] = 'This team already has the maximum number of members.' if add_member_return == false
        if add_member_return
          @teams_participant = TeamsParticipant.last
          undo_link("The team participant \"#{user.name}\" has been successfully added to \"#{team.name}\".")
        end
      end
    end

    redirect_to controller: 'teams', action: 'list', id: team.parent_id
  end

  def delete
    unless params[:id].present?
      flash[:error] = "No team participant specified for deletion."
      redirect_back fallback_location: root_path and return
    end

    teams_participant = TeamsParticipant.find(params[:id])
    parent_id = Team.find(teams_participant.team_id).parent_id
    user = teams_participant.participant
    teams_participant.destroy
    undo_link("The team participant \"#{user.name}\" has been successfully removed.")
    redirect_to controller: 'teams', action: 'list', id: parent_id
  end

  def delete_selected
    unless params[:item].present?
      flash[:error] = "No team participants selected for deletion."
      redirect_back fallback_location: root_path and return
    end

    params[:item].each do |item_id|
      participant = TeamsParticipant.find_by(id: item_id)
      participant&.destroy
    end

    redirect_to action: 'list', id: params[:id]
  end
end
