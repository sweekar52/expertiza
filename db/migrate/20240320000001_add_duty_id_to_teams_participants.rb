class AddDutyIdToTeamsParticipants < ActiveRecord::Migration[5.1]
  def change
    add_column :teams_participants, :duty_id, :integer
    add_foreign_key :teams_participants, :duties
    add_index :teams_participants, :duty_id
  end
end 