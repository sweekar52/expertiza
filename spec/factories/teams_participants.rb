FactoryBot.define do
  factory :teams_participant do
    association :team
    association :participant
    duty { nil }  # Make duty optional by default

    trait :with_assignment do
      association :team, factory: [:team, :with_assignment]
      association :participant, factory: [:participant, :with_assignment]
    end

    trait :with_course do
      association :team, factory: [:team, :with_course]
      association :participant, factory: [:participant, :with_course]
    end

    trait :with_duty do
      association :duty
    end

    after(:build) do |teams_participant|
      if teams_participant.team.present? && teams_participant.participant.present?
        teams_participant.team_id = teams_participant.team.id
        teams_participant.participant_id = teams_participant.participant.id
      end
    end

    after(:create) do |teams_participant|
      if teams_participant.team.present? && teams_participant.participant.present?
        teams_participant.team_id = teams_participant.team.id
        teams_participant.participant_id = teams_participant.participant.id
        teams_participant.save!
      end
    end
  end
end 