describe UserPresenter do
  let(:presenter) { present(:user, user) }
  let(:user) { build(:user) }
  let!(:board_1) { create(:board, :with_columns, name: 'second_board', user: user) }
  let!(:board_2) { create(:board, :with_columns, name: 'first_board', user: user) }
  let!(:board_3) { build(:board, name: 'third', user: user) }
  let!(:board_4) { create(:board, :with_columns, name: 'other_board', github_id: 123) }
  let(:repo_4) { OpenStruct.new(id: board_4.github_id) }
  before do
    allow_any_instance_of(GithubApi).
      to receive(:cached_repos).and_return([repo_4])
    user.github_api = GithubApi.new(user, 'fake_token')
  end

  describe '#boards' do
    subject { presenter.boards }

    context 'show only created boards' do
      it { is_expected.to have(3).items }
      it { expect(subject.include?(board_2)).to eq false }
    end

    context 'sorting by name' do
      it { expect(subject.first.name).to eq 'first_board' }
    end
  end
end
