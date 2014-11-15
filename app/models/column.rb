class Column < ActiveRecord::Base
  belongs_to :board

  def label_name
    "#{name} [#{order}]"
  end
end
