s.boot

It's pretty easy to make random bleeps and bloops in SC, just take a noise generator, plug it into an oscillator.

(
{
	var sig, freq;
	freq = LFDNoise0.kr(7).exprange(110, 880);
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

Easy, yes. Musically appealing and useful?...ehh, not so much. Instead, we can think in terms of MIDI note numbers, and convert to frequency with midicps:

(
{
	var sig, pch, freq;
	pch = LFDNoise0.kr(7).range(45, 81);
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

This noise generator spits out floats, which we can confirm by polling it:

(
{
	var sig, pch, freq;
	pch = LFDNoise0.kr(7).range(45, 81);
	pch.poll(7);
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

so, basically identical to the first example. If we want actual...notes from a piano keyboard, we can round these pitch values to the nearest integer:

(
{
	var sig, pch, freq;
	pch = LFDNoise0.kr(7).range(45, 81).round(1);
	pch.poll(7);
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

It's more musical but still pretty random, we can round to a different number to do intervallic stuff, like, a value of 2 picks notes from a whole-tone scale...7 picks from a bunch of stacked fifths...

(
{
	var sig, pch, freq;
	pch = LFDNoise0.kr(7).range(45, 81).round(7);
	pch.poll(7);
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

very retro video game flavor...ok, but the obvious question here is -- is it possible to round (or musically "quantize") these pitches to the nearest scale degree in some scale? The answer is yes, and the first step is to load a collection of scale degrees into a buffer, let's do the minor pentatonic scale, so that would look like this:

Scale.minorPentatonic.degrees;

~scale0 = Buffer.loadCollection(s, Scale.minorPentatonic.degrees);

And let's plot this buffer just to really understand what's going on here

~scale0.plot;

These connecting lines are misleading, so I'm gonna hit the 'm' key on my keyboard once to plot the data as points, stretch it vertically, and we can see this buffer contains 5 values, which are 0, 3, 5, 7, and 10.

And now, we're going use a UGen called Index, which retrieves buffer values, using the integer part of its input signal as an index. So, new variable called index, and gonna reuse this noise generator, but give it a range between 0 and 1, which is gonna represent octaves, and then scale it by the number of frames in the buffer. Index.kr uses this signal to look up scale degrees in the buffer. If we stop here, the values produced are gonna be 0, 3, 5, 7, or 10, which are really low for MIDI note numbers, so we should add a value, which effectively determines the starting note of the scale.

We'll poll the index, so as this plays, watch the integer part of the numbers in the post window, and you'll notice that they correspond to the scale degrees that we hear:

(
{
	var sig, index, pch, freq;
	index = LFDNoise0.kr(7).range(0,1);
	index = index * BufFrames.kr(~scale0);
	index.poll(7);
	pch = Index.kr(~scale0, index) + 48;
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

It's a good start, but doesn't give us a lot of flexibility. If we increase the range of the indices, y'know, thinking we're gonna expand out to four octaves or whatever, Index isn't really designed to work this way. Instead, it just clips the index within the buffer frame range, so in this case we're just going to hear that highest scale degree like 75-80% percent of the time:

(
{
	var sig, index, pch, freq;
	index = LFDNoise0.kr(7).range(0,4);
	index = index * BufFrames.kr(~scale0);
	index.poll(7);
	pch = Index.kr(~scale0, index) + 48;
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

An better option, I think, is a UGen called DegreeToKey which is similar, but instead of clipping index values, it wraps them within the frame range, and as it does so, shifts the octave accordingly. So, here's a four octave range, also dropping the starting note one octave lower...

(
{
	var sig, index, pch, freq;
	index = LFDNoise0.kr(7).range(0,4);
	index = index * BufFrames.kr(~scale0);
	index.poll(7);
	pch = DegreeToKey.kr(~scale0, index) + 36;
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

And just to emphasize what's going on here, let's replace the index with with LFSaw, to sweep across these four octaves, and I guess we don't really need to poll the values anymore:

(
{
	var sig, index, pch, freq;
	index = LFSaw.kr(0.8, 1).range(0,4);
	index = index * BufFrames.kr(~scale0);
	pch = DegreeToKey.kr(~scale0, index) + 36;
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
}.play;
)

And what's really cool about this is that these scales are stored in buffers, which means we can swap 'em out in real-time. To make this a little cleaner I'm gonna paste in a SynthDef version of this code, which has an argument for the scale buffer, and side-note, perfect example of why we should use kr for buffer information instead of ir, because if we switch to a scale with a different number of degrees, kr will track this change, ir will not.

(
SynthDef(\d2k, {
	arg buf;
	var sig, index, pch, freq;
	index = LFSaw.kr(0.75, 1).range(0,4);
	index = index * BufFrames.kr(buf);
	pch = DegreeToKey.kr(buf, index) + 36;
	freq = pch.midicps;
	sig = VarSaw.ar(freq, mul:0.2!2);
	Out.ar(0, sig);
}).add;
)

Here's a couple of different scales to play with:
(
~scale1 = Buffer.loadCollection(s, [0,4,6,7,10]);
~scale2 = Buffer.loadCollection(s, [0,3,7,9,10]);
)

And try 'em out:

x = Synth(\d2k, [\buf, ~scale0]);
x.set(\buf, ~scale1);
x.set(\buf, ~scale2);
x.free;

And finally, here's a fancy version I made ahead of time, pause and study at your leisure, it's got a randomly changing index, multichannel expansion to create multiple voices, a detuning effect on the pitch, an argument for the starting note so we can easily transpose, frequency very slightly lagged so there's a micro-glissando whenever the pitch changes, one additional octave at the top, an envelope mostly for fading-out, and a delay/reverb combo at the end.

(
SynthDef(\d2k, {
	arg buf, inote=36, gate=1;
	var sig, index, pch, freq;
	index = LFDNoise3.kr(1!4).range(0,5);
	index = index * BufFrames.kr(buf);
	pch = DegreeToKey.kr(buf, index) + inote;
	pch = pch + LFNoise1.kr(1!4).bipolar(0.12);
	freq = pch.midicps.lag(0.02);
	sig = VarSaw.ar(freq, mul:0.2);
	sig = Splay.ar(sig, 0.75);
	sig = sig * EnvGen.kr(
		Env([0,1,0,0],[0.2,4,7],[0,-2,0],1),
		gate, doneAction:2
	);
	sig = sig.blend(
		CombN.ar(sig, 0.25, 0.25, 2),
		0.5
	);
	sig = sig.blend(
		LPF.ar(GVerb.ar(sig.sum, 299, 5), 2000),
		0.4
	);
	Out.ar(0, sig);
}).add;
)

and it sounds like this:

x = Synth(\d2k, [\buf, ~scale0, \inote, 36]);
x.set(\buf, ~scale1, \inote, 32);
x.set(\buf, ~scale2, \inote, 30);
x.set(\buf, ~scale1, \inote, 39);
x.set(\buf, ~scale0, \inote, 38);
x.set(\gate, 0);

DegreeToKey, great UGen for scale quantization, a gateway to all sorts of scale- ande mode-based pitch work. Shoutout and big thanks to my Patrons, for the ongoing support, very much appreciated. And to everyone, if you're enjoying this mini series, please like and subscribe, and I hope you'll consider becoming a Patron yourself. Hope this helps, thanks for watching.

Patreon.thanks;