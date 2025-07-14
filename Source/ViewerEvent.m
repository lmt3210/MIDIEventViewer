//
// ViewerEvent.m
//
// Copyright (c) 2020-2025 Larry M. Taylor
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software. Permission is granted to anyone to
// use this software for any purpose, including commercial applications, and to
// to alter it and redistribute it freely, subject to 
// the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source
//    distribution.
//

#import "ViewerEvent.h"

@implementation LTViewerEvent

- (id)initWithEvent:(struct LTSMFEvent)event
      withDrumChannel:(NSNumber *)channel
{
    if ((self = [super init]))
    {
        Byte drumChannel = [channel intValue];
        self.track = [NSString stringWithFormat:@"   %u", (UInt32)event.track];
        self.totalTime = event.time;
        UInt32 ppqn = event.ppqn;
        long measure = (event.time / (ppqn * DEFAULT_NBPM)) + 1;
        long beat = ((event.time / ppqn) % DEFAULT_DBPM) + 1;
        long tick = event.time % ppqn;
        self.time = [NSString stringWithFormat:@"  %li:%.2li:%.3li",
                     measure, beat, tick];
        self.deltaTime = [NSString stringWithFormat:@" %u",
                          (UInt32)event.deltaTime];
        self.channel = [NSString stringWithFormat:@"    %d",
                        ((event.status & MIDI_CHNLNUM) + 1)];
        self.length = [NSString stringWithFormat:@"     %d", event.length];
        
        NSMutableString *hexString =
            [[NSMutableString alloc] initWithFormat:@" 0x%02x", event.status];
        
        for (int i = 0; i < (event.length - 1); i++)
        {
            [hexString appendFormat:@" 0x%02x", event.data[i]];
        }

        self.hex = [hexString copy];
        char str[MAX_STR_LEN] = { '\0' };
        char str2[MAX_STR_LEN] = { '\0' };
        Byte message = event.status & MIDI_CHNLMASK;
        const char **noteNames;
        
        if (event.keysig <= DEFAULT_KEY_SIG)
        {
            noteNames = noteNameFlat;
        }
        else
        {
            noteNames = noteNameSharp;
        }

        switch (message)
        {
            case MIDI_NOTE_ON:
                self.status = @"Note On";
                snprintf(str, MAX_STR_LEN, "%d (%s%d)", event.data[0],
                         noteNames[event.data[0] % 12],
                         ((event.data[0] - 12) / 12));
                
                if ((event.status & MIDI_CHNLNUM) == (drumChannel - 1))
                {
                    snprintf(str2, MAX_STR_LEN, "%s",
                             gmDrums[event.data[0] & 0x7f]);
                    self.data1 = [NSString stringWithFormat:@"%s (%s)",
                                  str, str2];
                }
                else
                {
                    self.data1 = [NSString stringWithFormat:@"%s", str];
                }
                
                self.data2 = [NSString stringWithFormat:@"%d", event.data[1]];
                break;
            case MIDI_NOTE_OFF:
                self.status = @"Note Off";
                snprintf(str, MAX_STR_LEN, "%d (%s%d)", event.data[0],
                         noteNames[event.data[0] % 12],
                         ((event.data[0] - 12) / 12));
                
                if ((event.status & MIDI_CHNLNUM) == (drumChannel - 1))
                {
                    snprintf(str2, MAX_STR_LEN, "%s",
                             gmDrums[event.data[0] & 0x7f]);
                    self.data1 = [NSString stringWithFormat:@"%s (%s)",
                                  str, str2];
                }
                else
                {
                    self.data1 = [NSString stringWithFormat:@"%s", str];
                }
                
                self.data2 = [NSString stringWithFormat:@"%d", event.data[1]];
                break;
            case MIDI_AFTER_TOUCH:
                self.status = @"Aftertouch";
                snprintf(str, MAX_STR_LEN, "%s%d",
                         noteNames[event.data[0] % 12],
                         ((event.data[0] - 12) / 12));
                self.data1 = [NSString stringWithFormat:@"%s", str];
                self.data2 = [NSString stringWithFormat:@"%d", event.data[1]];
                break;
            case MIDI_SET_PARAMETER:
                self.status = @"Control";
                snprintf(str, MAX_STR_LEN, "%s", ccList[event.data[0]]);
                self.data1 = [NSString stringWithFormat:@"%d (%s)",
                              event.data[0], str];
                self.data2 = [NSString stringWithFormat:@"%d", event.data[1]];
                break;
            case MIDI_SET_PROGRAM:
                self.status = @"Program Change";
                snprintf(str, MAX_STR_LEN, "%s", gmPatchList[event.data[0]]);
                self.data1 = [NSString stringWithFormat:@"%d (%s)",
                              (event.data[0] + 1), str];
                self.data2 = @"";;
                break;
            case MIDI_SET_PRESSURE:
                self.status = @"Poly Aftertouch";
                self.data1 = [NSString stringWithFormat:@"%d", event.data[0]];
                self.data2 = @"";
                break;
            case MIDI_PITCH_WHEEL:
                self.status = @"Pitch Wheel";
                self.data1 = [NSString stringWithFormat:@"%d      ",
                              (event.data[0] + (256 * event.data[1])) - 16384];
                self.data2 = @"";
                break;
            case MIDI_SYSTEM_MSG:
                
                switch (event.status)
                {
                    case MIDI_SYSEX:
                        self.status = @"System Exclusive";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_TCQF:
                        self.status = @"MTC Quarter Frame";
                        self.data1 = [NSString stringWithFormat:@"%3d",
                                      event.data[0]];
                        self.data2 = @"";
                        break;
                    case MIDI_SONG_POS:
                        self.status = @"Song Position";
                        self.data1 = [NSString stringWithFormat:
                                      @" %d     ",
                                      (event.data[0] + (256 * event.data[1]))];
                        self.data2 = @"";
                        break;
                    case MIDI_SONG_SELECT:
                        self.status = @"Song Select";
                        self.data1 = [NSString stringWithFormat:@"%d",
                                      event.data[0]];
                        self.data2 = @"";
                        break;
                    case MIDI_TUNE_REQ:
                        self.status = @"Tune Request";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_EOX:
                        self.status = @"End of SYSEX";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_CLOCK:
                        self.status = @"MIDI Clock";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_SEQ_START:
                        self.status = @"Sequencer Start";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_SEQ_CONTINUE:
                        self.status = @"Sequencer Continue";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_SEQ_STOP:
                        self.status = @"Sequencer Stop";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_ACTIVE_SENSE:
                        self.status = @"Active Sensing";
                        self.data1 = @"";
                        self.data2 = @"";
                        break;
                    case MIDI_META_EVENT:
                        self.status = @"Meta Event";
                        self.channel = @"";
                        int index = event.length - event.mlength - 1;
                        
                        switch (event.data[0])
                        {
                            case TYPE_TEMPO:
                                self.data1 = @"Tempo";
                                self.data2 =
                                    [NSString stringWithFormat:@"%d BPM",
                                     event.data[index]];
                                break;
                            case TYPE_TEXT:
                                self.data1 = @"Text Event";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_COPYRIGHT:
                                self.data1 = @"Copyright Notice";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_SEQ_NAME:
                                self.data1 = @"Track Name";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_LYRIC:
                                self.data1 = @"Lyric";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_MARKER:
                                self.data1 = @"Marker";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_CUE:
                                self.data1 = @"Cue Point";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_INS_NAME:
                                self.data1 = @"Instrument Name";
                                self.data2 = [NSString stringWithFormat:@"%s",
                                              &event.data[index]];
                                break;
                            case TYPE_TIME_SIG:
                                self.data1 = @"Time Signature";
                                self.data2 = 
                                    [NSString stringWithFormat:@"%d/%d",
                                     event.data[index++],
                                     (int)pow(2, event.data[index])];
                                break;
                            case TYPE_KEY_SIG:
                                self.data1 = @"Key Signature";
                                snprintf(str, MAX_STR_LEN, "%s",
                                    keySig[(event.data[index++] + 7) % 15]);
                                self.data2 =
                                    [NSString stringWithFormat:@"%s %s", str,
                                     ((event.data[index] == 0) ?
                                      "Maj" : "Min")];
                                break;
                            case TYPE_END:
                                self.data1 = @"End Of Track";
                                self.data2 = @"";
                                break;
                            case TYPE_SEQ_SPEC:
                                self.data1 = @"Sequencer Specific";
                                self.data2 = @"";
                                break;
                            case TYPE_SELECT_PORT:
                                self.data1 = @"MIDI Port";
                                self.data2 = [NSString stringWithFormat:@"%d",
                                              (event.data[index] + 1)];
                                break;
                            case TYPE_SMPTE:
                                self.data1 = @"SMPTE Offset";
                                self.data2 = [NSString stringWithFormat:
                                              @"%.2i:%.2i:%.2i:%.2i:%.2i",
                                              event.data[index++],
                                              event.data[index++],
                                              event.data[index++],
                                              event.data[index++],
                                              event.data[index]];
                                break;
                            default:
                                self.data1 = @"Unknown";
                                self.data2 =
                                    [NSString stringWithFormat:@"Type = %d",
                                     event.data[0]];
                                break;
                        }
                        
                        break;
                }
                
                break;
            default:
                break;
        }
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    LTViewerEvent *event = [[[self class] allocWithZone:zone] init];
    
    event.track = [self.track copyWithZone:zone];
    event.time = [self.time copyWithZone:zone];
    event.totalTime = self.totalTime;
    event.deltaTime = [self.deltaTime copyWithZone:zone];
    event.channel = [self.channel copyWithZone:zone];
    event.status = [self.status copyWithZone:zone];
    event.data1 = [self.data1 copyWithZone:zone];
    event.data2 = [self.data2 copyWithZone:zone];
    event.length = [self.length copyWithZone:zone];
    event.hex = [self.hex copyWithZone:zone];

    return event;
}

@end
