////////////////////////////////////////////////////////////////////////////////
//                          INIT

t = TempoClock(96/60);
~keyfrq = 64;

////////////////////////////////////////////////////////////////////////////////
// 							GRAPHICAL MONITORING

/*
s.scope(2);
*/

////////////////////////////////////////////////////////////////////////////////
//							RECORDING

/*
s.prepareForRecord;
s.record;
s.stopRecording;
*/

////////////////////////////////////////////////////////////////////////////////
//							SYNTHDEFS

// compressor

(
~compressor =
SynthDef(\compressor, {
	var in	   		= 	In.ar(2, 2);                          // stereo input bus
	var compressor	=	Compander.ar(in, in, thresh: 0.125, clampTime: 0.002, relaxTime: 0.01,
							slopeAbove: 1/128); // compressor
	Out.ar(0, compressor);
}).play;
);

// bass

(
~sawbass =
SynthDef(\sawbass, { |dur = 1, freq = 440, peak = 0.1|
	var env			=	Env.new([0, peak, 0], [0.002, dur / 1.5]);
	var envgen		=	EnvGen.kr(env, doneAction: 2);
	var envgendiv	=	6;
	var kbnfrq		=	10;
	var kbnmul		=	0.01;
	var kbn1		=	LFBrownNoise0.kr(kbnfrq, mul: kbnmul, add: 1);
	var kbn2		=	LFBrownNoise0.kr(kbnfrq, mul: kbnmul, add: 1);
	var saw1		=	SyncSaw.ar(freq, freq, mul: envgen / envgendiv);
	var saw2		=	SyncSaw.ar((freq) * kbn1, freq * kbn2, mul: envgen / envgendiv);
	var saw3		=	SyncSaw.ar((freq) * kbn2, freq * kbn1, mul: envgen / envgendiv);
	var tri			=	LFTri.ar(freq, mul: envgen / 4);
	var cutoff		=	(freq * 3).clip(60, SampleRate.ir / 3);
	var flt			=   RLPF.ar(saw1 + saw2 + saw3 + tri, cutoff, 0.75);
	Out.ar([0, 1], flt);
}).add;
);

// drone

(
~drone =
SynthDef(\drone, { |freq = 256, freqratio = #[1, 1.5], gate = 1, kbnammul = 0.85, kbnfmmul = 0.005, peak = 1|
	var kbnfmfreq	=	freq;
	var kbnamfreq	= 	20;
	var env			=	Env.asr(1, peak, 10, 0);
	var envgen		=	EnvGen.kr(env, gate, doneAction: 2);
	var kbnfmod1	=	LFBrownNoise0.kr(kbnfmfreq, mul: kbnfmmul, add: 1);
	var kbnfmod2	=	LFBrownNoise0.kr(kbnfmfreq, mul: kbnfmmul, add: 1);
	var kbnfmod3	=	LFBrownNoise0.kr(kbnfmfreq, mul: kbnfmmul, add: 1);
	var kbnfmod4	=	LFBrownNoise0.kr(kbnfmfreq, mul: kbnfmmul, add: 1);
	var kbnamod1	=	LFBrownNoise0.kr(kbnamfreq, mul: kbnammul, add: 1);
	var kbnamod2	=	LFBrownNoise0.kr(kbnamfreq, mul: kbnammul, add: 1);
	var kbnamod3	=	LFBrownNoise0.kr(kbnamfreq, mul: kbnammul, add: 1);
	var kbnamod4	=	LFBrownNoise0.kr(kbnamfreq, mul: kbnammul, add: 1);
	var sin1a		=	SinOsc.ar(freq * freqratio * kbnfmod1, 			mul: envgen * kbnamod1);
	var sin1b		=	SinOsc.ar(freq * 1.003 * freqratio, 			mul: envgen * kbnamod1);
	var sin2a		=	SinOsc.ar(freq * 2 * freqratio * kbnfmod2, 		mul: (envgen / 4) * kbnamod2);
	var sin2b		=	SinOsc.ar(freq * 2.005 * freqratio, 			mul: (envgen / 4) * kbnamod2);
	var sin3a		=	SinOsc.ar(freq * 4 * freqratio * kbnfmod3, 		mul: (envgen / 16) * kbnamod3);
	var sin3b		=	SinOsc.ar(freq * 4.01 * freqratio, 				mul: (envgen / 16) * kbnamod3);
	Out.ar([0, 1], (sin1a + sin1b + sin2a + sin2b + sin3a + sin3b) / 128);
}).add;
);

// pad

(
~pad =
SynthDef(\pad, { |dur = 1, envgendivisor = 8, freq = 512, gate = 1, kbnmul = 0.005, peak = 1|
	var kbnfreq		=	freq;
	var env			=	Env.sine(dur, peak);
	var envgen		=	EnvGen.kr(env, gate, doneAction: 2);
	var kbn1		=	LFBrownNoise0.kr(freq, mul: kbnmul, add: 1);
	var saw1		=	LFSaw.ar(freq * kbn1, mul: (envgen / envgendivisor));
	var kbn2		=	LFBrownNoise0.kr(freq, mul: kbnmul, add: 1);
	var saw2		=	LFSaw.ar((freq + 0.1) * kbn2, mul: (envgen / envgendivisor));
	var kbn3		=	LFBrownNoise0.kr(freq, mul: kbnmul, add: 1);
	var saw3		=	LFSaw.ar((freq - 0.1) * kbn3, mul: (envgen / envgendivisor));
	var rlpf		=	RLPF.ar(saw1 + saw2 + saw3, freq * 1.5, 0.5, mul: envgen / 2);
	var deci		=	Decimator.ar(saw1 + saw2 + saw3, rate: 16000, bits: 3, mul: envgen);
	var kbn4		=	LFBrownNoise0.kr(mul: 0.5, add: 1);
	var hpffrq		=	(freq * 6 * kbn4).clip(100, SampleRate.ir / 3);
	var kbn5		=	LFBrownNoise0.kr(mul: 0.75, add: 1).clip(0.1, 1);
	var rhpf		=	RHPF.ar(deci, hpffrq, kbn5, mul: envgen);
	Out.ar([0,1], rlpf + rhpf);
}).add;
);

/*
~padtest = Synth(\pad, [\dur, 20, \freq, 2500]).register;
~padtest.isPlaying;
~padtest.release;

d = DebugNodeWatcher(s);
d.start;
d.stop;
*/

// squirp

(
~squirp =
SynthDef(\squirp, { |amp = 1, dur = 8, freq = 512, squirpamp = 0.05|
	var env			=	Env.perc(0.002, releaseTime: dur, level: amp / 1.5, curve: -4);
	var envgen		=	EnvGen.kr(env, doneAction: 2);
	var squirp1		=	LinCongC.ar(freq, mul: squirpamp, add: 1);
	var sin1		=	SinOsc.ar(freq * squirp1, mul: (envgen / 3));
	var squirp2		=	LinCongC.ar((freq + 0.1), mul: squirpamp, add: 1);
	var sin2		=	SinOsc.ar((freq + 0.1) * squirp2, mul: (envgen / 3));
	var squirp3		=	LinCongC.ar(freq * 8, mul: squirpamp * 8, add: 1);
	var sin3		=	SinOsc.ar(freq * 8 * squirp3, mul: (envgen / 36));
	Out.ar([0, 1], [sin1 + sin3, sin2 + sin3]);
}).add;
);

// kords

(
~kords =
SynthDef(\kords, { | freq = 512, gate = 1, level = 0.25 |
	var env 		=	Env.asr(sustainLevel: level);
	var envgen		=	EnvGen.kr(env, gate, doneAction: 2);
	var bn			=	LFBrownNoise0.ar(freq, add: 1);
	var sin1		=	SinOsc.ar(freq, mul: envgen * bn);
	var sin2		=	SinOsc.ar(freq * 2.02, mul: (envgen * bn) / 2);
	Out.ar([0, 1], sin1 + sin2);
}).add;
);

/*
~kordtest = Synth(\kords).register;
~kordtest.release;
*/

(
~kords2 =
SynthDef(\kords2, { | freq = 512, gate = 1, level = 0.1, ratio = 1.125 |
	var env		= 	Env.asr(attackTime: 5, sustainLevel: level, releaseTime: 5, curve: 0);
	var envgen	=	EnvGen.kr(env, gate, doneAction: 2);
	var sfreqs	=	[freq, freq + 0.2];
	var bn		=	LFBrownNoise0.ar(sfreqs, mul: envgen / 2);
	var kbnf	=	LFBrownNoise0.kr([freq, freq], mul: 0, add: 1);
	var kbna	=	LFBrownNoise0.kr([freq, freq] / 16, mul: [0.75, 0.75], add: 1);
	var layers	=	16;
	var frqs	=	Array.fill(layers, { arg i; (sfreqs * kbnf) + (sfreqs * i * ratio * kbnf) });
	var amps	=	Array.fill(layers, { arg i; (1 / (((i + 1) * ratio) * 32)) * kbna });
	var rt		=	Array.fill(layers, { 0.3 });
	var klank	=	DynKlank.ar(`[frqs, amps, rt], bn);
	Out.ar(0, klank).clip(-0.9, 0.9);
}).add;
);

/*
~kords2test = Synth(\kords2).register;
~kords2test.isPlaying;
~kords2test.release;
*/

// pling

(
~burn =
SynthDef(\sin, { |amp = 1, curve = -4, dur = 1, envgendiv = 32, freq = 440, mulkbn = 0.9, mulcrckl = 0.01, xaos = 1.99|
	////////////////////////////////////////////////////////////////////////////////
	var env			=	Env.perc(0.005, releaseTime: dur, level: amp, curve: curve);
	var envgen		=	EnvGen.kr(env, doneAction: 2);
	///////////////////////////////////////////////////////////////////////////
	var crckl1		= 	Crackle.kr(chaosParam: [xaos, xaos], mul: mulcrckl, add: 1);
	var sin1		=	SinOsc.ar([freq, freq + 0.1] * crckl1, mul: envgen / 3);
	var kbn1		=	LFBrownNoise0.kr([freq, freq], mul: mulkbn, add: 1);
	var sin1a		=	SinOsc.ar([freq, freq + 0.1] * crckl1 * kbn1 * 8, mul: (envgen / envgendiv));
	////////////////////////////////////////////////////////////////////////////
	var crckl2		= 	Crackle.kr(chaosParam: [xaos, xaos], mul: mulcrckl, add: 1);
	var sin2		=	SinOsc.ar([freq, freq + 0.1] * crckl2, mul: envgen / 3);
	var kbn2		=	LFBrownNoise0.kr([freq, freq], mul: mulkbn, add: 1);
	var sin2a		=	SinOsc.ar([freq, freq + 0.1] * crckl2 * kbn2 * 8, mul: (envgen / envgendiv));
	////////////////////////////////////////////////////////////////////////////
	var sin3		=	SinOsc.ar([freq, freq + 0.1], mul: envgen / 3);
	var kbn3		=	LFBrownNoise0.kr([freq, freq], mul: mulkbn, add: 1);
	var sin3a		=	SinOsc.ar([freq, freq + 0.1] * kbn3 * 8, mul: (envgen / envgendiv));
	///////////////////////////////////////////////////////////////////
	Out.ar(0, sin1 + sin1a + sin2 + sin2a + sin3 + sin3a);
}).add;
);

// ox

(
~ox =
SynthDef(\ox, { |curve = -64, dur = 1, freq = 440, length = 0.25, peak = 0.5 |
	var env			=	Env.perc(0.002, releaseTime: dur / 4, level: peak / 8, curve: curve);
	var envgen		=	EnvGen.kr(env, doneAction: 2);
	var kbn1		=	LFBrownNoise0.kr(freq!2, add: 1);
	var kbn2		=	LFBrownNoise0.kr(freq!2, add: 1);
	var kimp		=	Impulse.ar(freq, mul: kbn1, add: 1);
	var sin			=	SinOsc.ar(freq * kimp, mul: kbn2);
	var foldfactor	=	4;
	var fold		=	sin.fold2(1 / foldfactor) * foldfactor * envgen;
	Out.ar(2, fold);
}).add;
);

// pad2

(
~pad2 =
SynthDef(\pad2, { |freq = 256, gate = 1, kbnmul = 1, peak = 1, width = 0.5|
	var env			=	Env.adsr(3, 1, peak, 3, peak, curve: -4);
	var envgen		=	EnvGen.kr(env, gate, doneAction: 2);
	var kbn1		=	LFBrownNoise0.kr(mul: kbnmul, add: 1);
	var saw1		=	VarSaw.ar([freq, freq + 0.1], width: width, mul: (envgen / 128) * kbn1);
	var kbn2		=	LFBrownNoise0.kr(mul: [kbnmul, kbnmul], add: 1);
	var saw2		=	VarSaw.ar(([freq, freq + 0.1] + 0.1), width: width, mul: (envgen / 128) * kbn2);
	var kbn3		=	LFBrownNoise0.kr(mul: [0.05, 0.5], add: 1);
	var cutoff		=	(freq * 2 * kbn3).clip(50, SampleRate.ir / 3);
	var rlpf		=	RLPF.ar(saw1 + saw2, cutoff, 0.1);
	Out.ar(0, rlpf);
}).add;
);

// prc based on xaotic fn

(
~foibles =
SynthDef(\latte, { |a = 1, b = 3, curve = -8, length = 0.2, pan = 0, peak = 1|
	var env			=	Env.perc(releaseTime: length, level: peak, curve: curve);
	var envgen		=	EnvGen.kr(env, doneAction: 2);
	var lat			=	Latoocarfian2DN.ar(a: a, b: b, mul: envgen);
	var pan2		= 	Pan2.ar(lat, pan);
	Out.ar(2, pan2);
}).add;
);

// clicky prc

/*
(
~germ =
SynthDef(\imp, { |frq = 2000, pan = 0, peak = 1, rq = 1|
	var env			=	Env.perc(0.005, level: peak);
	var envgen		=	EnvGen.kr(env, doneAction: 2);
	var imp			=	Impulse.ar(0, mul: envgen);
	var flt			=	RLPF.ar(imp, frq, rq);
	var pan2		=	Pan2.ar(flt, pan);
	Out.ar(2, imp);
}).add;
);
*/

(
SynthDef(\imp, { |fb = 0, freq = 4000, pan = 0, peak = 0.1|
	var env			=	Env.new([0, peak, 0], [0.003, 0.001], );
	var envgen		=	EnvGen.ar(env, doneAction: 2);
	var sinfb		=	SinOscFB.ar(freq, fb, envgen);
	var pan2		=	Pan2.ar(sinfb, pan);
	var rhpf		=	RHPF.ar(pan2, 8000, 0.01);
	Out.ar(2, rhpf);
}).add;
);

~imptest = Synth(\imp);

////////////////////////////////////////////////////////////////////////////////////
//							PATTERNS

(
// bass
~morse =
Pdef(\mutter,
	Pbind(
		\instrument, 	\sawbass,
		\dur, 			Pshuf([0.25, 0.5, 0.75, 1, 1.5, 8, 12, 16, 24].mirror, inf),
		\freq, 			Pseq([
							1/1, 16/15,
							1/1, 1/1, 9/8,
							1/1, 1/1, 1/1, 6/5, 16/15
						] * ~keyfrq, inf),
		\peak, 			0.15,
));
);

/*
~morse.play(t, quant: 1);
~morse.stop;
*/

(
~squirpy1 =
Pdef(\squirpy,
Pbind(
	\instrument, 		\squirp,
	\dur, 				Prand([0.25, 4, 6, 8, 12, 16, 24], inf),
	\freq, 				Pshuf([9/10, 1/1, 16/15, 9/8, 6/5, 3/2, 9/5, 32/15, 9/4, 13/5] * ~keyfrq * 8, inf),
));
);

/*
~squirpy1.play(t, quant: 1);
~squirpy1.stop;
*/

~squirpy2 = Pdef(\squirpy2, Pbindf(~squirpy1));

/*
~squirpy2.play(t, quant: 1);
~squirpy2.stop;
*/

// kords

(
~kordsdurarray = [16, 24, 32, 48].scramble;

~kordpat1 =
Pdef(\kordpat1,
	Pbind(
		\instrument, \kords2,
		//\dur, Pseq(~kordsdurarray, inf),
		\dur, Pshuf([8, 12, 16, 24, 32, 48], inf),
		\freq, Pshuf([1/1, 3/2, 7/4, 9/4, 13/5].mirror * ~keyfrq * 16, inf),
		\legato, 0.5,
		\level, 0.05,
		\ratio, Pshuf([13/11, 17/11, 23/11, 29/11], inf),
));
);

/*
~kordpat1.play(t, quant: 1);
~korpat1.isPlaying;
~kordpat1.stop;
*/

~kordpar = Pdef(\kordpar, Ppar(Array.fill(5, {~kordpat1})));

/*
~kordpar.play(t, quant: 1);
~kordpar.isPlaying;
~kordpar.stop;
*/

// pad ///////////////////////////////////////////////

(
~padpat =
Pdef(\padpat,
	Pbind(
		\instrument, 	\pad,
		\dur, 			Pshuf([21, 23, 25, 27, 29], inf),
		\freq, 			Pshuf([1/1, 16/15, 9/8, 8/7, 6/5, 9/7, 11/8, 7/5, 10/7, 3/2, 11/7, 8/5, 13/8, 12/7, 9/5, 13/7, 11/5, 13/5, 13/3] * ~keyfrq * 4, inf),
		\peak, 			0.4,
));
);

/*
~padpat.play(t, quant: 1);
~padpat.stop;
*/

(
~padchords =
Pdef(\padchords,
Ppar([~padpat, ~padpat, ~padpat], inf
));
);

/*
~padchords.play(t, quant: 1);
~padchords.stop;
*/

// prc1a /////////////////////////////////////////////

(
~gazelle =
Pdef(\moisture,
	Pbind(
		\instrument, 	\latte,
		\a, 			Pwhite(0.1, 1, inf),
		\b, 			Pwhite(1, 3, inf),
		\dur, 			Pwrand([Pseq([0.25 / 2], 4), 0.5, 0.75, 6, 9], [1, 16, 16, 4, 4].normalizeSum, inf),
		\pan, 			Pshuf([-1, -0.5, 0, 0.5, 1], inf),
		\peak, 			Pwhite(0.75, 1, inf) / 4,
));
);

/*
~gazelle.play(t, quant: 1);
~gazelle.stop;
*/

// prc1b
(
~gauze =
Pdef(\gumboots,
	Ppar(
		~gazelle!4, inf
));
);

/*
~gauze.play(t, quant: 1);
~gauze.stop;
*/

// prc1c

(
~bandage =
Pdef(\gobble,
	Ppar(
		[~gauze, ~gauze], inf
));
);

/*
~bandage.play(t, quant: 1);
~bandage.stop;
*/

// imp (clicky) //////////////////////////

(
~godliness =
Pdef(\huddled,
	Pbind(
		\instrument, 	\imp,
		\dur, 			Pxrand([0.5, 0.75, 1.5], inf),
		\fb,            Pshuf((0..6), inf),
		\freq,          ~keyfrq * 2.pow(8),
		\pan, 			Prand([-1, 0, 1], inf),
		\peak, 			Pwhite(0.75, 1, inf) / 10,
));
);

/*
~godliness.play(t, quant: 1);
~godliness.stop;
*/

// clicky echo ///////////////////////////

(
~gumption =
Pdef(\homesick,
	Pbindf(~godliness,
		\dur, 			Pwrand([Pseq([0.125], 2), Pseq([0.125], 4), 0.5, 0.75, 1.5], [1, 1, 16, 16, 16].normalizeSum, inf),
		\peak, 			Pwhite(0.75, 1, inf) / 50,
));
);

~desert = Pdef(\fluster, Ppar([~gumption, ~gumption], inf));

/*
~desert.play(t, quant: 1);
~desert.stop;
*/

// imp for 2nd section

(
~klikk2 =
Pdef(\klikk,
	Pbind(
		\instrument, \imp,
		\dur, Pshuf([0.75, 1, 1.5, 2].mirror2, inf),
		\fb, 6,
		\freq, ~keyfrq * 2.pow(6),
		\peak, Pwhite(0.75, 1, inf) / 30,
		//\peak, 0,
));
~klikk2a = Pdef(\klikk2a, Pbindf(~klikk2, \dur, 1.25, \fb, 2, \peak, 1 / 80));
);

/*
~klikk2.play(t, quant: 0.5);
~klikk2a.play(t, quant: 0.5);
~klikk2.stop;
~klikk2a.stop;
*/

~klikkpar = Pdef(\klikkpar, Ppar([~klikk2, ~klikk2a], inf));

/*
~klikkpar.play(t, quant: 0.5);
~klikkpar.stop;
*/

// kik ///////////////////

(
~bonk =
Pdef(\borne,
	Pbind(
		\instrument, 	\latte,
		\a, 			3,
		\b, 			Pwhite(0.11, 0.114, inf),
		\curve, 		-64,
		\dur, 			Pxrand([0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4, 6, 8, 12], inf),
		\length, 		0.1,
		\pan, 			Pwhite(-0.5, 0.5, inf),
		\peak, 			Pwhite(0.6, 0.8, inf),
));
);

/*
~bonk.play(t, quant: 1);
~bonk.stop;
*/

// snr ////////////////////

(
~guzzle =
Pdef(\horned,
	Pbind(
		\instrument, 	\latte,
		\a, 			Pwhite(0.925, 0.926, inf),
		\curve, 		-64,
		\dur, 			Pxrand([0.75, 1, 1.5, 2, 3, 4, 6, 8, 12], inf),
		\length, 		0.1,
		\note, 			Pseq([Rest, 1], inf),
		\peak, 			0.4,
));
);

/*
~guzzle.play(t, quant: 1);
~guzzle.stop;
*/

// pling /////////////////////////////////////////////////////////////

(
~forked =
Pdef(\fillery,
	Pbind(
		\instrument, 	\sin,
		\amp, 			0.1,
		\curve,         -4,
		\dur, 			Pshuf([0.25, 4, 6, 8, 12, 16, 24, 32, 48], inf),
		\freq, 			Pseq([9/10, 1/1, 16/15, 9/8, 6/5, 3/2, 9/5, 13/5] * ~keyfrq * 8, inf),
));
);

/*
~forked.play(t, quant: 1);
~forked.stop;
*/

(
~formula =
Pdef(\borked,
	Ppar(
		~forked!2, inf
));
);

/*
~formula.play(t, quant: 1);
~formula.stop;
*/

(
~familyman =
Pdef(\vooom,
	Pbindf(
		~forked,
		\freq, Pshuf([9/10, 1/1, 16/15, 9/8, 6/5, 3/2, 9/5, 13/5] * ~keyfrq * 8 * (3/2), inf),
));
);

/*
~familyman.play(t, quant: 1);
~familyman.stop;
*/

(
~families =
Pdef(\goam,
Ppar(
		~familyman!2, inf
));
);

/*
~families.play(t, quant: 1);
~families.stop;
*/

// pad2

/*
(
~pad2pat1 =
Pdef(\pad2pat,
Pbind(
		\instrument, 	\pad2,
		\dur, 			Pshuf([17, 19, 23, 29, 31].mirror2, inf),
		\freq, 			Pshuf([[1/1, 3/2, 7/4]].mirror2 * 512 * (9/8), inf),
		\peak, 			0.3,
		\width, 		Pwhite(0.2, 0.8, inf),
));
);

/*
~pad2pat.play(t, quant: 1);
~pad2pat.stop;
*/

(
~pad2chords =
Pdef(\pad2chords,
Ppar(
		Array.fill(5, { ~pad2pat1 }), inf
));
);

/*
~pad2chords.play(t, quant: 1);
~pad2chords.stop;
*/

*/

// ox

(
~oxpastpat =
Pdef(\oxtestpat,
Pbind(
		\instrument, 	\ox,
		\curve,         -64,
		\dur, 			Pshuf((17..19).stutter(3) / 4, inf),
		\freq, 			Prand([2.pow(2), 2.pow(4), 2.pow(8)], inf) * ~keyfrq,
		\peak, 			Pbrown(0.5, 1, 0.5, inf) / 1.5
));
//~oxpastpat2 = Pdef(\oxpastpat2, Pbindf(~oxpastpat, \dur, Prand([0.5, 0.75, 8, 12], inf), \peak, 0.2));
~oxpastpar = Pdef(\oxpastpar, (Ppar(~oxpastpat!3, inf)));
);

/*
~oxpastpat.play(t, quant: 0.5);
~oxpastpat.stop;
*/

/*
~oxpastpar.play(t, quant: 0.5);
~oxpastpar.stop;
*/

/////////////////////////////////////////////////////////////////////////////////
// 							MIDI KONTROL

// connect MIDI
MIDIdef.freeAll;
MIDIClient.init;
MIDIIn.connectAll;
c.free;
c = MIDIdef.cc(\ccpostln, { arg ...args; args.postln; });
~nanoktrl = 1310720;
//~nanoktrl = 1400710921;
//~nanoktrl = 683998490;

// bass

(
~flub =
MIDIdef.cc(\flub, {
	if (~morse.isPlaying.not) {
		~morse.play(t, quant: 0.5);
		"bass play".postln;
	} {
		~morse.stop;
		"bass stop".postln;
	};
}, 32, srcID: ~nanoktrl);
);

// drone

(
~dronectl =
MIDIdef.cc(\dronectl, {
	if (~dronenode.isPlaying.not) {
		~dronenode = Synth(\drone).register;
		"drone play".postln;
	} {
		~dronenode.release;
		"drone stop".postln;
	};
}, 48, srcID: ~nanoktrl);
);

// pad

(
~padctrl =
MIDIdef.cc(\padctrl, {
	if (~padchords.isPlaying.not) {
		~padchords.play(t, quant: 1);
		"pad play".postln;
	} {
		~padchords.stop;
		"pad stop".postln;
	}
}, 64, srcID: ~nanoktrl);
);

// prc1a-c

(
~gassy1 =
MIDIdef.cc(\morp, {
	if (~gazelle.isPlaying.not) {
		~gazelle.play(t, quant: 0.5);
		"prc1 play".postln;
	} {
		~gazelle.stop;
		"prc1 stop".postln;
	};
}, 33, srcID: ~nanoktrl);
);

(
~gassy2 =
MIDIdef.cc(\morp2, {
	if (~gauze.isPlaying.not) {
		~gauze.play(t, quant: 0.5);
		"prc2 play".postln;
	} {
		~gauze.stop;
		"prc2 stop".postln;
	};
}, 49, srcID: ~nanoktrl);
);

(
~gassy3 =
MIDIdef.cc(\morp3, {
	if (~bandage.isPlaying.not) {
		~bandage.play(t, quant: 0.5);
		"prc3 play".postln;
	} {
		~bandage.stop;
		"prc3 stop".postln;
	};
}, 65, srcID: ~nanoktrl);
);

// squirp

(
~squirpplayer1 =
MIDIdef.cc(\squipplayer1, {
	if (~squirpy1.isPlaying.not) {
		~squirpy1.play(t, quant: 0.5);
		"squirpy1 play".postln;
	} {
		~squirpy1.stop;
		"squirpy1 stop".postln;
	}
}, 34, srcID: ~nanoktrl);
);

(
~squirpplayer2 =
MIDIdef.cc(\squipplayer2, {
	if (~squirpy2.isPlaying.not) {
		~squirpy2.play(t, quant: 0.5);
		"squirpy2 play".postln;
	} {
		~squirpy2.stop;
		"squirpy2 stop".postln;
	}
}, 50, srcID: ~nanoktrl);
);

// kords

(
~kordsplayer =
MIDIdef.cc(\kordplayer, {
	if (~kordpar.isPlaying.not) {
		~kordpar.play(t, quant: 0.5);
		"kord play".postln;
	} {
		~kordpar.stop;
		"kord stop".postln;
	}
}, 66, srcID: ~nanoktrl);
);

// clicky 'hat'

(
~elastics =
MIDIdef.cc(\kaiser, {
	if (~godliness.isPlaying.not) {
		~godliness.play(t, quant: 0.5);
		"hat play".postln;
	} {
		~godliness.stop;
		"hat stop".postln;
	}
}, 35, srcID: ~nanoktrl);
);

// clicky 'hat' echo

(
~thumble =
MIDIdef.cc(\geyser, {
	if (~desert.isPlaying.not) {
		~desert.play(t, quant: 0.5);
		"hat echo play".postln;
	} {
		~desert.stop;
		"hat echo stop".postln;
	}
}, 51, srcID: ~nanoktrl);
);

// klikk2

(
~klikk2player =
MIDIdef.cc(\klikk2player, {
	if (~klikkpar.isPlaying.not) {
		~klikkpar.play(t, quant: 0.5);
		"klikkpar play".postln;
	} {
		~klikkpar.stop;
		"klikkpar stop".postln;
	}
}, 67, srcID: ~nanoktrl);
);

// kik

(
~grassrooties =
MIDIdef.cc(\formals, {
	if (~bonk.isPlaying.not) {
		~bonk.play(t, quant: 0.5);
		"kik play".postln;
	} {
		~bonk.stop;
		"kik stop".postln;
	}
}, 36, srcID: ~nanoktrl);
);

// 'snr'

(
~corndogs =
MIDIdef.cc(\armedstruggle, {
	if (~guzzle.isPlaying.not) {
		~guzzle.play(t, quant: 0.5);
		"snr play".postln;
	} {
		~guzzle.stop;
		"snr stop".postln;
	}
}, 52, srcID: ~nanoktrl);
);

// pling

(
~boring =
MIDIdef.cc(\cookies, {
	if (~formula.isPlaying.not) {
		~formula.play(t, quant: 0.5);
		"pling1 play".postln;
	} {
		~formula.stop;
		"pling1 stop".postln;
	}
}, 37, srcID: ~nanoktrl);
);

(
~coring =
MIDIdef.cc(\morecookies, {
	if (~families.isPlaying.not) {
		~families.play(t, quant: 0.5);
		"pling2 play".postln;
	} {
		~families.stop;
		"pling2 stop".postln;
	}
}, 53, srcID: ~nanoktrl);
);

// ox

(
~oxpat =
MIDIdef.cc(\oxpat, {
	if (~oxpastpar.isPlaying.not) {
		~oxpastpar.play(t, quant: 0.5);
		"ox play".postln;
	} {
		~oxpastpar.stop;
		"ox stop".postln;
	}
}, 68, srcID: ~nanoktrl);
);

// pad2

/*
(
~pad2pctl =
MIDIdef.cc(\pad2ctl, {
	if (~pad2chords.isPlaying.not) {
		~pad2chords.play(t, quant: 0.5);
		"pad2 play".postln;
	} {
		~pad2chords.stop;
		"pad2 stop".postln;
	}
}, 38, srcID: ~nanoktrl);
);
*/