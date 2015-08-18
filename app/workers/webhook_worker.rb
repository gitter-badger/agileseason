class WebhookWorker
  include Sidekiq::Worker
  include GithubApiAccess
  sidekiq_options retry: 2
  sidekiq_options unique: true,
                  unique_args: -> (args) { [args.first] }

  def perform(board_id, encrypted_github_token)
    return unless Rails.env.production?

    board = Board.find(board_id)
    hook = github_api(encrypted_github_token).apply_issues_hook(board)
    board.update(github_hook_id: hook.id)
  end
end
