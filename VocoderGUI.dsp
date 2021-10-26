/*Polyphony limited to 2 because smartphone is not powerful enough*/
declare interface "SmartKeyboard{
  'Number of Keyboards':'3',
  'Rounding Mode':'0',
  'Rounding Cycles':'3',
  'Max Keyboard Polyphony':'2'
  'Keyboard 0 - Orientation':'1',
  'Keyboard 2 - Orientation':'1',
  'Keyboard 0 - Number of Keys':'13',
  'Keyboard 1 - Number of Keys':'4',
  'Keyboard 2 - Number of Keys':'13',
  'Keyboard 0 - Lowest Key':'60',
  'Keyboard 2 - Lowest Key':'48',
  'Keyboard 0 - Send Y':'1',
  'Keyboard 2 - Send Y':'1',
  'Keyboard 1 - Send Key X':'1'
  'Keyboard 1 - Send Freq':'0'
  'Keyboard 1 - Static Mode':'1',
  'Keyboard 1 - Key 0 - Label':'Cutoff',
  'Keyboard 1 - Key 1 - Label':'Wet/Dry',
  'Keyboard 1 - Key 2 - Label':'Voice Gain',
  'Keyboard 1 - Key 3 - Label':'Tone',
}";

import("stdfaust.lib");

oneVocoderBand(band, nBands, bwRatio, bandGain, x) = x : fi.resonbp(bandFreq, bandQ, bandGain)
with
{ 
    bandFreq = 25*pow(2,(band+1)*(9/nBands));
    bandWidth = (bandFreq - 25*pow(2,band*9/nBands))*bwRatio;
    bandQ = bandFreq/bandWidth;
};

vocoder(nBands, att, rel, bwRatio, sourceGain, gate, excitation, source) = source <: 
    par(i, nBands, oneVocoderBand(i, nBands, bwRatio,gainIn): 
        an.amp_follower_ud(att, rel) : _, excitation : oneVocoderBand(i, nBands, bwRatio)) :> 
            (_*(1-mix) + mix*excitation)*gate * 0.125<:_,_
        with
        {
            gainIn = source:an.amp_follower_ud(0.001,0.005)*sourceGain;
        };

vocoderDemo = mainOsc*envelope, source : vocoder(bands, att, rel, bwRatio, sourceGain, gate):filter,filter
with
{
    source = _;
    bands = 74;
    att = 0.1*0.001;
    rel = 5*0.001;
    bwRatio = 0.5;
};

gate = button("gate");
f = nentry("freq",200,40,2000,0.01);
maxBend = 1.06; //2^(1/12) semitone
//bend = hslider("bend[acc: 0 0 -100 0 100]",1,(1/maxBend),maxBend,0.001):si.polySmooth(t,0.999,1); //DEBUG
bend = nentry("bend[acc: 0 0 -1000 0 1000]",1,0,10,0.01) : si.polySmooth(t,0.999,1);
//bend = 1; //DEBUG
g = nentry("gain",1,0,1,0.01);
t = button("gate");
y = hslider("y",0.5,0,1,0.01):si.smoo;
mix = hslider("kb1k1x",0,0,1,0.01):si.smoo;
xParam = hslider("kb1k0x", 1, 0, 1, 0.001);
keyboard = hslider("keyboard",0,0,2,1) : int;
sourceGain = hslider("kb1k2x", 0.2, 0, 1, 0.01);
toneParam = hslider("kb1k3x",0,0,1,0.01):si.smoo;

filter = fi.lowpass(3,cutoff);
    
freq = f*bend;

gainParam = select2(keyboard==2, 1-y, y);
gain = gainParam*g;
envelope = t*gain : si.smoo;

lowFreq = 80;
highFreq = 10000;
cutoff = xParam * (highFreq-lowFreq) + lowFreq;
sawOsc = os.sawtooth(freq);
squareOsc = os.lf_squarewave(freq);
mainOsc = toneParam*sawOsc + (1-toneParam)*squareOsc;

process = vocoderDemo;
