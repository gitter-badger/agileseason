# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :board do
    name 'test_board'
    type "Boards::KanbanBoard"
  end

  factory :board_with_columns, parent: :board do
    after(:build) do |user, evaluator|
      columns [build(:column, board: self)]
    end
  end
end
