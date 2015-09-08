module IssueStats
  class Mover
    pattr_initialize :user, :board_bag, :column_to, :number, :is_force_sort

    def call
      if is_force_sort || column_will_change?
        IssueStatService.move!(column_to, issue_stat, user, is_force_sort)
      else
        issue_stat
      end
    end

    # NOTE Public until end refactoring

    def issue_stat
      @issue_stat ||= IssueStatService.find(board, number) ||
        IssueStatService.create!(board, user.github_api.issue(board, number), user)
    end

    private

    def board
      board_bag.board
    end

    def column_will_change?
      column_to != issue_stat.column
    end
  end
end
