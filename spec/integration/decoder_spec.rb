require 'spec_helper'

describe Pocketsphinx::Decoder do
  subject { @decoder }
  let(:configuration) { @configuration }

  # Share decoder across all examples for speed
  before do
    @configuration = Pocketsphinx::Configuration.default
    @decoder = Pocketsphinx::Decoder.new(@configuration)
  end

  it 'reads cmninit configuration values from default acoustic model feat.params' do
    expect(configuration.details('cmninit')[:default]).to eq("8.0")
    expect(configuration.details('cmninit')[:value]).to eq("40,3,-1")
  end

  describe '#decode' do
    it 'correctly decodes the speech in goforward.raw' do
      subject.decode File.open('spec/assets/audio/goforward.raw', 'rb')
      expect(subject.hypothesis).to eq("go forward ten meters")
    end

    it 'accepts a file path as well as a stream' do
      subject.decode 'spec/assets/audio/goforward.raw'
      expect(subject.hypothesis).to eq("go forward ten meters")
    end

    it 'reports words with start/end frame values' do
      subject.decode File.open('spec/assets/audio/goforward.raw', 'rb')

      expect(subject.words.map(&:word)).to eq(["<s>", "go", "forward", "ten", "meters", "</s>"])
      expect(subject.words.map(&:start_frame)).to eq([51, 54, 66, 119, 155, 214])
      expect(subject.words.map(&:end_frame)).to eq([53, 65, 118, 154, 213, 262])
    end
  end
end
