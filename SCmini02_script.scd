s.boot;

It's pretty common to encounter error messages in SuperCollider, and it can be really frustrating if you don't have strategies for dealing with them. So let's have a look at some of the most common types. Throughout this video, when you see an error, I encourage you to pause and figure it out yourself before moving on — it's good practice.

Let's begin with some code that actually works just fine. But one of the most common problems is not the code itself, but the way it's evaluated. In SuperCollider there are two keystrokes for evaluating code: shift-enter evaluates a single statement based on where the cursor is, and the other keystroke, command-enter on macOS, and control-enter on windows and linux, will evaluate a multi-line chunk enclosed in parentheses, like this here. So, command-enter works just fine, the whole chunk flashes orange, and it's all good. But if I use shift-enter, then only a single line flashes, and SuperCollider will return all sorts of weird and confusing things, depending on where the cursor happens to be. So when you see an error, first thing to do is make sure you used the correct keystroke.

(
x = {
	arg rate=9;
	var sig, note, freq, amp;
	freq = LFNoise0.kr(rate).range(35,85);
	freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);
	amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);
	sig = SinOsc.ar(freq.midicps) * amp;
	sig = sig * 0.2;
}.play;
)

Ok, moving on — this code doesn't work. It says, Class not defined.

(
x = {
	var sig;
	sig = Pulse.ar([100,100.5], 0.5, 0.03);
	sig = sig + SinOsc.ar([150,150.6], 0, 0.15);
	sig = sig + BrowNoise.ar(0.03!2);
	sig = sig * SinOsc.kr(0.3, 3pi/2).exprange(0.1,1);
}.play;
)

When I see any error message, the first thing I like to do is clear the post window, and run it again. This guarantees there's no extra junk in the post window.

This error is pretty easy to deal with. Classes are these things here, they always start with a captial letter, and this message usually means we misspelled a class name. This line number here, line 6, is *relative* to the chunk you just ran. So to sync up the line numbers, highlight the code you just ran, notice the line numbers change. On line 6, the class is BrownNoise, and it's missing a lowercase n.

(
x = {
	var sig;
	sig = Pulse.ar([100,100.5], 0.5, 0.03);
	sig = sig + SinOsc.ar([150,150.6], 0, 0.15);
	sig = sig + BrownNoise.ar(0.03!2);
	sig = sig * SinOsc.kr(0.3, 3pi/2).exprange(0.1,1);
}.play;
)

Here's another example, producing a quite large error message.

(
x = {
	var sig;
	sig = Pulse.ar([100,100.5], 0.5, 0.03);
	sig = sig + SinOsc.ar([150,150.6], 0, 0.15);
	sig = sig + BrownNoise.ar(0.03!2);
	sig = sig * SinOsc.kr(0.3, 3pi/2).exprnage(0.1);
}.play;
)

Step 1, don't freak out! It looks kinda scary, but you know what, don't even look at it, just stay calm and read the summary at the bottom, which says: message "exprnage" not understood, receiver: a SinOsc.

In SuperCollider, code expression often takes the form something-dot-something, for example, 3.cubed. The thing on the left is the receiver, and the thing on the right is the message, or method.

This error tells us an instance of SinOsc is receiving an undefined method, which probably means, like the previous case, we misspelled something. And sure enough, we did. This is supposed to be exprange, change it, problem solved.

(
x = {
	var sig;
	sig = Pulse.ar([100,100.5], 0.5, 0.03);
	sig = sig + SinOsc.ar([150,150.6], 0, 0.15);
	sig = sig + BrownNoise.ar(0.03!2);
	sig = sig * SinOsc.kr(0.3, 3pi/2).exprange(0.1);
}.play;
)

Here's another that says "Variable 'amp' not defined."

(
x = {
	arg rate=9;
	var sig, note, freq;
	freq = LFNoise0.kr(rate).range(35,85);
	freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);
	amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);
	sig = SinOsc.ar(freq.midicps) * amp;
	sig = sig * 0.2;
}.play;
)

Lines 7 and 8 is where SuperCollider got confused. The rule is: local variables must be declared before they can be used. Unless it's a single lowercase character, like x, which is a special case, you can't just pull a name out of thin air and get away with it — it's just not allowed.

num = 5;

The usual solution here is to declare the variable using a var statement at the top of the relevant section of code.

(
var num;
num = 5;
)

In this example, we're using a thing called 'amp' but we forgot to declare it. Include it in the declaration, and we're good to go.

(
x = {
	arg rate=9;
	var sig, note, freq, amp;
	freq = LFNoise0.kr(rate).range(35,85);
	freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);
	amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);
	sig = SinOsc.ar(freq.midicps) * amp;
	sig = sig * 0.2;
}.play;
)

Here's another that pops up a lot, this one's a little bit trickier. Binary operator "multiply" failed. Receiver nil.

(
x = {
	arg rate=9;
	var sig, note, freq, amp;
	freq = LFNoise0.kr(rate).range(35,85);
	freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);
	sig = SinOsc.ar(freq.midicps) * amp;
	amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);
	sig = sig * 0.2;
}.play;
)

nil is a value that represents uninitialized data. If you declare a variable but don't set it equal to something, then it equals nil. This error tells us SuperCollider is trying to do nil times something, and that's an undefined operation.

nil * 2;

There's no line number, so tracking down the issue involves some backtracking and proofreading. But you should be able to see that the problem is here — sig is a sine wave times amp...but amp isn't given a proper value until the next line, so we need to swap these two statements. Keep in mind this error might look a little different, like a different binary operator, maybe you're trying to access an item in an array that doesn't exist yet.

nil + 2;

nil.at(5);

The main clue is "receiver: nil" -- and that tells you something somewhere hasn't been initialized.

Last one, very common, sometimes kind of tricky. Syntax error, unexpected blah blah blah blah blah.

(
x = {
	arg rate=9;
	var sig, note, freq, amp;
	freq = LFNoise0.kr(rate).range(35,85)
	freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);
	amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);
	sig = SinOsc.ar(freq.midicps) * amp;
	sig = sig * 0.2;
}.play;
)

This means there's a syntactical issue somewhere, in other words, you violated SuperCollider's basic rules of grammar, like a comma instead of a period, a left bracket that doesn't have a matching right bracket, etc. In addition to the line number, these carets point to the spot where SuperCollider got lost, and most of time, these carets don't point to the actual problem, instead, they point to something a handful of characters after the problem. So, line 6, here's the spot, if we make our way backwards a bit, sure enough, we forgot a semicolon at the end of the previous line.

(
x = {
	arg rate=9;
	var sig, note, freq, amp;
	freq = LFNoise0.kr(rate).range(35,85);
	freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);
	amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);
	sig = SinOsc.ar(freq.midicps) * amp;
	sig = sig * 0.2;
}.play;
)

The semicolon is the expression terminator. Without it, SuperCollider has no idea where one line ends and the next begins. The human equivalent is writing code with no return characters, which, is technically valid, but completely unreadable.

(x = {arg rate=9;var sig, note, freq, amp;freq = LFNoise0.kr(rate).range(35,85);freq = freq + LFNoise0.kr(rate!2).bipolar(0.5);amp = VarSaw.kr(rate,1,0.01).exprange(0.01,1);sig = SinOsc.ar(freq.midicps) * amp;sig = sig * 0.2;}.play;)

So, these are some of the most common errors, why they show up, and techniques for how to fix them. That's gonna be it for this tutorial, I wanna give a shoutout and very special thanks to my supporters on patreon, much love, really appreciate your generosity, and to everyone, hope this helps, and thanks for watching.
