require 'rails_helper'

RSpec.describe TeamsParticipant, type: :model do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }
  let(:participant) { create(:participant, parent_id: assignment.id) }
  let(:duty) { create(:duty) }
  let(:teams_participant) { build(:teams_participant, team: team, participant: participant, duty: duty) }

  describe 'associations' do
    it { should belong_to(:team) }
    it { should belong_to(:participant) }
    it { should belong_to(:duty).optional }
  end

  describe 'validations' do
    let(:team) { create(:assignment_team, parent_id: assignment.id) }
    let(:participant) { create(:participant, parent_id: assignment.id) }
    let(:existing_teams_participant) { create(:teams_participant, team: team, participant: participant) }
    
    it { should validate_presence_of(:team_id) }
    it { should validate_presence_of(:participant_id) }
    
    it 'validates uniqueness of participant_id scoped to team_id' do
      subject = build(:teams_participant, team: team, participant: participant)
      expect(subject).to validate_uniqueness_of(:participant_id)
        .scoped_to(:team_id)
        .with_message("is already a member of this team")
    end
  end

  describe '.team_id' do
    let(:assignment) { create(:assignment) }
    let(:participant) { create(:participant, parent_id: assignment.id) }
    let(:team) { create(:assignment_team, parent_id: assignment.id) }
    let!(:teams_participant) { create(:teams_participant, team: team, participant: participant) }

    it 'returns team_id for a participant in an assignment' do
      expect(TeamsParticipant.team_id(assignment.id, participant.user_id)).to eq(team.id)
    end

    it 'returns nil if participant is not found' do
      expect(TeamsParticipant.team_id(assignment.id, 999)).to be_nil
    end

    it 'returns nil if teams_participant is not found' do
      other_participant = create(:participant, parent_id: assignment.id)
      expect(TeamsParticipant.team_id(assignment.id, other_participant.user_id)).to be_nil
    end
  end

  describe '.team_empty?' do
    let(:assignment) { create(:assignment) }
    let(:team) { create(:assignment_team, parent_id: assignment.id) }

    it 'returns true if team has no participants' do
      expect(TeamsParticipant.team_empty?(team.id)).to be true
    end

    it 'returns false if team has participants' do
      create(:teams_participant, team: team)
      expect(TeamsParticipant.team_empty?(team.id)).to be false
    end
  end

  describe '.add_member_to_invited_team' do
    let(:assignment) { create(:assignment) }
    let(:inviter) { create(:user) }
    let(:invited) { create(:user) }
    let(:inviter_participant) { create(:participant, user: inviter, parent_id: assignment.id) }
    let(:invited_participant) { create(:participant, user: invited, parent_id: assignment.id) }
    let(:team) { create(:assignment_team, parent_id: assignment.id) }

    before do
      create(:teams_participant, team: team, participant: inviter_participant)
    end

    it 'adds a member to the team successfully' do
      puts "Before: TeamsParticipant.count = #{TeamsParticipant.count}"
      puts "inviter.id = #{inviter.id}, invited.id = #{invited.id}, assignment.id = #{assignment.id}"
      puts "inviter_participant.id = #{inviter_participant.id}, invited_participant.id = #{invited_participant.id}"
      puts "team.id = #{team.id}"
      
      result = TeamsParticipant.add_member_to_invited_team(inviter.id, invited.id, assignment.id)
      puts "Result: #{result}"
      puts "After: TeamsParticipant.count = #{TeamsParticipant.count}"
      
      expect(result).to be true
      expect(TeamsParticipant.count).to eq(2)
    end

    it 'returns false if inviter is not a participant' do
      TeamsParticipant.where(participant_id: inviter_participant.id).destroy_all
      inviter_participant.destroy
      expect(TeamsParticipant.add_member_to_invited_team(inviter.id, invited.id, assignment.id)).to be false
    end

    it 'returns false if invited user is not a participant' do
      invited_participant.destroy
      expect(TeamsParticipant.add_member_to_invited_team(inviter.id, invited.id, assignment.id)).to be false
    end

    it 'returns false if team is full' do
      allow_any_instance_of(AssignmentTeam).to receive(:full?).and_return(true)
      expect(TeamsParticipant.add_member_to_invited_team(inviter.id, invited.id, assignment.id)).to be false
    end
  end

  describe '.get_team_members' do
    let(:assignment) { create(:assignment) }
    let(:team) { create(:assignment_team, parent_id: assignment.id) }
    let(:participant1) { create(:participant, parent_id: assignment.id) }
    let(:participant2) { create(:participant, parent_id: assignment.id) }

    before do
      create(:teams_participant, team: team, participant: participant1)
      create(:teams_participant, team: team, participant: participant2)
    end

    it 'returns all team members' do
      members = TeamsParticipant.get_team_members(team.id)
      expect(members).to include(participant1.user, participant2.user)
    end
  end

  describe '.get_teams_for_user' do
    let(:assignment) { create(:assignment) }
    let(:user) { create(:user) }
    let(:participant) { create(:participant, user: user, parent_id: assignment.id) }
    let(:team1) { create(:assignment_team, parent_id: assignment.id) }
    let(:team2) { create(:assignment_team, parent_id: assignment.id) }

    before do
      create(:teams_participant, team: team1, participant: participant)
      create(:teams_participant, team: team2, participant: participant)
    end

    it 'returns all teams for a user' do
      teams = TeamsParticipant.get_teams_for_user(user.id)
      expect(teams).to include(team1, team2)
    end

    it 'returns empty array if user has no teams' do
      TeamsParticipant.destroy_all
      expect(TeamsParticipant.get_teams_for_user(user.id)).to be_empty
    end
  end
end 