require 'spec_helper'

describe CultomePlayer::Plugins::Points do
	let(:t){ TestClass.new }

  before :each do
    t.execute "connect '#{test_folder}' => test"
  end

	it 'point a song if played complete' do
		expect{ t.emit_event(:playback_finish, Song.first) }.to change{ Song.first.points }.by(1)
	end

	it 'point a song if repeated' do
		t.should_receive(:current_song).at_least(1).and_return(Song.first)
		expect{ t.emit_event(:after_command_prev, Command.new({action: 'prev'}, []), t.success("ok")) }.to change{ Song.first.points }.by(1)
	end

	it 'point a song between 10-50% played' do
		t.should_receive(:current_song).at_least(1).and_return(Song.first)
		t.should_receive(:playback_length).at_least(1).and_return(100)
		t.should_receive(:playback_position).at_least(1).and_return(20)
		expect{ t.emit_event(:before_command_next, Command.new({action: 'next'}, []), t.success("ok")) }.to change{ Song.first.points }.by(-1)
	end

	it 'point a song if almost played completly' do
		t.should_receive(:current_song).at_least(1).and_return(Song.first)
		t.should_receive(:playback_length).at_least(1).and_return(100)
		t.should_receive(:playback_position).at_least(1).and_return(90)
		expect{ t.emit_event(:before_command_prev, Command.new({action: 'prev'}, []), t.success("ok")) }.to change{ Song.first.points }.by(1)
	end

	it 'punctuate more than once' do
		t.execute("play")
		curr_song = t.current_song
		t.execute("ff 40") # recorremos para estar en el rango de puntuacion negativa
		Song.all.each{|s| s.points.should eq 0 }

		# debe puntuar con puntos negativos 10...50
		expect{ t.execute("next") }.to change{ curr_song.points }.by(-1)
		old_points = curr_song.points # extraemos los punto de la nueva rola

		curr_song = t.current_song
		t.execute("ff 45") # recorremos hast entrar en 81...100
		points_before = t.current_song.points
		t.execute("prev")
		t.current_song.points.should eq (old_points + 1)
	end
end