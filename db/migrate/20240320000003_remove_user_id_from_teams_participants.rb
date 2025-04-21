# db/migrate/20240320000003_remove_user_id_from_teams_participants.rb
class RemoveUserIdFromTeamsParticipants < ActiveRecord::Migration[6.1]
    def change
      remove_column :teams_participants, :user_id, :integer
    end
  end
  