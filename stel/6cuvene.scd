Pdef.removeAll;

( //midi
MIDIdef.freeAll;
MIDIClient.init;
MIDIIn.connectAll;
MIDIdef.cc(\ccpostln, { arg ...args; args.postln; });
MIDIdef.noteOn(\noteonpostln, { arg ...args; args.postln; });
~lpm = MIDIClient.sources.detect{ |a| a.name.contains("Launchpad") };
if(~lpm.isNil) { ~lpm = MIDIClient.sources.detect{ |a| a.name.contains("out0") } };
~midiout = MIDIOut(0);
~midiout.connect(~lpm.uid);
);

(
t = TempoClock(120/60);
b = Buffer.alloc(s, s.sampleRate * (t.tempo * 6), 1);
);

(
~midiktrl = { |pdef, note|
    MIDIdef.noteOn(pdef, {
        if(Pdef(pdef).isPlaying.not) {
            ~midiout.noteOn(0, note, 127);
            Pdef(pdef).play(t);
            pdef.post;
            " play".postln;
        } {
            ~midiout.noteOn(0, note, 0);
            Pdef(pdef).stop;
            pdef.post;
            " stop".postln;
        }
    }, note, srcID: ~lpm.uid);
}
);

(
// Pitch logic
~ratios = [1/1, 16/15, 9/8, 7/6, 5/4, 4/3, 7/5, 3/2, 8/5, 5/3, 7/4, 15/8];
~tuning = Tuning.new(~ratios.ratiomidi);
~scaledegrees = #[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
~scale = Scale.new(~scaledegrees, ~ratios.size, ~tuning);
~chord = [0, 2, 7, 10, 12];
~chords = [[-5, 2, 0, 2], [-2, 0, 2, 7], [0, 2, 7, 10], [2, 7, 10, 12]];
);

////////////////////////////////////////////////////////
// RECORDING

/*
s.prepareForRecord;
s.record;
s.stopRecording;
*/

////////////////////////////////////////////////////////////////
// PAD

(
SynthDef(\pad, { |attack = 0.05, curve = -16, dur = 1, fb = 0, freq = 400, gate = 1, k = 1, level = 0.05, release = 0.2, round = 0.1, stan_freq = 100|
	var env				=	Env.asr(attack, level, release, curve);
	var envgen			=	EnvGen.kr(env, gate, doneAction: 2);
	//var freqmod			=	LFNoise2.kr(0.1!2, 0.0003, 1);
    var stan            =   StandardN.ar([stan_freq - 5, stan_freq + 5], [k, k - 0.01]).range(0.0, fb);
    var sinfb1			=	SinOscFB.ar(freq, stan);
    var sinfb2			=	SinOscFB.ar(freq, fb * 0.5);
    var sinfbmix        =   (sinfb1 + sinfb2).round(round) * envgen;
    var rhpf            =   RHPF.ar(sinfbmix, (freq * 4).clip(50, SampleRate.ir / 2.5));
    Out.ar(0, rhpf);
}).add;
);

//

(
Pdef(\pad1,
    Pbind(
        \instrument, \pad,
        \attack, 0.03,
        \curve, 0,
        //\degree, Pseq([[-2, 0, 7], [7, 10, 12]], inf),
        \degree, Pshuf(~chords, inf),
        \dur, Pshuf([31, 33, 35, 37, 39] + 0.25, inf),
        \fb, 0.5,
        \k, Pwhite(0.9, 4.0, inf),
        \legato, 1,
        \octave, 5,
        \offset, Pwhite(-0.02, 0.02, inf),
        \release, 0.1,
        \round, 0.5,
        \scale, ~scale,
        \stan_freq, 23
));

Pdef(\pads1, Ppar([Pdef(\pad1)].stutter(2), inf));

//Pdef(\pads2, Pbindf(Pdef(\pads1), \degree, [2, 5]));
Pdef(\pads2, Pbindf(Pdef(\pads1)));

Pdef(\padsgroup1, Ppar([Pdef(\pads1), Pdef(\pads2)], inf));

/*
Pdef(\pad1).play(t);
Pdef(\pad1).isPlaying;
Pdef(\pad1).stop;
*/

/*
Pdef(\pads1).play(t);
Pdef(\pads1).isPlaying;
Pdef(\pads1).stop;
*/

/*
Pdef(\pads2).play(t, quant: 1);
Pdef(\pads2).isPlaying;
Pdef(\pads2).stop;
*/

/*
Pdef(\padsgroup1).play(t, quant: 1);
Pdef(\padsgroup1).isPlaying;
Pdef(\padsgroup1).stop;
*/

//

//Pdef(\pads3, Pbindf(Pdef(\pads1), \degree, [7, 10, 12, 14], \dur, Pshuf([31, 33, 35, 37, 39] + 0.25, inf), \octave, 6));

//Pdef(\pads4, Pbindf(Pdef(\pads2), \dur, Pshuf([31, 33, 35, 37, 39] + 0.25, inf), \octave, 6));

//Pdef(\padsgroup2, Ppar([Pdef(\pads3)], inf));

/*
Pdef(\pads3).play(t);
Pdef(\pads3).isPlaying;
Pdef(\pads3).stop;
*/

/*
Pdef(\pads4).play(t);
Pdef(\pads4).isPlaying;
Pdef(\pads4).stop;
*/

/*
Pdef(\padsgroup2).play(t);
Pdef(\padsgroup2).isPlaying;
Pdef(\padsgroup2).stop;
*/

//

//Pdef(\pads5, Pbindf(Pdef(\pads1), \dur, Pshuf([21, 23, 25, 27, 29] + 0.25, inf), \octave, 7));

//Pdef(\pads6, Pbindf(Pdef(\pads2), \dur, Pshuf([21, 23, 25, 27, 29] + 0.25, inf), \octave, 7));

//Pdef(\padsgroup3, Ppar([Pdef(\pads5), Pdef(\pads6)], inf));

/*
Pdef(\pads5).play(t);
Pdef(\pads5).isPlaying;
Pdef(\pads5).stop;
*/

/*
Pdef(\pads6).play(t);
Pdef(\pads6).isPlaying;
Pdef(\pads6).stop;
*/

//

(
Pdef(\padlo,
    //Pmono(
        //\pad,
    Pbind(
        \instrument, \pad,
        \attack, 0.1,
        \curve, -4,
        \degree, [0, 7, 12],
        \dur, Pshuf([41, 43, 45, 47, 49] + 0.25, inf),
        \fb, 0.3,
        \k, Pwhite(0.9, 4.0, inf),
        \legato, 0.5,
        \octave, 4,
        \release, 0.1,
        \round, 0.5,
        \scale, ~scale
));

Pdef(\padslo, Ppar([Pdef(\padlo)].stutter(2), inf));
);

//Pdef(\padsgroup4, Ppar([Pdef(\pads7), Pdef(\pads8)], inf));

);

/*
Pdef(\padslo).play(t);
Pdef(\padslo).isPlaying;
Pdef(\padslo).stop;
*/

/*
Pdef(\padsgroup4).play(t);
*/
//

~midiktrl.value(\padsgroup1, 34);
//~midiktrl.value(\padsgroup2, 35);
//~midiktrl.value(\padsgroup3, 36);
~midiktrl.value(\padslo, 35);

////////////////////////////////////////////////////////////////
// SIN

(
SynthDef(\sin, { |fb = 0, freq = 440, gate = 1, level = 0.02|
    var env             =   Env.asr(0.01, level, 0.1);
    var envgen          =   EnvGen.kr(env, gate, doneAction: 2);
    var sin             =   SinOscFB.ar(freq!2, fb, envgen);
    var lor             =   SinOsc.ar(freq * 16 * LorenzL.ar(freq * 32, [10, 9.99], mul: 0.1, add: 1), mul: envgen * 0.1);
    Out.ar(0, sin + lor);
}).add;
);

(
Pdef(\sindrone,
    Pmono(
        \sin,
        \dur, 11,
        \degree, [-5, 0],
        \fb, 0.2,
        \octave, 5,
        \release, 0.1,
        \scale, ~scale
));
);

/*
Pdef(\sindrone).play(t);
Pdef(\sindrone).isPlaying;
Pdef(\sindrone).stop;
*/

(
Pdef(\sin,
    Pbind(
        \instrument, \sin,
        \degree, ~chord,
        \dur, 47,
        \fb, 0.2,
        \legato, 0.5,
        \octave, 5,
        \scale, ~scale
));
);

/*
Pdef(\sin).play(t);
Pdef(\sin).isPlaying;
Pdef(\sin).stop;
*/

(
Pdef(\sinlo,
    Pbind(
        \instrument, \sin,
        \dur, 53,
        \degree, 2,
        \fb, 0.5,
        \legato, 0.5,
        \octave, [3, 4],
        \scale, ~scale
));
);

/*
Pdef(\sinlo).play(t);
Pdef(\sinlo).isPlaying;
Pdef(\sinlo).stop;
*/

~midiktrl.value(\sindrone, 32);
~midiktrl.value(\sin, 48);
~midiktrl.value(\sinlo, 64);

////////////////////////////////////////////////////////////////
// TONE

(
SynthDef(\tone, { |curve = -4, dur, fb = 0, freq = 440, level = 0.1|
    var env             =   Env.perc(0.01, dur, level, curve);
    var envgen          =   EnvGen.kr(env, doneAction: 2);
    var sin             =   SinOscFB.ar([freq - 0.2, freq + 0.2], fb, envgen);
    Out.ar(0, sin);
}).add
);

(
Pdef(\tone1,
    Pbind(
        \instrument, \tone,
        \curve, -4,
        \degree, [-2, 0],
        \dur, Pseq([Pxrand([3, 3.75, 4.25, 5], 15), 23.25], inf),
        \octave, 5,
        \scale, ~scale
));

Pdef(\tone2, Pbindf(Pdef(\tone1), \degree, 7));

Pdef(\tones, Ppar([Pdef(\tone1), Pdef(\tone2)], inf));
);

/*
Pdef(\tone1).play(t);
Pdef(\tone1).isPlaying;
Pdef(\tone1).stop;
*/

/*
Pdef(\tone2).play(t);
Pdef(\tone2).isPlaying;
Pdef(\tone2).stop;
*/

/*
Pdef(\tones).play(t);
Pdef(\tones).stop;
*/

~midiktrl.value(\tone1, 33);
~midiktrl.value(\tone2, 49);


////////////////////////////////////////////////////////////////
// SCENES

(
~scenetoggle = { |scene, light, patterns, patternlights, patternstostop, stoplights|
    var scenestatus;
    MIDIdef.cc(scene, {
        if(scenestatus.isNil) {
            ~midiout.control(0, light, 127);
            patternlights.do({ |l| ~midiout.noteOn(0, l, 127) });
            patterns.do({ |s| Pdef(s).play(t) });
            patternstostop.do({ |p| Pdef(p).stop });
            stoplights.do({ |l| ~midiout.noteOff(0, l) });
            scenestatus = "playing";
        } {
            ~midiout.control(0, light, 0);
            patterns.do({ |s| Pdef(s).stop });
            patternlights.do({ |l| ~midiout.noteOff(0, l) });
            scenestatus = nil;
        }
    }, light, srcID: ~lpm.uid, argTemplate: { |a| a > 0 });
}
);

(
~scene1 = [\sindrone, \sin, \tone2];
~scene1lights = [32, 48, 49];
~scenetoggle.value(\scene1, 104, ~scene1, ~scene1lights);
);

(
~scene2 = [\sinlo];
~scene2lights = [64];
~scenetoggle.value(\scene2, 105, ~scene2, ~scene2lights);
);

(
~scene3 = [\padsgroup1];
~scene3lights = [34];
~scenetoggle.value(\scene3, 106, ~scene3, ~scene3lights);
);

(
~scene4 = [\tone1, \padslo];
~scene4lights = [33, 35];
~scenetoggle.value(\scene4, 107, ~scene4, ~scene4lights);
);

(
~scene5stoppers = [\sin, \sindrone, \sinlo, \tone1, \tone2];
~scene5stopperlights = [32, 48, 64, 33, 49];
~scenetoggle.value(\scene5, 108, patternstostop: ~scene5stoppers, stoplights: ~scene5stopperlights);
);

(
~scene6stoppers = [\padsgroup1, \padslo];
~scene6stopperlights = [34, 35];
~scenetoggle.value(\scene6, 109, patternstostop: ~scene6stoppers, stoplights: ~scene6stopperlights);
);