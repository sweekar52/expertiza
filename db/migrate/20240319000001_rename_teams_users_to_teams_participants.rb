# db/migrate/20240319000001_rename_teams_users_to_teams_participants.rb
class RenameTeamsUsersToTeamsParticipants < ActiveRecord::Migration[6.1]
    def change
      rename_table :teams_users, :teams_participants
    end
  end
  