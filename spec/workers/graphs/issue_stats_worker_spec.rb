describe Graphs::IssueStatsWorker do
  let(:worker) { Graphs::IssueStatsWorker.new }
  describe '.perform' do
    subject { board.issue_stats }
    let(:board) { create(:board, :with_columns, created_at: 10.days.ago) }
    let(:arrange) {}
    before { allow_any_instance_of(GithubApi).to receive(:issues).and_return(issues) }
    before { arrange }
    before { worker.perform(board.id, Encryptor.encrypt('fake_token')) }

    context :empty do
      let(:issues) { [] }
      it { is_expected.to be_empty }
    end

    context 'not add issues when it closed before board#created_at' do
      let(:board) { create(:board, :with_columns, created_at: 1.day.ago) }
      let(:issues) { [issue_1, issue_2] }
      let(:issue_1) { OpenStruct.new(number: 1, state: 'closed', created_at: 2.days.ago, updated_at: 2.days.ago, closed_at: 2.days.ago) }
      let(:issue_2) { OpenStruct.new(number: 2, state: 'open', created_at: 2.days.ago, updated_at: 2.days.ago, closed_at: nil) }
      it { is_expected.to have(1).item }
      it { expect(subject.first.number).to eq issue_2.number }
    end

    context 'add_new' do
      let(:issues) { [issue_1, issue_2] }
      let(:issue_1) { OpenStruct.new(number: 1, created_at: Time.current - 1.day, updated_at: Time.current - 6.hours, closed_at: Time.current) }
      let(:issue_2) { OpenStruct.new(number: 2, created_at: Time.current - 1.day, updated_at: Time.current - 6.hours, closed_at: nil) }
      it { expect(subject.map(&:number).sort).to eq [issue_1.number, issue_2.number] }
      it { expect(subject.map(&:created_at).map(&:to_s)).to eq [issue_1.created_at, issue_2.created_at].map(&:to_s) }
      it { expect(subject.map(&:updated_at).map(&:to_s)).to eq [issue_1.updated_at.to_s, issue_2.updated_at].map(&:to_s) }
      it { expect(subject.map(&:closed_at).map(&:to_s)).to eq [issue_1.closed_at, issue_2.closed_at].map(&:to_s) }
    end

    context 'update issue_1.closed_at and add new issue_2' do
      let(:arrange) { board.issue_stats.create!(number: 1, created_at: Time.current - 2.day, updated_at: Time.current - 2.day, closed_at: nil) }
      let(:issues) { [issue_1, issue_2] }
      let(:issue_1) { OpenStruct.new(number: 1, created_at: Time.current - 2.day, updated_at: Time.current - 6.hours, closed_at: Time.current) }
      let(:issue_2) { OpenStruct.new(number: 2, created_at: Time.current - 1.day, updated_at: Time.current - 6.hours, closed_at: nil) }
      it { is_expected.to have(2).items }
      it { expect(subject.map(&:number).sort).to eq [issue_1.number, issue_2.number] }
      it { expect(subject.map(&:created_at).map(&:to_s)).to eq [issue_1.created_at, issue_2.created_at].map(&:to_s) }
      it { expect(subject.map(&:updated_at).map(&:to_s)).to eq [issue_1.updated_at.to_s, issue_2.updated_at].map(&:to_s) }
      it { expect(subject.map(&:closed_at).map(&:to_s)).to eq [issue_1.closed_at, issue_2.closed_at].map(&:to_s) }
    end

    context 'update only if need' do
      let(:updated_at) { Time.current - 2.days }
      let(:arrange) { board.issue_stats.create!(number: 1, created_at: Time.current - 2.days, updated_at: updated_at, closed_at: nil) }
      let(:issues) { [issue_1] }
      context '- need' do
        let(:issue_1) { OpenStruct.new(number: 1, created_at: Time.current - 2.day, updated_at: updated_at + 1.second, closed_at: Time.current) }
        it { expect(subject.first.closed_at.to_s).to eq issue_1.closed_at.to_s }
      end

      context '- not need' do
        let(:issue_1) { OpenStruct.new(number: 1, created_at: Time.current - 2.day, updated_at: updated_at, closed_at: Time.current) }
        it { expect(subject.first.closed_at).to be_nil }
      end
    end

    context 'auto archive very old (see GithubApi::Issues.closed)' do
      let(:arrange) do
        board.issue_stats.create!(number: 1, closed_at: 3.month.ago, archived_at: nil)
        board.issue_stats.create!(number: 2, closed_at: closed_issue.closed_at, archived_at: nil)
        board.issue_stats.create!(number: 3, closed_at: nil, archived_at: nil)
      end
      let(:closed_issue) { OpenStruct.new(number: 2, state: 'closed', created_at: 2.day.ago, updated_at: Time.current - 6.hours, closed_at: Time.current) }
      let(:open_issue) { OpenStruct.new(number: 3, state: 'open', created_at: 2.day.ago, updated_at: Time.current, closed_at: nil) }
      let(:issues) { [closed_issue, open_issue] }

      it { expect(IssueStat.find_by(number: 1)).to be_archived }
      it { expect(IssueStat.find_by(number: 2)).not_to be_archived }
      it { expect(IssueStat.find_by(number: 3)).not_to be_archived }
    end
  end
end
