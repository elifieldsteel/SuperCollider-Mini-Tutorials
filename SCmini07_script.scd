Here's a problem pretty much everybody runs into at some point, it has to do with using conditional logic inside of a SynthDef. Documented in a reference file called Control Structures, conditional logic refers to things that control the flow of information in a program, like if. Here's an example that works correctly: We have a function with an argument. If it's 0, play a tone, otherwise, play some noise.

s.boot;

(
f = {
	arg num=0;
	if(
		num == 0,
		{ {SinOsc.ar(500) * 0.2!2 }.play },
		{ {PinkNoise.ar(1) * 0.2!2}.play }
	);
};
)

f.value([0,1].choose.postln);

And, it seems reasonble to rewrite this code as a SynthDef with the conditional logic inside,

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	if(
		num == 0,
		{ sig = SinOsc.ar(500) },
		{ sig = PinkNoise.ar(1) }
	);
	Out.ar(0, sig * 0.2!2);
}).add;
)

but it will not work correctly. In fact, it's such a common pitfall, it has a dedicated page on the SuperCollider website.

https://supercollider.github.io/tutorials/If-statements-in-a-SynthDef.html

No matter how we manipulate the argument...

x = Synth(\if, [\num, 0]);
x.set(\num, 1);
x.set(\num, 0);
x.free;

we always get noise.

If we change the conditional expression to num less than 1, then the SynthDef fails outright, and says the expression is non-boolean, which -- seems outrageous, because num is 0, and we want to know, is it less than 1...?

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	if(
		num < 1,
		{ sig = SinOsc.ar(500) },
		{ sig = PinkNoise.ar(1) }
	);
	Out.ar(0, sig * 0.2!2);
}).add;
)

So, something fishy is going on here. The key to understanding stems from the fact that SynthDef arguments automatically become instances of a class called Control, it's basically what lets us interact with sounds using set messages. Going back to the version that checks equality with 0, this *if* construct is language-side,

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	if(
		num == 0,
		{ sig = SinOsc.ar(500) },
		{ sig = PinkNoise.ar(1) }
	);
	Out.ar(0, sig * 0.2!2);
}).add;
)

which means, before the server even gets involved, the language says, "oh, it's an if, I need to evaluate this." and it does. So it says is num equal to 0? and to us humans, it looks obviously true, but what's actually being evaluated is this:

Control.kr(0) == 0;

which is false! It's like apples and oranges, comparing a UGen to an Integer. These will never be equal in the eyes of the language. So the result is, and always will be, sig = PinkNoise. If we dumpUGens on the SynthDef, we can see there is no SinOsc present.

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	if(
		num == 0,
		{ sig = SinOsc.ar(500) },
		{ sig = PinkNoise.ar(1) }
	);
	Out.ar(0, sig * 0.2!2);
}).dumpUGens;
)

So, from the server's perspective, it actually just looks like this:

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	sig = PinkNoise.ar(1);
	Out.ar(0, sig * 0.2!2);
}).add;
)

Now, the version with less than 1:

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	if(
		num < 1,
		{ sig = SinOsc.ar(500) },
		{ sig = PinkNoise.ar(1) }
	);
	Out.ar(0, sig * 0.2!2);
}).add;
)

What the language sees is this:

Control.kr(0) < 1;

which returns a BinaryOpUGen, another type of UGen created behind the scenes. Most other binary operations produce the same result, the equality check is actually one of the few exceptions.

Control.kr(0) + 1;
Control.kr(0) - 1;
Control.kr(0) == 1;

A BinaryOpUGen is non boolean - it's neither true nor false, so the language doesn't know what to do, and we get an error.

So, is it possible to use conditional logic in a SynthDef? Yes. But — we have to think about it a little differently. An easy solution is the Select UGen, basically the closest thing we have to a UGen version of if. We provide a number, and the integer part is used as an index into a UGen array.

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	sig = Select.ar(
		num,
		[
			SinOsc.ar(500),
			PinkNoise.ar(1)
		]
	);
	Out.ar(0, sig * 0.2!2);
}).add;
)

x = Synth(\if, [\num, 0]);
x.set(\num, 1);
x.set(\num, 0);

Related to this is SelectX which crossfades between adjacent signals when the index is a non-integer, and as a throwback to mini tutorial 3, we'll put a varlag on the index:

(
SynthDef.new(\if, {
	arg num=0;
	var sig;
	sig = SelectX.ar(
		num.varlag(2),
		[
			SinOsc.ar(500),
			PinkNoise.ar(1)
		]
	);
	Out.ar(0, sig * 0.2!2);
}).add;
)

x = Synth(\if, [\num, 0]);
x.set(\num, 1);

Select has other applications, too — here's it's just looking up values in a table to create an arpeggiator, combining topics from mini tutorials 5 and 6:

(
SynthDef.new(\if, {
	var notes, index, freq, sig;
	notes = (0,7..42) +.x [0,4];
	index = LFSaw.kr(1,1).range(0, notes.size.postln);
	freq = Select.kr(index, notes);
	freq = (freq + 50).midicps;
	sig = SinOsc.ar(freq);
	Out.ar(0, sig * 0.2!2);
}).add;
)

Synth(\if);

The downside of Select is that all UGens in the array are continuously running, even when not selected, so computational efficiency is a consideration. But, forget about Select for a moment — conditional expressions do have meaning on the server, but the results are represented using 1 and 0 instead of true and false. Here, the amplitude of pink noise randomly moves between 0.02 and 0.5. If it's greater than 0.1, isLoud has a value of 1, otherwise, 0.

(
{
	var sig, amp, isLoud;
	sig = PinkNoise.ar(1!2);
	amp = LFDNoise3.kr(4).exprange(0.02,0.5);
	isLoud = amp > 0.1;
	isLoud.poll;
	sig = sig * amp;
}.play;
)

And this is really useful, if we think in terms of mathematical signal manipulation. For example, it could be used as a kind of gate, to turn something on or off depending on the condition. Here, we mix in an impulse generator which turns on whenever the amplitude of the noise is below threshold.

(
{
	var sig, amp, isLoud, imp;
	sig = PinkNoise.ar(1!2);
	amp = LFDNoise3.kr(4).exprange(0.02,0.5);
	isLoud = amp > 0.1;
	isLoud.poll;
	imp = Impulse.ar([19,20], mul:0.25);
	imp = imp * (1 - isLoud).lag(0.1);
	sig = sig * amp;
	sig = sig + imp;
}.play;
)

Lots of other possibilities, these conditionals can do some really sophisticated things with signal logic — the hardest part, I think, is training yourself *not* to think in conventional terms of if-then-else, and instead think in terms of 1s and 0s, and mathematically weave these numbers into your algorithms to get the results you want.

So, that's it for this tutorial, shoutout and big thanks as always to my awesome patrons, I hugely appreciate the ongoing support, thank you so, so much. And to everyone, hope this helps lift the fog around using if inside of a SynthDef, thanks for watching.