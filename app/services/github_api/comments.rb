class GithubApi
  module Comments
    def issue_comments(board, number)
      client.issue_comments(board.github_id, number)
    end

    def add_comment(board, number, comment)
      client.add_comment(board.github_id, number, comment)
    end

    def update_comment(board, number, comment)
      client.update_comment(board.github_id, number, comment)
    end

    def delete_comment(board, number)
      client.delete_comment(board.github_id, number)
    end
  end
end
