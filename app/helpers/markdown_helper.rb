require 'redcarpet'

module MarkdownHelper
  include Unescaper

  def markdown(text, board)
    return unless text
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(prettify: true, hard_wrap: true),
      autolink: true,
      fenced_code_blocks: true,
      highlight: true,
      lax_spacing: true, # Now it doesn't work. Partially helps hard_wrap.
      space_after_headers: true,
    )
    markdown.render(markdown_github_fixes(text, board)).html_safe
  end

  private

  def markdown_github_fixes(text, board)
    text = replace_issue_numbers(text, board)
    text = replace_checkbox(text)
    text
  end

  def replace_issue_numbers(text, board)
    url_prefix = un(UrlGenerator.show_board_issues_url(board, ''))
    text.gsub(/#([0-9]+)/, "<a href='#{url_prefix}\\1'>#\\1</a>")
  end

  def replace_checkbox(text)
    text.
      gsub(/- \[ \] (.*)/, '<input type="checkbox" class="task" />\1').
      gsub(/- \[x\] (.*)/, '<input type="checkbox" class="task" checked />\1')
  end
end
