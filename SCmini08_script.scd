Randomness is a big part of computer music, you can check out the guide file called Randomness for an overview. When we generate random numbers in sclang, we get a convincingly random sequence. And if we go get a cup of coffee, come back five minutes later and do it again, we're virtually guaranteed to get a different sequence.

rrand(0,99);

But, it *is* possible to reproduce a specific random sequence, because, fun fact, computer-generated randomness is not random at all — it's completely deterministic, but the algorithm is complex enough that the human brain just can't see it, so for us, if it "feels" random, then for all intents and purposes, it is.

A random number generator, or RNG, begins with a seed, some integer that provides a starting point for the algorithm. The simplest way to seed sclang's RNG is "thisThread", dot randSeed, equals some integer, let's do 24.

thisThread.randSeed = 24;

Then, generate some random numbers

rrand(0,99);

...seems random enough. But, reseed,

thisThread.randSeed = 24;

rrand(0,99);

we'll get the exact same sequence every time. And this applies to any random choice that sclang makes, like choosing from an array...

(
thisThread.randSeed = 24;
4.do({ [1,2,3,4,5].choose.postln });
)

flipping a coin...

(
thisThread.randSeed = 24;
4.do({ 0.5.coin.postln });
)

or using a different method, like exprand.

(
thisThread.randSeed = 24;
4.do({ exprand(80, 8000).postln });
)

And, if we change the seed, even by the smallest possible amount, the results are completely different.

(
thisThread.randSeed = 25;
4.do({ exprand(80, 8000).postln });
)

(
thisThread.randSeed = 26;
4.do({ exprand(80, 8000).postln });
)

So, let's unpack what "thisThread" actually means. In the SuperCollider language, the context in which code runs is called a thread, and right now, we're in the main, top-level thread, so at the moment, that's what thisThread refers to.

thisThread

There's a class called Thread, which mainly exists to provide a framework for its subclass, Routine, a special type of function that can pause and resume. Routines inherit the RNG seed from their parent thread, in other words, the thread in which they were created.

So if the main thread seed is 24,

thisThread.randSeed = 24;

then this Routine has the same seed, and produces the same sequence from before — 27, 72, 99

(
r = Routine.new({
	loop{
		rrand(0,99).postln;
		0.4.wait;
	};
});

r.play;
)

r.stop;

But, a Routine can have its own seed. One option is to use the randSeed method on the routine, before it plays, and just like that, different numbers.

thisThread.randSeed = 24;

(
r = Routine.new({
	loop{
		rrand(0,99).postln;
		0.4.wait;
	};
});
r.randSeed = 25;
r.play;
)

r.stop;

Or, you can use thisThread *inside* the Routine, in which case it refers to the new child thread, instead of the main parent thread.

thisThread.randSeed = 24;

(
r = Routine.new({
	thisThread.randSeed = 25;
	loop{
		rrand(0,99).postln;
		0.4.wait;
	};
});

r.play;
)

r.stop;

In this case, resetting the routine has the side effect of reseeding the RNG, because reseeding takes place *in* the routine.

r.reset.play;

r.stop;

And just to clarify the subtleties, if the top-level seed is 24 and we grab a couple numbers, 27, 72,

thisThread.randSeed = 24;
rrand(0,99)

we already know the next one is gonna be 99. Even if we let this routine blow through a few numbers

(
r = Routine.new({
	thisThread.randSeed = 25;
	loop{
		rrand(0,99).postln;
		0.4.wait;
	};
});

r.play;
)

r.stop;

It has no effect on the RNG of the parent thread — case in point, 99, still next in line.

rrand(0,99);

Ok, let's make some sound. Here's a routine called ~soundMaker, that plays a UGen function, and waits, and loops these two steps. The UGen function picks 8 random frequencies, sums 8 sine waves, and applies an envelope. Sounds like this...

(
~soundMaker = Routine.new({
	loop{
		{
			var sig, freq;
			freq = {exprand(80, 8000)}.dup(8);
			sig = 8.collect({
				arg i;
				SinOsc.ar(
					freq: freq[i] * [-0.1, 0.1].midiratio,
					mul: 0.05
				);
			}).sum;
			sig = sig * EnvGen.ar(
				Env.perc(0.002, 0.1),
				doneAction:2
			);
		}.play(fadeTime:0);

		1.wait;
	};
});
)

And a second looping routine to create a musical sequence. The first thing it does is seed the first routine, we'll give it a value in just a second. Then, jumps into an iteration block, six times in row calls 'next' on the first routine, and then waits for point 12 seconds. calling 'next' on a routine tells it to start evaluating, and come to a full stop if runs into a wait. So this 1 is totally arbitrary, it could be any number, and you can also replace 'wait' with 'yield,' same result. So, when using next, this line is like a traffic cop that says "stop, and I will tell you when you can go."

(
~player = Routine.new({
	loop{
		~soundMaker.randSeed_(~seed);
		6.do{
			~soundMaker.next;
			0.12.wait;
		};
	};
});
)

Prepare a seed value,

~seed = 44;

And play the second routine, you'll notice that we get 6 random bloops that repeat indefinitely:

~player.play;

~player.stop;

And because ~seed is a "global" variable inside a continually re-evaluated process, we can swap it out in real-time, but the seed only updates at the beginning of a six-note cycle, so the rhythm is preserved.

~player.reset.play;
~seed = 45;
~seed = 44;
~seed = 46;
~seed = 44;
~player.stop;

Lots of variations to explore. But, an important observation, all these techniques are exclusively language-side, so it only applies to RNG in sclang, not on the server. And to demonstrate, if we swap the exprand method for the ExpRand UGen:

(
~soundMaker = Routine.new({
	loop{
		{
			var sig, freq;
			freq = {ExpRand(80, 8000)}.dup(8);
			sig = 8.collect({
				arg i;
				SinOsc.ar(
					freq: freq[i] * [-0.1, 0.1].midiratio,
					mul: 0.05
				);
			}).sum;
			sig = sig * EnvGen.ar(
				Env.perc(0.002, 0.1),
				doneAction:2
			);
		}.play(fadeTime:0);

		1.wait;
	};
});
)

The behavior's different — the randomness doesn't repeat, because now the RNG lives on the server, an entirely different program with a separate RNG mechanism. It is possible to do seeded randomness on the server, but, too much for a five minute video, so I'm gonna save that for a future tutorial, but if you want a push in the right direction, take a look at RandID and RandSeed.

So that's it for this tutorial, big thanks to my Patrons, love you all, truly appreciate the support, thank you so so much, and to everyone, hope this helps, thanks for watching.