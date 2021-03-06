class ColumnsController < ApplicationController
  include PatchAttributes
  before_action :fetch_board, only: [:show]
  before_action :fetch_board_for_update, except: [:show]
  before_action :fetch_resource, only: [:show, :update, :destroy]

  def show
    render json: {
      column_id: @column.id,
      html: render_to_string(
        partial: 'issues/issue_miniature',
        collection: @board_bag.column_issues(@column),
        as: :issue
      )
    }
  end

  def new
  end

  def create
    @column = Column.new(column_params)
    @column.board = @board
    @column.order = @board.columns.last.order + 1
    if @column.save
      redirect_to un(board_settings_url(@board))
    else
      render :new
    end
  end

  def edit
  end

  def update
    if params[:issues]
      @column.update_sort_issues(params[:issues])
      broadcast_column(@column)
    end
    render nothing: true
  end

  def destroy
    # FIX : Replace json on redirect_to or add animation for column hiding.
    if @column.issue_stats.blank?
      @column.destroy
      render json: { result: true, message: "Column \"#{@column.name}\" was successfully deleted.", id: @column.id }
    else
      render json: { result: false, message: "Can't delete column with issues!" }
    end
    # NOTE : After 302 redirect board was deleted too! But with 303 page don't reload. :(
    #redirect_to board_url(@board), notice: message, status: 303
  end

  def move_left
    move_to(:left)
  end

  def move_right
    move_to(:right)
  end

  private

  def move_to(direction)
    transporter = ColumnTransporter.new(@board.columns.find(params[:id]))
    if transporter.can_move?
      notice = 'Column was successfully moved'
      transporter.send("move_#{direction}")
    else
      notice = 'Can\'t move column with issues!'
    end
    redirect_to un(board_url(@board)), notice: notice
  end

  def column_params
    params.
      require(:column).
      permit(:name, :issues, :is_auto_assign)
  end

  def fetch_resource
    @column = @board.columns.find(params[:id])
    @column
  end
end
