# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasTaskbars' do
  subject { create(described_class.name.underscore) }

  describe '#destroy_taskbars' do
    it 'destroys related taskbars' do
      taskbar = create(:taskbar, key: "#{described_class.name}-#{subject.id}")
      subject.destroy
      expect { taskbar.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end
end
