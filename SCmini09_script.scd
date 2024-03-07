In many situations, duration and musical pitch are inseparably linked. For example, consider this excerpt from one of my compositions.

s.boot;

b = Buffer.read(s, "/Users/eli/Desktop/sax.aiff");

{PlayBuf.ar(2, b, rate: 1)}.play;

If playback speed is reduced by two-thirds,

{PlayBuf.ar(2, b, rate: 2/3)}.play;

the duration of the sample increases, but pitch is also affected. This happens because pitch is a perceptual experience based primarily on frequency, and frequency is a measure of vibrational cycles per second. So, if we stretch the sample, cycles get longer, thus frequency and our sense of pitch are lower.

But, we can unlink these two parameters to do things like pitch-neutral time-stretching and spectral freezing by applying the Fast Fourier Transform, or FFT, to perform a spectral analysis and resynthesis of a sound. Specifically, we'll use PV_RecordBuf and PV_PlayBuf, which are part of the SC3-plugins extensions package, which needs to be downloaded and installed separately, instructions in the video description if you need them. These UGens behave a lot like regular RecordBuf and PlayBuf, but the buffer they access contains FFT analysis data instead of data that directly represents the waveform.

So, first we set a few important FFT parameters. The FFT size is the number of samples in one analysis window, has to be a power of two. For time stretching, a relatively high value like 8192 works well, but you can drop down to 4096 or 2048 and it'll probably still sound ok. I like 0.25 for the hop size, this means the analysis windows overlap by a factor of four which helps produce a smooth resynthesis, and for the windowing envelope, 0 is a sine window, 1 is a Hann window, slightly different but both reasonable choices, you can experiment and decide which one you like.

~fftsize = 8192;
~hop = 0.25;
~win = 0;

Next, allocate a buffer that will contain analysis data. We calculate the appropriate buffer size based on the original sample duration, using the 'calcPVRecSize' method, also part of the same extensions package, and provide FFT size and hop size.

f = Buffer.alloc(s, b.duration.calcPVRecSize(~fftsize, ~hop));

If your source file is monophonic, you can run this line as-is, but I've got a stereo file, so I need an array of two analysis buffers, one for each channel, so I'm gonna wrap this line in curly braces and duplicate with exclam 2.

b.numChannels;

f = { Buffer.alloc(s, b.duration.calcPVRecSize(~fftsize, ~hop)) } ! 2;

And finally, a pair of UGen functions, one using PV_RecordBuf to analyze and record the FFT data, and the other using PV_PlayBuf to read and resynthesize an audio signal from that data. In the first function, we begin with an audio signal of the original sample, LocalBuf provides a dedicated space for the FFT object to actually perform its calculations, once again we need two of them because we're working in stereo, and PV_RecordBuf writes the complete analysis into the two buffers stored in f. Zero at the end to make sure the output is silent.

(
{
	var sig, chain, localbuf;
	sig = PlayBuf.ar(2, b, BufRateScale.kr(b), doneAction: 2);
	localbuf = { LocalBuf.new(~fftsize) } ! 2;
	chain = FFT(localbuf, sig, ~hop, ~win);
	chain = PV_RecordBuf(chain, f, run: 1, hop: ~hop, wintype: ~win);
	0;
}.play;
)

Keep in mind this analysis is a preparatory step that doesn't happen instantaneously, in fact in this particular case we actually need to read through the entire sample in real-time to complete the analysis, but you can monitor the progress on the node tree to see when it's finished.

Plot f, and we can clearly see that the stored data does not represent the waveform itself, but instead it's FFT analysis data, representing the same sound in a different format.

f.do(_.plot(minval: 0, maxval: 100));

In the second function, another pair of LocalBufs for FFT calculations, PV_PlayBuf reads the data from f, including a rate argument for real-time control, and IFFT is the inverse operation that resynthesizes a waveform from the data, create a signal we can send to our speakers.

(
x = {
	var sig, chain, localbuf;
	localbuf = { LocalBuf.new(~fftsize) } ! 2;
	chain = PV_PlayBuf(localbuf, f, \rate.kr(1), loop: 1);
	sig = IFFT(chain, ~win);
}.play;
)

The lines below change the rate during playback. 0 creates a spectral freeze effect, positive values close to zero will creep along slowly, producing a smeared and dreamy effect, and negative numbers read through the data backward.

x.set(\rate, 0);

x.set(\rate, 1/10);

x.set(\rate, -2/3);

x.release(2);

Lots of variations to be explored, but that's the basic technique of pitch-neutral time-stretching, and hopefully this tutorial gives you a good starting point. Shoutout to Josh Parmenter, who describes himself as a composer and performer distracted by a day job, also a long-time SC developer and creator of these and many other excellent UGen extensions. And a very special shoutout and thanks to my supporters on Patreon who help make these videos possible, thank you all so very much, hope you enjoyed this mini tutorial, if you did, please like and subscribe. Thanks for watching.

Patreon.thanks;