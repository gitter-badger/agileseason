class IssuePresenter < Keynote::Presenter
  presents :issue
  delegate :labels, :number, to: :issue

  def labels_html(board)
    build_html do
      labels.each do |label|
        div class: :label, style: "background-color:##{label.color}; color:##{color(label)}" do
          label.name
        end
      end
    end
  end

  # FIX : Public method only for test - not single responsibility.
  # FIX : Need extract to gem.
  def color(label)
    hex = label.color.hex
    if hex == 16_777_215 # white
      '000'
    elsif hex >= 16_525_609 # red
      'fff'
    elsif hex <= 5_446_119 # dark blue
      'fff'
    else
      '000'
    end
  end

  def current_column?(columns, current_column)
    columns.any? { |column| current_column == column.name.split('] ').last }
  end

  def archived?(board)
    IssueStatService.archived?(board, number)
  end

  def body_empty?
    issue.body == nil || issue.body.split("<!---").first.blank?
  end

  def first_letter(string)
    string.slice(0, 1).capitalize + string.slice(1..-1)
  end
end
