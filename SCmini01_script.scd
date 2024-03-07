Did you know that it's possible to record SuperCollider's output and render that sound as an audio file? It's a useful trick, especially if you're the kind of person who likes using SuperCollider for *generating* sound, but prefers a DAW for assembly and fine-tuning. Let's say you've got some code you're happy with, like this here:

s.boot;

(
x = {
	var sig, freq, amp, reverb;
	freq = LFNoise0.ar(8!8).exprange(60,1500).round(60);
	amp = VarSaw.ar(8,0,0.004).range(0,1).pow(4);
	sig = LFTri.ar(freq);
	sig = sig * amp * 0.4;
	sig = Splay.ar(sig);
}.play(fadeTime:0);
)

x.release(1);

One of the simplest ways to turn this code into an audio file is to run

s.makeWindow;

which gives you a little status window for the audio server, click the record button, run your code and let it play for as long as you like, stop the sound, and then click that same button again to stop recording.

When you stop recording, ............the file path appears in the post window. You can also get the location of your recordings directory by evaluating

Platform.recordingsDir;

Navigate to the folder, and here's our new audio file. Open it up in a waveform editor...and there it is. Inevitably, with this approach, there's going to be some time that passes between pressing the record button and running your code, that's why we have this chunk of silence at the beginning here. Of course you can trim this off using editing software, but if this bothers you, you can handle the recording process using code instead. All you have to do is wrap your sound code in a Routine with .play at the end, and put s.record at the beginning of the Routine. Now, when we call s.record, the server does a tiny bit of setup in preparation for writing audio into a file, and that takes a small amount of time, so it's kind of necessary, actually, to include a short wait between these two steps. Hard to say precisely how much time is needed but I find that 0.02 seconds usually works pretty well.

(
Routine.new({

	s.record;

	0.02.wait;

	x = {
		var sig, freq, amp, reverb;
		freq = LFNoise0.ar(8!8).exprange(60,1500).round(60);
		amp = VarSaw.ar(8,0,0.004).range(0,1).pow(4);
		sig = LFTri.ar(freq);
		sig = sig * amp * 0.4;
		sig = Splay.ar(sig);
	}.play(fadeTime:0);

}).play;
)

When you've had enough, stop the sound...and then evaluate s.stopRecording.

x.release(1);

s.stopRecording;

[open recording]

Once again, here...is our recording, and it looks we've got roughly 0.01 seconds of silence at the beginning. So that's pretty good, probably good enough, but, y'know, go ahead and mess with this 0.02 value if you feel like it.

The default format for these files is 32-bit float, AIFF format, 2-channels. You can get these settings by evaluating

s.recSampleFormat;
s.recHeaderFormat;
and
s.recChannels;

In many cases these settings are fine, but *if* you'll need to change something, most likely it'll be downgrading the bit depth to something lower than 32, because most but not all audio software can read 32-bit audio files. To drop the bit depth, set this expression equal to the string int24 or int16 depending on what bit depth you want.

s.recSampleFormat = "int24";

Similarly, you can set the file format to wav like this

s.recHeaderFormat = "wav";

though I don't think I've ever encountered a situation where wav and aiff are not interchangeable.

So, let's run this Routine again...

(
Routine.new({

	s.record;

	0.02.wait;

	x = {
		var sig, freq, amp, reverb;
		freq = LFNoise0.ar(8!8).exprange(60,1500).round(60);
		amp = VarSaw.ar(8,0,0.004).range(0,1).pow(4);
		sig = LFTri.ar(freq);
		sig = sig * amp * 0.4;
		sig = Splay.ar(sig);
	}.play(fadeTime:0);

}).play;
)

stop the sound, and stop recording...

x.release(1);
s.stopRecording;

here's our file, we can see that it's a 24-bit wav file.

s.record actually takes a few arguments that can make this process a little easier.

(
Routine.new({

	s.record();

	0.02.wait;

	x = {
		var sig, freq, amp, reverb;
		freq = LFNoise0.ar(8!8).exprange(60,1500).round(60);
		amp = VarSaw.ar(8,0,0.004).range(0,1).pow(4);
		sig = LFTri.ar(freq);
		sig = sig * amp * 0.4;
		sig = Splay.ar(sig);
	}.play(fadeTime:0);

}).play;
)

Two in particular I want to bring to your attention: The first argument, path, is a string representing where you want to put the new file, which is nice for being able to store the recording somewhere else. And the last argument, duration, is the desired length of the recording, in seconds. This is nice because you no longer have to stop the recording process manually, and you'll actually see "recording stopped" in the post window when it's finished.

(
Routine.new({

	s.record(path:"/Users/eli/Desktop/test/mySound.wav", duration:4);

	0.02.wait;

	x = {
		var sig, freq, amp, reverb;
		freq = LFNoise0.ar(8!8).exprange(60,1500).round(60);
		amp = VarSaw.ar(8,0,0.004).range(0,1).pow(4);
		sig = LFTri.ar(freq);
		sig = sig * amp * 0.4;
		sig = Splay.ar(sig);
	}.play(fadeTime:0);

}).play;
)

x.free;

And, on the desktop, here's my test folder, with mySound.wav in there. Something to watch out for — make sure this path is unique each time you run it. Otherwise, you're gonna end up overwriting a previous audio file with a new one, you won't get a warning message or anything like that, and the old recording will be unrecoverable.

For more info, check out the Server help file, under the section titled Recording Support. Related to this, the help file for Recorder, which is the actual class that does the work in the background when we call s.record.

So that's it for this mini tutorial, I want to give a special shoutout to my supporters on Patreon, huge thanks, you all are so awesome, and to everyone, hope this is helpful, and thanks for watching.