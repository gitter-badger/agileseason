describe SettingsController, type: :controller do
  render_views
  before do
    allow_any_instance_of(GithubApi).
      to receive(:repos).and_return([])
  end

  describe 'GET show' do
    let(:user) { create(:user) }
    let(:board) { create(:board, :with_columns, user: user) }
    before { stub_sign_in(user) }

    it 'returns http success' do
      get :show, board_github_full_name: board.github_full_name
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH update' do
    let(:user) { create(:user) }
    let(:board) { create(:kanban_board, :with_columns, user: user) }
    before { stub_sign_in(user) }

    it 'returns http redirect if ok' do
      get(
        :update,
        board_github_full_name: board.github_full_name,
        kanban_settings: { foo: :bar }
      )
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST rename' do
    let(:user) { create(:user) }
    let(:board) { create(:board, :with_columns, user: user) }
    before { stub_sign_in(user) }

    it 'returns http redirect if ok' do
      get(
        :rename,
        board_github_full_name: board.github_full_name,
        board: { name: board.name + '1' }
      )
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(CGI::unescape(board_settings_url(board)))
    end

    it 'returns http success if fail' do
      get(
        :rename,
        board_github_full_name: board.github_full_name,
        board: { name: '' }
      )
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
    end
  end
end
