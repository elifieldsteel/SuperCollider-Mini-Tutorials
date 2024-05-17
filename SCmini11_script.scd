Clock dividers and step sequencers are two examples of tools that interact with trigger signals and allow us to do interesting things with timing and rhythm. In SuperCollider, these tools are called PulseDivider and Stepper, so let's take a look at how they work and what they can sound like. So, here, I've got 15 pulses per second, fed to PulseDivider, which also takes a division value. PulseDivider counts pulses, and when count equals div, it outputs a pulse of its own and resets the count to zero. These signals generate single-sample impulses, which generally don't show up nicely on a plot, but we can use Trig to extend them and make them more visible.

(
{
	var clock, pdiv;
	clock = Impulse.ar(15);
	pdiv = PulseDivider.ar(clock, div: 2);
	Trig.ar([clock, pdiv], SampleDur.ir * 50);
}.plot(0.5, bounds: Rect(150, 300, 1600, 500), minval: -0.1, maxval: 1.1);
)

As you can see, PulseDivider gives one pulse for every two received. Multichannel expansion lets us simultaneously view division by 2, 3, 4, you get the idea.

(
{
	var clock, pdiv;
	clock = Impulse.ar(15);
	pdiv = PulseDivider.ar(clock, div: [2, 3, 4]);
	Trig.ar([clock, pdiv].flat, SampleDur.ir * 50);
}.plot(0.5, bounds: Rect(150, 100, 1600, 800), minval: -0.1, maxval: 1.1);
)

The start parameter offsets the initial count, it's essentially a phase control, here's division by three with start values 0, 1, and 2. If start equals div minus one, as it does here at the bottom, PulseDivider will generate a pulse right at the beginning.

(
{
	var clock, pdiv;
	clock = Impulse.ar(15);
	pdiv = PulseDivider.ar(clock, div: 3, start: [0, 1, 2]);
	Trig.ar([clock, pdiv].flat, SampleDur.ir * 50);
}.plot(0.5, bounds: Rect(150, 100, 1400, 800), minval: -0.1, maxval: 1.1);
)

PulseDivider is a good option for polyrhythms, like 3 against 4:

(
{
	var clock, pdiv, sig, div = [3, 4];
	clock = Impulse.ar(15);
	pdiv = PulseDivider.ar(clock, div: div, start: div - 1);
	sig = SinOsc.ar([500, 900]) * Env.perc(0.002, 0.1).ar(gate: pdiv) * 0.1;
}.play(fadeTime: 0);
)

Now, even though the array is 3 comma 4, we hear four pulses on the left and three on the right. It might seem like it should be the other way around, but these div values represent duration per pulse, in other words, a smaller number means more frequent pulses. So the rhythm we actually hear is least common multiple divided by div:

12 / [3, 4];

This means, for example, if we want to hear 3 against 4 against 5, the div array needs to be 20, 15, 12:

60 / [3, 4, 5];

(
{
	var clock, pdiv, sig, div = [20, 15, 12];
	clock = Impulse.ar(60);
	pdiv = PulseDivider.ar(clock, div: div, start: div - 1);
	sig = SinOsc.ar([500, 900, 1300]) * Env.perc(0.002, 0.1).ar(gate: pdiv) * 0.1;
	Splay.ar(sig);
}.play(fadeTime: 0);
)

My advice, though, don't get distracted by the math, instead, just throw numbers at it until it sounds good. For example, here, div is the integers 2 through 20, used to divide pulses and also interpreted as scale degrees to generate pitch information.

(
{
	var clock, pdiv, notes, sig, div = (2..20);
	clock = Impulse.ar(15);
	pdiv = PulseDivider.ar(clock, div: div, start: div - 1);
	notes = DegreeToKey.kr(
		LocalBuf.newFrom(Scale.lydian.degrees),
		div - 2
	) + 64;
	sig = SinOsc.ar(notes.midicps) * Env.perc(0.002, 0.1).ar(gate: pdiv) * 0.1;
	Splay.ar(sig);
}.play(fadeTime: 0);
)

Here's a sampling example, where PulseDivider triggers and multichannel expands PlayBuf, and start positions are derived by mapping div values across the length of the buffer:

b = Buffer.read(s, Platform.resourceDir ++ "/sounds/a11wlk01-44_1.aiff");

(
{
	var clock, pdiv, sig, div = (2..20);
	clock = Impulse.ar(15);
	pdiv = PulseDivider.ar(clock, div: div, start: div - 1);
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b),
		trigger: pdiv,
		startPos: div.linlin(2, 21, 0, BufFrames.ir(b)),
	);
	sig = sig * Env.perc(0.002, 0.1).ar(gate: pdiv) * 0.5;
	Splay.ar(sig);
}.play(fadeTime: 0);
)

Definitely consider swapping this sample for a drum loop, or something else inherently rhythmic, it can be a lot of fun to chop up something like that, but for now let's move on to Stepper, which also counts pulses, but outputs the count value itself, which repeatedly goes from min to max, in this case 0 to 15, also, it can be a good idea to provide a one-time reset trigger which forces Stepper to start at its min value, otherwise the first clock pulse makes it start one value higher. We'll poll to visualize the step count, and sonify each 16th note with white noise.

(
{
	var metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
}.play(fadeTime: 0);
)

To put a tone on each downbeat, we can gate the tone envelope with step < 1, which of course, is only true at the beginning of each cycle. This works because on the server, a conditional check is 1 if true, 0 if false.

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step < 1) * 0.3;
	blip + metro;
}.play(fadeTime: 0);
)

If we modulo step count by half the cycle size, we get a blip on every half note:

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step % 8 < 1) * 0.3;
	blip + metro;
}.play(fadeTime: 0);
)

Subdividing again puts a blip on every quarter note:

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step % 4 < 1) * 0.3;
	blip + metro;
}.play(fadeTime: 0);
)

And suppose we want four blips, one on each of the first four 16th notes of the cycle, it might seem correct to gate with step < 4,

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step < 4) * 0.3;
	blip + metro;
}.play(fadeTime: 0);
)

but this doesn't work because step < 4 is consistently true for the first four steps, so we just get one large trigger at the start of the cycle.

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step < 4) * 0.3;
	[Trig.ar(clock, SampleDur.ir * 100), step/8, step < 4];
}.plot(1, bounds: Rect(150, 100, 1400, 800), minval: -0.1, maxval: 1.1);
)

The correct approach is to multiply the conditional by the clock, and that gives us the appropriate gate signal:

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step < 4) * 0.3;
	[Trig.ar(clock, SampleDur.ir * 100), step/8, step < 4 * Trig.ar(clock, SampleDur.ir * 100)];
}.plot(1, bounds: Rect(150, 100, 1400, 800), minval: -0.1, maxval: 1.1);
)

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step < 4 * clock) * 0.3;
	blip + metro;
}.play(fadeTime: 0);
)

To shift this cluster of notes to a later beat, we can subtract a value from step, and modulo by total steps to wrap back to the correct range:

(
{
	var blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step - 4 % 16 < 4 * clock) * 0.3;
	blip + metro;
}.play(fadeTime: 0);
)

Modulo values that don't evenly divide the cycle create polyrhythms, so here's a new layer, step minus 2 mod 3 will be less than one on beats 2, 5, 8, 11, and 14, so, sort of a clave-style rhythm:

(
{
	var clave, blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step - 4 % 16 < 4 * clock) * 0.3;
	clave = SinOsc.ar([2300, 2450]) * Env.perc(0, 0.1).ar(gate: step - 2 % 3 < 1 * clock) * 0.2;
	clave + blip + metro;
}.play(fadeTime: 0);
)

I'll paste in a synthesized kick,

(
{
	var kick, clave, blip, metro, clock, step;
	clock = Impulse.ar(10);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15).poll(clock);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step - 4 % 16 < 4 * clock) * 0.3;
	clave = SinOsc.ar([2300, 2450]) * Env.perc(0, 0.1).ar(gate: step - 2 % 3 < 1 * clock) * 0.2;
	kick = SinOsc.ar(
		freq: Env([40, 350, 40], [0.0001, 0.1], -6).ar(gate: step % 4 < 1 * clock),
		mul: Env([0, 0.25, 0], [0.001, 0.6], -6).ar(gate: step % 4 < 1 * clock),
	);
	clave + blip + metro + kick;
}.play(fadeTime: 0);
)

and we've got ourselves a nice little trance beat. Finally, here's an example that combines PulseDivider and Stepper, basically merging previous examples and adding some varations, pause and study if you like, it sounds like this:

b = Buffer.read(s, Platform.resourceDir ++ "/sounds/a11wlk01-44_1.aiff");

(
x = {
	var pb, sig, kick, clave, blip, metro, notes, clock, pdiv, step, div = (4..16);
	clock = Impulse.ar(\n.kr(8));
	pdiv = PulseDivider.ar(clock, div);
	step = Stepper.ar(clock, reset: Impulse.ar(0), min: 0, max: 15);
	metro = WhiteNoise.ar(0.03 ! 2) * Env.perc(0, 0.01).ar(gate: clock);
	blip = SinOsc.ar(5000 ! 2) * Env.perc(0, 0.05).ar(gate: step - 4 % 16 < 4 * clock) * 0.06;
	clave = SinOsc.ar([2300, 2450]) * Env.perc(0, 0.1).ar(gate: step - 2 % 3 < 1 * clock) * 0.08;
	kick = SinOsc.ar(
		freq: Env([40, 350, 40], [0.0001, 0.1], -6).ar(gate: step % 4 < 1 * clock),
		mul: Env([0, 0.25, 0], [0.001, 0.6], -6).ar(gate: step % 4 < 1 * clock),
	);
	notes = DegreeToKey.kr(LocalBuf.newFrom([0, 3, 5, 7, 10]), div - 2) + 45;
	sig = Pulse.ar(notes.scramble.midicps) * Env.perc(0.001, 0.3).ar(gate: pdiv);
	sig = Splay.ar(
		MoogFF.ar(sig, Env.perc(curve: -12).ar(gate: pdiv).linexp(0, 1, 100, 3000), 2.5),
		spread: 0.75
	);
	pb = Splay.ar(
		PlayBuf.ar(1, b,
			rate: BufRateScale.ir(b) * (8 - step).midiratio,
			trigger: pdiv,
			startPos: div/20 * BufFrames.ir(b)
		) * Env.perc(0.002, 0.1).ar(gate: pdiv),
		spread: 0.75
	);
	sig = [pb * 2, sig, clave, blip, metro, kick].sum;
	sig = sig.blend(LPF.ar(GVerb.ar(sig.sum, 300, 4), 1500), 0.015);
}.play(fadeTime: 0);
)

x.set(\n, 4);

x.set(\n, 2);

x.set(\n, 0);

x.free;

Patreon.thanks;

Many more ideas left unexplored, I hope this gives you some fun ideas to play with, shoutout to my Patrons, huge thanks to all of you, for the support, I really appreciate it. If you're new and you enjoyed this video please like and subscribe, and I hope you'll consider becoming a Patron yourself, thanks for watching, see you next time.