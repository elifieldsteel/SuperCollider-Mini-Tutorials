Back in like 2010 I discovered a SCtweet by Nathaniel Virgo, posted as @headcube that caught my attention, and sounds like this:

play{GVerb.ar(VarSaw.ar(Duty.ar(1/5,0,Dseq(x=[[4,4.5],[2,3,5,6]];flat(x*.x allTuples(x*.x x)*4).clump(2)++0)),0,0.9)*LFPulse.ar(5),99,5)/5}

Link in the video description, go check it out, listen to some of the other ones too, they're all fantastic. As an exercise, I like to deconstruct these to understand them better, feel free to pause and study this exploded version at your own pace:

(
var freq;
x = [ [4,4.5], [2,3,5,6] ];
freq = x *.x x;
freq = allTuples(freq);
freq = x *.x freq;
freq = freq * 4;
freq = freq.flat;
freq = freq.clump(2);
freq = freq ++ 0;

{
	var demand, sig;
	demand = Duty.kr(1/5, 0, Dseq(freq));
	sig = VarSaw.ar(demand, 0, 0.9);
	sig = sig * LFPulse.ar(5);
	sig = GVerb.ar(sig, 99, 5);
	sig = sig / 5;
}.play;
)

Back then, there was one part of this tweet I could. not. figure out, and it was this here: "x space asterisk period x space x." My reaction at the time was "well, this is complete nonsense" forgot about it for awhile until like like a decade later, I posted a question on scsynth.org, and mystery solved, turns out it's pretty interesting.

This x and this x refer to this array of arrays of numbers. This asterisk means multiplication, like it usually does, but this .x here is called an adverb, it's an additional argument provided to the binary operator that changes its behavior — a binary operator being some symbol or method applied to a pair of values, like this plus that, this to the power of that, etc.

[Operators HF]

17 + 3
17 ** 3

Adverbs are documented in a file called "Adverbs for Binary Operators," and, this concept also appears in a file called "J Concepts in SC".

And...by the way, the fact the array and the adverb are both named x, is a total coincidence, which is kind of confusing, so you can rename the array, if you like.

(
var freq;
z = [ [4,4.5], [2,3,5,6] ];
freq = z *.x z;
freq = allTuples(freq);
freq = z *.x freq;
freq = freq * 4;
freq = freq.flat;
freq = freq.clump(2);
freq = freq ++ 0;

{
	var demand, sig;
	demand = Duty.kr(1/5, 0, Dseq(freq));
	sig = VarSaw.ar(demand, 0, 0.9);
	sig = sig * LFPulse.ar(5);
	sig = GVerb.ar(sig, 99, 5);
	sig = sig / 5;
}.play;
)

So here's the deal. In SC, a binary operation with a number and an array is defined such that the operation is applied to the number and each item in the array, resulting in a new array of the same size.

100 + [1, 2, 3, 4, 5, 6, 7];

For an operation with two arrays, the default behavior is to apply the operation to corresponding pairs, and if the sizes of the arrays are different, wrap to the beginning of the the short array and start over as many times as needed to accommodate the long array. In this case we get 100 plus 1, 200 plus 2, 300 plus 3, then wrap the shorter one, and we continue with 100 plus 4, 200 + 5, etc.

[100, 200, 300] + [1, 2, 3, 4, 5, 6, 7];

Adverbs change this default behavior. .s stands for short, which means the shorter array determines the length of the result.

[100, 200, 300] +.s [1, 2, 3, 4, 5, 6, 7];

.f means folding, instead of wrapping, so when we get to the end of the short array, we bounce back and go the opposite direction, bouncing back and forth as many times as needed to accommodate the long array, so here notice the hundredths place goes 1232123

[100, 200, 300] +.f [1, 2, 3, 4, 5, 6, 7];

.t is "table," and this is where things get interesting, the result is a multidimensional array, so in this case an array containing three arrays, each containing seven numbers, and the operation is applied to every possible pair of values from the first and second array.

[100, 200, 300] +.t [1, 2, 3, 4, 5, 6, 7];

dot-x, which I think means "cross", almost the same as table, except it removes the inner brackets and the the result is just one large array

[100, 200, 300] +.x [1, 2, 3, 4, 5, 6, 7];

keep in mind this syntax works for any binary operator with a symbolic representation, like subtraction...division...etc.

[100, 200, 300] -.x [1, 2, 3, 4, 5, 6, 7];
[100, 200, 300] /.x [1, 2, 3, 4, 5, 6, 7];
[100, 200, 300] %.x [1, 2, 3, 4, 5, 6, 7];

For operators that don't have symbolic representation, for example the least common multiple,

lcm(6, 8)

the syntax needs to be a little different, you can either put method colon dot adverb between the arrays:

[100, 200, 300] lcm:.x [1, 2, 3, 4, 5, 6, 7];

Or receiver.method style, and in parentheses, comma after the second array, followed by a symbol representing the adverb.

[100, 200, 300].lcm([1, 2, 3, 4, 5, 6, 7], \x);

So, cool that you can modify this behavior, but not immediately clear why it's useful, and where I think this trick really shines is generating pitch collections. Let's say you want to generate a list of all the MIDI notes on the 88-key piano keyboard that belong to the key of A minor. We can get the raw scale degrees like this:

Scale.minor.degrees;

Note numbers on the piano range from 21 to 108. So here's one way to do it, maybe not the most optimal, but it works. Start with an array of a bunch of octave transpositions, and cross-add with the minor scale, and then add 21 to start on the correct note. 127 is higher than we need, so we can use reject to iterate and remove anything greater than 108.

(
f = (0,12..96) +.x Scale.minor.degrees + 21;
f = f.reject({ |n| n>108 });
)

And there you go. So hopefully you can imagine all the complex interesting data collections you can concisely generate with these adverbs. And by the way if one day you find yourself with a lot of caffeine and nothing else to do, I recommend you browse through this J Concepts guide, because some of this stuff is...pretty cool.

So, thanks to Nathaniel Virgo @headcube for letting me feature this awesome tweet, and very special shoutout to my Patrons for the support, huge thanks, much appreciated, and to everyone, hope this helps, thanks for watching.