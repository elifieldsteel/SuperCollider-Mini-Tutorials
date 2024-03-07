SuperCollider has this diverse library of patterns for expressing all kinds of sequences, common examples include Pseq, Prand, Pwhite, many others. Now, by design, patterns are language-side, and although it is often useful to have this separation from the audio server, it does mean that we can't plug them directly in a SynthDef, as you can see here!

s.boot;

(
SynthDef(\d, {
	var freq, sig;
	freq = Pseq([200, 300, 400], inf);
	sig = Saw.ar(freq, mul: 0.1 ! 2);
	Out.ar(0, sig);
}).play;
)

However, there's a category of Demand UGens that produce pattern-like behavior, most actually have nearly the same name as their pattern counterparts. These demand classes can be incorporated into a UGen function and applied directly to audio and control signals. They're kinda like sequencer modules on an analog synth, so they're a good choice for arpeggiators, rhythm generators, and just about anything sequential in nature.

So, here's a basic filtered sawtooth instrument.

(
SynthDef(\d, {
	var freq, sig;
	freq = 50.midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

For this tutorial I actually want to think in terms of musical scale, so I'm gonna load the dorian mode into a buffer, which is just the integers 0 2 3 5 7 9 10.

b = Buffer.loadCollection(s, Scale.dorian);

b.plot.plotMode_(\plines);

And use DegreeToKey, from mini tutorial 6, basically just retrieves buffer values by index, allowing us to use consecutive integers to traverse the scale.

(
SynthDef(\d, {
	var freq, sig;
	freq = (DegreeToKey.ar(b, 0) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

And then here's a simple application of Demand UGens. We start with an impulse generator as a basic timing signal. Demand receives those triggers, it's also got a reset parameter which I'm gonna temporarily ignore, and then some demand-based pattern, like Dseq, for example, will step through its values in order.

(
SynthDef(\d, {
	var freq, sig, trig, deg;
	trig = Impulse.ar(4);
	deg = Demand.ar(trig, 0, Dseq([ 0, 2, -1, -3 ], inf));
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

MouseX and MouseY to control impulse rate and cutoff frequency, for a little interactive fun and also to help understand what's going on a little bit more clearly.

(
SynthDef(\d, {
	var freq, sig, trig, deg;
	trig = Impulse.ar(MouseX.kr(2, 150, 1));
	deg = Demand.ar(trig, 0, Dseq([ 0, 2, -1, -3 ], inf));
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, MouseY.kr(100, 8000, 1));
	Out.ar(0, sig);
}).play;
)

Duty is similar to Demand but interprets its first argument as a duration instead of expecting a trigger signal.

(
SynthDef(\d, {
	var freq, sig, deg;
	deg = Duty.ar(
		1/4,
		0,
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

That's the same thing we heard a moment ago, but the duration doesn't have to be static, in fact it can be any signal, like an LFO or even another demand-style pattern, like Drand.

(
SynthDef(\d, {
	var freq, sig, deg;
	deg = Duty.ar(
		Drand([ 1/4, 1/8 ], inf),
		0,
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

The reset argument can be used to restart a sequence at any point. So, for example, if the duration is 1/8 and we want a repeating sequence of 11 notes, we can use an impulse generator with a frequency of 8/11 because frequency and period are inversely related.

(
SynthDef(\d, {
	var freq, sig, deg;
	deg = Duty.ar(
		1/8,
		Impulse.ar(8/11),
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

Just like patterns, Demand UGens can be nested inside of each other for more complex results, so here's a composite rhythmic sequence, and a little bit of randomness on the second pitch value.

(
SynthDef(\d, {
	var freq, sig, deg;
	deg = Duty.ar(
		Dseq([
			Dseq([ 1/4, 1/8 ], 4),
			Dseq([ 1/8 ], 4)
		], inf),
		0,
		Dseq([ 0, Drand([ 2, 3, 4 ], 1), -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	Out.ar(0, sig);
}).play;
)

For amplitude sequencing, we can use TDuty to trigger an envelope according to some unique rhythm. TDuty is very similar to Duty but outputs its values as triggers, instead of sample-and-hold behavior, as you can see on these two plots.

(
{
	Duty.ar( // change to TDuty
		0.0005,
		0,
		Dseq([1, 7, 3], inf)
	);
}.plot;
)

So, a little syncopated rhythm for these triggers, and since we're just gating an envelope, we don't need some complicated value sequence — just any positive number is fine.

(
SynthDef(\d, {
	var freq, sig, trig, deg;
	trig = TDuty.ar(
		Dseq([ 0.75, 0.75, 0.5 ], inf),
		0,
		1
	);
	deg = Duty.ar(
		1/8,
		0,
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(sig, 1500);
	sig = sig * Env.perc(0.005, 0.5).ar(gate: trig);
	Out.ar(0, sig);
}).play;
)

A very analog synth thing to do is modulate the cutoff frequency with another envelope controlled by the same trigger signal.

(
SynthDef(\d, {
	var freq, sig, trig, deg;
	trig = TDuty.ar(
		Dseq([ 0.75, 0.75, 0.5 ], inf),
		0,
		1
	);
	deg = Duty.ar(
		1/8,
		0,
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg) + 50).midicps;
	freq = freq * { Rand(-0.1, 0.1).midiratio }.dup(4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(
		sig,
		Env(
			[100, 1500, 100],
			[0.05, 0.75],
			-4
		).ar(gate: trig)
	);
	sig = sig * Env.perc(0.005, 0.5).ar(gate: trig);
	Out.ar(0, sig);
}).play;
)

If we want a chord progression, all we have to do is create some array representing a stack of scale degrees, and add it to the base degree value, taking advantage of multichannel expansion. I'm also gonna slow things down, because 8 chord changes per second seems a little fast.

(
SynthDef(\d, {
	var freq, sig, trig, deg;
	trig = TDuty.ar(
		Dseq([ 0.75, 0.75, 0.5 ], inf),
		0,
		1
	);
	deg = Duty.ar(
		2,
		0,
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, deg + [ 0, 4, 6, 7, 8, 9 ]) + 50).midicps;
	freq = freq * ({ Rand(-0.1, 0.1).midiratio} ! 4);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(
		sig,
		Env(
			[100, 1500, 100],
			[0.05, 0.75],
			-4
		).ar(gate: trig)
	);
	sig = sig * Env.perc(0.005, 0.5).ar(gate: trig);
	Out.ar(0, sig);
}).play;
)

Dconst is worth highlighting here, I think, it outputs values according to its second input until the sum of those values would exceed the threshold represented by the first value, at which point it truncates the last value to fit. So, in this specific case we'll get 0.75, five times in a row, which adds up to 3.75, and the sixth value is shortened to 0.25. We're gonna wrap this in a Dseq so that the whole process repeats. And then, some finishing touches, an LFO for the envelope release, another LFO modulating cutoff frequency, and we'll throw some delay and reverb on the end.

(
SynthDef(\d, {
	var freq, sig, trig, deg;
	trig = TDuty.ar(
		Dseq([
			Dconst(4, 0.75),
		], inf),
		0,
		1
	);
	deg = Duty.ar(
		2,
		0,
		Dseq([ 0, 2, -1, -3 ], inf)
	);
	freq = (DegreeToKey.ar(b, [0, 4, 6, 7, 8, 9] + deg) + 50).midicps;
	freq = freq * ({ Rand(-0.1, 0.1).midiratio} ! 6);
	sig = Saw.ar(freq);
	sig = Splay.ar(sig);
	sig = MoogFF.ar(
		sig,
		Env(
			[100, LFTri.kr(1/16, 3).exprange(200, 2500), 100],
			[0.05, 0.75],
			-4
		).ar(gate: trig)
	);
	sig = sig * Env.perc(0.005, LFTri.kr(1/16, 3).exprange(0.15, 4)).ar(gate: trig);
	sig = sig + CombN.ar(sig, 0.5, 0.5, 4, -12.dbamp);
	sig = sig.blend(LPF.ar(GVerb.ar(sig, 200, 5).sum, 1000, 0.33));
	Out.ar(0, sig);
}).play;
)

So, nice little collection of UGens, and pretty convenient, I think, being able to put pattern-style logic straight into a SynthDef. Hope this gives you some fun ideas to explore, shoutout to my supporters on Patreon, thank you all for the support, I really appreciate it. If you enjoyed this video, please like and subscribe, thanks for watching, see you next time.