s.boot;

A vocoder is a signal processing algorithm that takes two sounds, a carrier and a modulator, it analyzes the spectrum of the modulator, usually someone's voice, and transplants that spectrum onto the carrier, which is usually some synthesized waveform. It's a popular choice for creating a "robot voice" effect, and featured in songs by kraftwerk, daft punk, imogen heap, beastie boys, and many others.

It is surprisingly easy to build your own vocoder in SuperCollider, so let's do it.

(
SynthDef(\vocoder, {

	// create modulator & carrier

	// track spectrum of modulator

	// apply spectrum to carrier

}).play;
)

For the modulator, I'm gonna use this recording of my voice:

b = Buffer.read(s, "/Users/eli/Documents/Illinois/Teaching/AY 2023-2024/Fall 2023/MUS 499C/Lecture Code Files/Week 5 Lecture Code 2023-09-21/brain.aiff");

b.play;

So PlayBuf takes care of that. For the carrier, the wider the spectrum, the better the results are gonna be, so I'm gonna pass white noise through a comb filter to create a resonator effect, which has a broad spectrum, but also a sense of pitch at the inverse of the delay time, which'll be 50 Hz by default. Comb filters can get pretty loud, especially with long decay times, so let's dial back the amplitude and take a listen.

(
SynthDef(\vocoder, {

	var mod, car;

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator

	// apply spectrum to carrier

	Out.ar(0, car * 0.02!2);
}).play;
)

Next, we're gonna pass the modulator through a bank of bandpass filters, and measure the amplitude of each band. So, BPF, with mod as the input. Then, an array of center frequencies. Our range of pitch sensation is about 10 octaves, and a lot of graphic EQs split the octave into three bands, so 10 times 3 is 30 filters, and that seems like a good model. A target range of 20 to 20000 is fine, but you'll still get get good results if you shrink this range a bit, which also feels a little safer to me, though I might just be paranoid.

For reciprocal quality, I'm gonna do 1/q, and then the square root of q for mul, I find does a pretty good job of keeping the overall amplitude consistent across a wide range of q values.

If you're curious, we can listen to the filtered modulator, using Splay to mix 30 channels down to stereo:

(
SynthDef(\vocoder, {

	var mod, car, bpfmod, num = 30,
	bpfhz = (1..num).linexp(1, num, 25, 16000),
	q = \q.kr(20);

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator
	bpfmod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);

	// apply spectrum to carrier

	Out.ar(0, Splay.ar(bpfmod));
}).play;
)

Though, keep in mind, at the end of the day, it's the carrier we're gonna be listening to, not the modulator, I'm just monitoring the modulator because it's kind of interesting. So, next, we're gonna measure the output amplitude of each filter using Amplitude.kr, and the output is 30 channels of real-time amplitude following, one for each band. In addition to monitoring the filtered modulator, let's also route the amplitude tracking to a bank of control busses, and let's view those on the scope to see what we're working with.

(
SynthDef(\vocoder, {

	var mod, car, bpfmod, num = 30, track,
	bpfhz = (1..num).linexp(1, num, 25, 16000),
	q = \q.kr(20);

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator
	bpfmod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);
	track = Amplitude.kr(bpfmod);

	// apply spectrum to carrier

	Out.kr(0, track);
	Out.ar(0, Splay.ar(bpfmod));
}).play;
)

Ok, cool, we are actually almost done. Last thing is to apply this spectral profile to the carrier, so we pass the carrier through an identical set of filters, multiply by track, and output the result, again mixing down to stereo.

(
SynthDef(\vocoder, {

	var mod, car, bpfmod, num = 30, track, bpfcar,
	bpfhz = (1..num).linexp(1, num, 25, 16000),
	q = \q.kr(20);

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator
	bpfmod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);
	track = Amplitude.kr(bpfmod);

	// apply spectrum to carrier
	bpfcar = BPF.ar(car, bpfhz, 1/q, q.sqrt) * track;

	Out.ar(0, Splay.ar(bpfcar));
}).play;
)

So — it works! But there's a couple things we can do to improve the results. The sound is kind of gritty and crunchy, that's because the amplitude tracking signal is jittery as-is, but we can smooth it out by lagging with a small time interval. It also sounds a little quiet relative to the modulator, so I'm gonna upscale these values a bit.

(
SynthDef(\vocoder, {

	var mod, car, bpfmod, num = 30, track, bpfcar,
	bpfhz = (1..num).linexp(1, num, 25, 16000),
	q = \q.kr(20);

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator
	bpfmod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);
	track = Amplitude.kr(bpfmod).lag(0.03) * 2;

	// apply spectrum to carrier
	bpfcar = BPF.ar(car, bpfhz, 1/q, q.sqrt) * track;

	Out.ar(0, Splay.ar(bpfcar));
}).play;
)

And if we Splay as-is, the low frequency bands end up on the left, high frequency on the right, sounds kind of unbalanced, so we can scramble the array, and set 'spread' closer to zero, which narrows the stereo image.

(
SynthDef(\vocoder, {

	var mod, car, bpfmod, num = 30, track, bpfcar,
	bpfhz = (1..num).linexp(1, num, 25, 16000),
	q = \q.kr(20);

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator
	bpfmod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);
	track = Amplitude.kr(bpfmod).lag3(0.03) * 2;

	// apply spectrum to carrier
	bpfcar = BPF.ar(car, bpfhz, 1/q, q.sqrt) * track;

	Out.ar(0, Splay.ar(bpfcar.scramble, spread: 0.1));
}).play;
)

'freq' is an argument, so it's controllable in real-time, for example, let's give this Synth a name, and then prep a set message down below with some randomness:

(
x = SynthDef(\vocoder, {

	var mod, car, bpfmod, num = 30, track, bpfcar,
	bpfhz = (1..num).linexp(1, num, 25, 16000),
	q = \q.kr(20);

	// create modulator & carrier
	mod = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	car = CombL.ar(WhiteNoise.ar(1), 1/20, 1/\freq.kr(50), 3);

	// track spectrum of modulator
	bpfmod = BPF.ar(mod, bpfhz, 1/q, q.sqrt);
	track = Amplitude.kr(bpfmod).lag3(0.03) * 2;

	// apply spectrum to carrier
	bpfcar = BPF.ar(car, bpfhz, 1/q, q.sqrt) * track;

	Out.ar(0, Splay.ar(bpfcar.scramble, spread: 0.1));
}).play;
)

x.set(\freq, rrand(30, 50).midicps);

That's a pretty lazy example of controlling pitch, but you could plug in a MIDI controller, and use that to modulate the frequency instead, and on that note you could also hook up a microphone, use SoundIn instead of PlayBuf, and you've got yourself a real-time robot voice auto-tuner. Don't forget you can also use whatever you want for the carrier, but keep in mind, the wider the spectrum, the better the results tend to be.

Patreon.thanks;

That's it for this tutorial, shoutout and thanks to my Patrons, thank you all so much for the support, I really appreciate it. Hope you have some fun with this vocoder, if you enjoyed this video please give it a like, leave a comment down below, and subscribe if you're new. Thanks for watching, see you next time.