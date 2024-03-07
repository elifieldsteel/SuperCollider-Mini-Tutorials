When a Synth is running, we often use a 'set' message to change a control value, and when we do, that change happens more or less instantaneously... But maybe that's not what you want, or maybe at some point you asked yourself, is there an easy way to slide from one value to the next over a period of time?

s.boot;

(
SynthDef(\gliss, {
	arg freq=440, gate=1, amp=0.3, out=0;
	var sig, env;
	env = EnvGen.kr(Env.asr, gate, doneAction:2);
	sig = SinOsc.ar(freq)!2;
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

x = Synth(\gliss);
x.set(\freq, 72.midicps);
x.set(\freq, 74.midicps);
x.set(\gate, 0);

In fact, there is. Lag is a UGen, essentially a type of lowpass filter that causes a signal to interpolate between changes over a period of time. In the case of pitch, it creates a glissando effect, and in more general terms, Lag makes a signal behave sluggishly, like it's moving through molasses. But the best way to understand how it works is to hear it.

This frequency argument here, all we have to do is pass it through a Lag, and provide the desired lag time, in seconds. Once the sound is running, whenever that value changes, it takes that much time to actually get there.

(
SynthDef(\gliss, {
	arg freq=440, gate=1, amp=0.3, out=0;
	var sig, env;
	freq = Lag.kr(freq, 1);
	env = EnvGen.kr(Env.asr, gate, doneAction:2);
	sig = SinOsc.ar(freq)!2;
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

x = Synth(\gliss);
x.set(\freq, 72.midicps);
x.set(\freq, 74.midicps);
x.set(\gate, 0);

As a slightly shorter alternative, we can use the convenience method, dot-lag.

(
SynthDef(\gliss, {
	arg freq=440, gate=1, amp=0.3, out=0;
	var sig, env;
	freq = freq.lag(1);
	env = EnvGen.kr(Env.asr, gate, doneAction:2);
	sig = SinOsc.ar(freq)!2;
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

x = Synth(\gliss);
x.set(\freq, 74.midicps);
x.set(\gate, 0);

Keep in mind this lag time doesn't have to be fixed — you can add a new argument for the lag time, and set it as fast or slow as you like.

(
SynthDef(\gliss, {
	arg freq=440, freqlag=1, gate=1, amp=0.3, out=0;
	var sig, env;
	freq = freq.lag(freqlag);
	env = EnvGen.kr(Env.asr, gate, doneAction:2);
	sig = SinOsc.ar(freq)!2;
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

x = Synth(\gliss);
x.set(\freq, 76.midicps, \freqlag, 0.25);
x.set(\freq, 71.midicps, \freqlag, 3);
x.set(\freq, 80.midicps, \freqlag, 0);
x.set(\gate, 0);

And, of course, you can effectively bypass a lag by setting the lag time to zero...but don't use negative numbers for lag times — or use them at your own risk because...weird stuff starts to happen.

Ok, so Lag gives us control over the duration of the interpolation, but it doesn't give any control over the shape of the interpolation curve, which, in the case of Lag, is always exponential. And it's for this reason that I usually prefer VarLag, which has a similar convenience method. In addition to a lag time, varlag accepts a curve value. And the behavior here is exactly like curve values for envelopes: 0 is linear, positive values bend the shape so that the value changes slowly at first, then quickly toward the end, negative values bend in the opposite way, and as this value gets further away from zero, the shape of the curve becomes more extreme.

(
SynthDef(\gliss, {
	arg freq=440, freqlag=1, freqcrv=0, gate=1, amp=0.3, out=0;
	var sig, env;
	freq = freq.varlag(freqlag, freqcrv);
	env = EnvGen.kr(Env.asr, gate, doneAction:2);
	sig = SinOsc.ar(freq)!2;
	sig = sig * amp;
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

x = Synth(\gliss);

So, here's our tone going down an octave over 2 seconds, linearly:
x.set(\freq, 220, \freqlag, 2, \freqcrv, 0);

Going up an octave, with a positive curve:
x.set(\freq, 440, \freqlag, 2, \freqcrv, 15);

And down an octave once more with a negative curve:
x.set(\freq, 220, \freqlag, 2, \freqcrv, -15);

x.set(\gate, 0);

When applied to pitch, negative curves tend to be more useful, because when a value changes, a negative curve moves it close to its target quickly and then levels off, which is kind of the natural most common way to perform a glissando, whereas positive curves cause the value to stay mostly where it is until the very end of the lag time, so there's kind of this awkward delay.

Lag is not just useful for frequency, it can be applied to just about anything. For example, let's get rid of this envelope, and instead, lag the amplitude, creating a sort of dynamic envelope that can be controlled stage by stage, using set messages:

(
SynthDef(\gliss, {
	arg freq=440, freqlag=1, freqcrv=0, amplag=2, ampcrv=0, gate=1, amp=0, out=0;
	var sig;
	freq = freq.varlag(freqlag, freqcrv);
	sig = SinOsc.ar(freq)!2;
	sig = sig * amp.varlag(amplag, ampcrv);
	Out.ar(out, sig);
}).add;
)

x = Synth(\gliss);
x.set(\amp, 0.3, \amplag, 1, \ampcrv, -2);
x.set(\amp, 0, \amplag, 3, \ampcrv, -8);
x.free;

Another use for Lag, if you have an external physical controller, like a motion sensor or something, that kind of data tends to be jumpy, and typically you don't want to plug that straight into your synthesis algorithm, because it usually makes your sound all wobbly and unstable. Lag is very handy here, capable of smoothing out that data once it is mapped onto some SynthDef argument, softening all the hard edges and becoming much friendlier for musical applications.

A quick note about varlag, though it is useful and flexible, it can exhibit weird behavior if applied to an audio-rate signal, as discussed in this warning at the top of the help file.

But, Lag has a few other siblings, Lag2 and Lag3 are shortcuts for double- and triple-nested Lags, so to wrap up, here's one more example to help visualize these behaviors. Here, sig is a sample & hold noise generator, basically a random staircase shape, producing 50 random values per second, and we're gonna plot half a second of five different signals: the original noise, that noise passed through lag, lag2, lag3, and finally, two lag3s in series, which would be the equivaleant of lag6, each with a lag time of 0.01, and as you can see, all these signals get progressively smoother as we lag them more aggressively.

(
{
	var sig;
	sig = LFNoise0.kr(50);
	[
		sig,
		sig.lag(0.01),
		sig.lag2(0.01),
		sig.lag3(0.01),
		sig.lag3(0.01).lag3(0.01)
	];
}.plot(0.5, bounds:Rect(100,200,1700,750));
)

So that's most of the Lag family in a nutshell, pretty handy, almost kind of essential in some cases. Use it well, and have fun smoothing out all your signals. Shoutout to my awesome patrons, you all are the best, thank you so much for supporting these tutorials. To everyone, hope this helps, thanks for watching.