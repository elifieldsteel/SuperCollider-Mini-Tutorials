Figuring out the nuts and bolts of using patterns to express certain musical ideas can sometimes be tricky. As an example, let's consider the following sequence that plays four random low notes, followed by four random high notes, again and again indefinitely:

s.boot;

(
p = Pbind(
	\midinote, Pseq([
		Pxrand([51,53,55,58],4),
		Pxrand([72,75,77,79],4)
	],inf),
	\sustain, 0.02,
	\dur, 0.15,
	\amp, 0.5,
);

q = p.play;
)

q.stop;

And, let's imagine we want the number of *low* notes to be different every time this pattern is embedded, like, instead of always four, a random integer between 2 and 5. And feel free to pause here and see if you can figure out a way to do this. There are multiple solutions, which is like, welcome to patterns, but for this video there's a specific sort of solution I want to focus on.

You might be tempted to use rrand, which seems reasonable, but it won't work, — or at least, it won't work correctly. The number of low notes will be random, but it'll be the *same* random number every time we roll back around to this Pxrand.

(
p = Pbind(
	\midinote, Pseq([
		Pxrand([51,53,55,58],rrand(2,5)),
		Pxrand([72,75,77,79],4)
	],inf),
	\sustain, 0.02,
	\dur, 0.15,
	\amp, 0.5,
);

q = p.play;
)

q.stop;

In that case, we happened to roll a 2, and so that value gets baked into this Pbind and we're stuck with it. So, one option that *does* work here is to enclose the random expression in curly braces, so that it becomes a function. And by doing so, in a sense, we're deferring the evaluation of this code until the Stream that plays this Pbind actually needs to know what the value is, at which point it'll evaluate the function and obtain a new, random number each time:

(
p = Pbind(
	\midinote, Pseq([
		Pxrand([51,53,55,58],{rrand(2,5)}),
		Pxrand([72,75,77,79],4)
	],inf),
	\sustain, 0.02,
	\dur, 0.15,
	\amp, 0.5,
);

q = p.play;
)

q.stop;

So that's one solution to this problem, and it works perfectly well in cases where the algorithm can be expressed using one or more language methods, like rrand, exprand, array.choose, etc. But — what if we want something more complex than just pick a random number? For example, let's say we want 1 low note, followed by 4 high notes, then 2 low notes followed by 4 high, then 3 then 4, then 4 then 4, etc, just adding a new low note each time. You might very reasonably think to yourself, aha, I know the perfect pattern for this, and go grab a Pseries, that starts at one, adds one each time, goes on forever.

(
p = Pbind(
	\midinote, Pseq([
		Pxrand([51,53,55,58],Pseries(1,1,inf)),
		Pxrand([72,75,77,79],4)
	],inf),
	\sustain, 0.02,
	\dur, 0.15,
	\amp, 0.5,
);

q = p.play;
)

q.stop;

But this does not work, it's just stuck on the low notes somehow. The reason this doesn't work is related to one of *~the most~* central ideas of patterns, and that is the distinction between a pattern and a stream.

A pattern, like this one here, defines some sequence, but it is not the sequence itself. Instead, a Pattern is a recipe, or a blueprint for that sequence. And if all we have is a Pattern, then there is no way for us to actually...get...the output directly from the pattern...

x = Pseries(1,1,inf);
x.next;
x.value;
x.please;

...and that's why this Pseries doesn't work here. Pxrand needs a number of repeats, and a Pseries is not a number. A stream, on the other hand, is a tangible execution of some pattern, and that's what we need, a thing that actually says here's the next number, here's the next number. So we can convert a pattern to a stream using asStream..., I know it says Routine here, but technically a Routine is a type of stream...and then we can call value, or next, on the result, and we actually get the values.

x = Pseries(1,1,inf).asStream;
x.value;
x.next;

So, back to our Pbind, the solution here is to use a stream, derived from a pattern, to control the number of repeats:

(
~reps = Pseries(1,1,inf).asStream;

p = Pbind(
	\midinote, Pseq([
		Pxrand([51,53,55,58],~reps),
		Pxrand([72,75,77,79],4)
	],inf),
	\sustain, 0.02,
	\dur, 0.15,
	\amp, 0.5,
);

q = p.play;
)

q.stop;

There you go. Something important to keep in mind, though, is that the event stream, q,  is *independent* from the Pseries stream ~reps. If we stop the event stream player, and even if you also reset the EventStreamPlayer, doing so does not also reset ~reps, so in a sense that internal stream "remembers" where it left off and will continue from there if we restart the event stream:

q.reset;
q.play;
q.stop;
q.reset;

If you want to reset everything, then the internal stream needs its own reset message, or, even easier, just create the entire thing again and start over.

~reps.reset;

(
~reps = Pseries(1,1,inf).asStream;
p = Pbind(
	\midinote, Pseq([
		Pxrand([51,53,55,58],~reps),
		Pxrand([72,75,77,79],4)
	],inf),
	\sustain, 0.02,
	\dur, 0.15,
	\amp, 0.5,
);

q = p.play;
)

q.stop;

This can be a nice trick to keep in the back pocket, and easy to overlook opportunities to take advantage of pattern/stream subtleties in situations like this. In some cases it can drastically simplify pattern expression of musical ideas, and it's something that I did not really get the hang of until fairly late into my own SuperCollider journey.

Patreon.thanks;

So, special thanks to my patrons, for supporting these tutorials and also for all the lively conversations that have been happening on Patreon about new tutorial ideas, really really appreciate it. And to everyone, hope this helps, thanks for watching.