describe Roadmap do
  describe '#call' do
    subject(:roadmap) { Roadmap.call(board_bag: board_bag) }
    let(:board_bag) { BoardBag.new(user, board) }
    let(:board) { create(:board, :with_columns) }
    let(:user) { create(:user) }

    context 'empty' do
      its(:issues) { is_expected.to be_empty }
      its(:dates) { is_expected.to be_empty }
    end

    context 'with issues' do
      let!(:issue_stat_1) { create(:issue_stat, board: board, number: issue_1.number) }
      let(:github_api) { double(issues: issues) }
      let(:issues) { [issue_1] }
      let(:issue_1) { stub_issue }
      before { Timecop.freeze(Time.current) }
      before { allow(user).to receive(:github_api).and_return(github_api) }
      after { Timecop.return }

      its(:issues) { is_expected.not_to be_empty }
      its(:dates) { is_expected.not_to be_empty }

      describe 'roadmap item' do
        subject { OpenStruct.new(roadmap.issues.first) }
        let(:forecast_closed_at) { issue_1.created_at + 1.day }

        its(:number) { is_expected.to eq issue_1.number }
        its(:title) { is_expected.to eq issue_1.title }
        its(:state) { is_expected.to eq issue_1.state.to_sym }
        its(:from) { is_expected.to eq 0 }
        its(:cycletime) { is_expected.to eq 40 }
        its(:created_at) { is_expected.to eq issue_1.created_at.strftime('%d %b') }
        its(:closed_at) { is_expected.to eq forecast_closed_at.strftime('%d %b') + ' (?)' }
        its(:column) { is_expected.to eq issue_stat_1.column.name }
        its(:is_archive) { is_expected.to eq false }
      end
    end
  end
end
