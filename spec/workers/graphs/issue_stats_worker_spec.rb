describe Graphs::IssueStatsWorker do
  let(:worker) { Graphs::IssueStatsWorker.new }

  describe '.perform' do
    subject(:issue_stats) { board.issue_stats }
    let(:board) { create(:board, :with_columns, created_at: created_at) }
    let(:created_at) { 10.days.ago }
    let(:arrange) {}

    before { allow_any_instance_of(GithubApi).to receive(:issues).and_return(issues) }
    before { arrange }
    before { worker.perform(board.id, Encryptor.encrypt('fake_token')) }

    context :empty do
      let(:issues) { [] }
      it { is_expected.to be_empty }
    end

    context 'not add issues when it closed before board#created_at' do
      let(:created_at) { 1.day.ago }
      let(:issues) { [issue_1, issue_2] }
      let(:issue_1) { stub_issue(state: 'closed', created_at: 2.days.ago, updated_at: 2.days.ago, closed_at: 2.days.ago) }
      let(:issue_2) { stub_issue(state: 'open', created_at: 2.days.ago, updated_at: 2.days.ago, closed_at: nil) }

      it { is_expected.to have(1).item }

      describe 'check fields' do
        subject { issue_stats.first }
        its(:number) { is_expected.to eq issue_2.number }
        its(:created_at) { is_expected.to be_the_same_time issue_2.created_at }
        its(:updated_at) { is_expected.to be_the_same_time issue_2.updated_at }
        its(:closed_at) { is_expected.to eq issue_2.closed_at }
      end
    end

    context 'add new issues' do
      let(:issues) { [issue_1, issue_2] }
      let(:issue_1) { stub_issue(created_at: Time.current - 1.day, updated_at: Time.current - 6.hours, closed_at: Time.current) }
      let(:issue_2) { stub_issue(created_at: Time.current - 1.day, updated_at: Time.current - 6.hours, closed_at: nil) }

      it { is_expected.to have(2).items }
    end

    context 'update issue_1.closed_at and add new issue_2' do
      let(:arrange) { board.issue_stats.create!(number: 1, created_at: Time.current - 2.day, updated_at: Time.current - 2.day, closed_at: nil) }
      let(:issues) { [issue_1, issue_2] }
      let(:issue_1) { stub_issue(number: 1, created_at: Time.current - 2.day, updated_at: Time.current - 6.hours, closed_at: Time.current) }
      let(:issue_2) { stub_issue(number: 2, created_at: Time.current - 1.day, updated_at: Time.current - 6.hours, closed_at: nil) }

      it { is_expected.to have(2).items }

      describe 'check updated closed_at' do
        subject { issue_stats.find_by(number: issue_1.number) }
        its(:closed_at) { is_expected.to be_the_same_time issue_1.closed_at }
      end
    end

    context 'update only if need' do
      let(:arrange) { issue_stat }
      let(:issue_stat) do
        board.issue_stats.create!(
          number: 1,
          created_at: 2.days.ago,
          closed_at: nil
        )
      end
      let(:issues) { [issue_1] }

      context '- need' do
        let(:issue_1) do
          stub_issue(
            number: 1,
            created_at: 3.days.ago,
            closed_at: Time.current
          )
        end

        Graphs::IssueStatsWorker::SYNCED_FIELDS.each do |field|
          it do
            expect(subject.first.send(field).to_i).to eq issue_1.send(field).to_i
          end
        end
      end

      context '- not need' do
        let(:issue_1) { stub_issue(number: 1, closed_at: nil) }

        Graphs::IssueStatsWorker::SYNCED_FIELDS.each do |field|
          it do
            expect(subject.first.send(field).to_i).to eq issue_stat.send(field).to_i
          end
        end
      end
    end
  end
end
