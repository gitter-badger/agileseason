class GithubApi
  module Issues
    def issues(board)
      (open_issues(board) + closed_issues(board))
        .select { |issue| !issue.pull_request }
        .sort { |a, b| b.updated_at <=> a.updated_at }
    end

    def board_issues(board)
      board_hash = board.github_labels.each_with_object({}) { |label, hash| hash[label] = [] }
      issues(board).each do |issue|
        label_name = find_label_name(board, issue)
        board_hash[label_name] << issue if label_name
      end
      board_hash
    end

    def create_issue(board, issue)
      labels = issue.labels.reject(&:blank?) << board.columns.first.label_name
      github_issue = client.create_issue(board.github_id, issue.title, issue.body, labels: labels)
      IssueStatService.create!(board, github_issue)
      github_issue
    end

    def issue(board, number)
      client.issue(board.github_id, number)
    end

    # FIX : To many args.
    def move_to(board, column, number, issue = client.issue(board.github_id, number))
      IssueStatService.move!(board, column, issue)
      client.update_issue(
        board.github_id,
        number,
        issue.title,
        issue.body,
        labels: fetch_labels(issue, column)
      )
    end

    def close(board, number)
      client.close_issue(board.github_id, number)
      IssueStatService.close!(board, client.issue(board.github_id, number))
    end

    def archive(board, number)
      issue = client.issue(board.github_id, number)
      return if issue.state == 'open'
      IssueStatService.archive!(board, issue)
    end

    def assign_yourself(board, number, github_username)
      # FIX : Get issue - don't work override, error: Wrong number of arguments. Expected 4 to 5, got 3.
      issue = client.issue(board.github_id, number)
      # FIX : Don't work - client.update_issue(board.github_id, number, assignee: github_username)
      client.update_issue(board.github_id, number, issue.title, issue.body, assignee: github_username)
    end

    def update_issue(board, number, issue_params, issue = client.issue(board.github_id, number))
      if issue_params[:labels]
        client.update_issue(
          board.github_id,
          number,
          issue.title,
          issue.body,
          labels: issue_params[:labels]
        )
      else
        client.update_issue(
          board.github_id,
          number,
          issue_params[:title] ? issue_params[:title] : issue.title,
          issue_params[:body] ? issue_params[:body] : issue.body,
        )
      end
    end

    private

    def find_label_name(board, issue)
      column_names = board.github_labels
      label = issue.labels.detect { |e| column_names.include?(e.name) }
      if label
        label.name
      elsif issue.state == 'open'
        column = board.columns.first
        move_to(board, column, issue.number, issue)
        column.label_name
      end
    end

    def fetch_labels(issue, column)
      (issue.labels.map(&:name) - column.board.github_labels) << column.label_name
    end

    def open_issues(board)
      client.issues(board.github_id)
    end

    def closed_issues(board)
      client.issues(board.github_id, state: :closed)
    end
  end
end
