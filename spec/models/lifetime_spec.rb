RSpec.describe Lifetime, type: :model do
  describe 'validations' do
    subject { Lifetime.new }
    it { is_expected.to validate_presence_of :in_at }
  end
end
