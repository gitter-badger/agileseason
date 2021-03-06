module IssueStats
  class Unready
    include Service
    include Virtus.model

    attribute :user, User
    attribute :board_bag, BoardBag
    attribute :number, Integer

    def call
      issue_stat = IssueStats::Finder.new(user, board_bag, number).call
      issue_stat.update(is_ready: false)
      issue_stat
    end
  end
end
