class BoardIssue
  attr_accessor :issue, :issue_stat
  delegate :number, :title, :body, :state, :labels, :html_url,
    :assignee, :comments, :all_comments, to: :issue

  def initialize(issue, issue_stat)
    @issue = issue
    @issue_stat = issue_stat
  end

  def archive?
    @issue_stat.archived?
  end
end
