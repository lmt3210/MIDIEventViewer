//
// MasterViewController.m
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

#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "LTMidi.h"
#import "MasterViewController.h"
#import "ViewerEvent.h"


@implementation MasterViewController

@synthesize mTableView;
@synthesize mLabel;
@synthesize mEvents;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    // Set up logging
    mLog = os_log_create("com.larrymtaylor.MIDIEventViewer", "MasterView");

    // Initialize variables
    mEvents = [[NSMutableArray alloc] init];
    mDrumChannel = @10;
    
    // Set delegate for drag and drop
    [mTableView setDelegate:self];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.mTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

// Determine valid drop target
- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationCopy;
}

// This is called when the mouse button is released for a drop
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSArray *filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filenames[0]];
    
    // Handle the dropped file
    [self loadSMF:fileURL];
    
    return YES;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    // Get a new ViewCell
    NSTableCellView *cellView = 
        [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    LTViewerEvent *eventData = [mEvents objectAtIndex:row];
    NSString *text = @"";
    
    if ([tableColumn.identifier isEqualToString:@"track"] == YES)
    {
        (eventData.track == nil) ? (text = @"") : (text = eventData.track);
    }
    else if ([tableColumn.identifier isEqualToString:@"time"] == YES)
    {
        (eventData.time == nil) ? (text = @"") : (text = eventData.time);
    }
    else if ([tableColumn.identifier isEqualToString:@"channel"] == YES)
    {
        (eventData.channel == nil) ? (text = @"") :
            (text = eventData.channel);
    }
    else if ([tableColumn.identifier isEqualToString:@"status"] == YES)
    {
        (eventData.status == nil) ? (text = @"") :
            (text = eventData.status);
    }
    else if ([tableColumn.identifier isEqualToString:@"data1"] == YES)
    {
        (eventData.data1 == nil) ? (text = @"") : (text = eventData.data1);
    }
    else if ([tableColumn.identifier isEqualToString:@"data2"] == YES)
    {
        (eventData.data2 == nil) ? (text = @"") : (text = eventData.data2);
    }
    else if ([tableColumn.identifier isEqualToString:@"length"] == YES)
    {
        (eventData.length == nil) ? (text = @"") : (text = eventData.length);
    }
    else if ([tableColumn.identifier isEqualToString:@"hex"] == YES)
    {
        (eventData.hex == nil) ? (text = @"") : (text = eventData.hex);
    }
    else if ([tableColumn.identifier isEqualToString:@"ttime"] == YES)
    {
        text = [NSString stringWithFormat:@"%u", (UInt32)eventData.totalTime];
    }
    else if ([tableColumn.identifier isEqualToString:@"dtime"] == YES)
    {
        (eventData.deltaTime == nil) ? (text = @"") :
            (text = eventData.deltaTime);
    }

    cellView.textField.stringValue = text;

    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [mEvents count];
}

- (NSURL *)getSMFURL
{
    // Create and configure the file open dialog
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setDirectoryURL:[NSURL URLWithString:mSMFStartDir]];
    NSArray *extensions = @[@"mid", @"MID", @"midi", @"MIDI"];
    [openDlg setAllowedFileTypes:extensions];
    
    // Display the dialog, and if the OK button was pressed, process the file
    NSURL *fileURL = [[NSURL alloc] initWithString:@""];
    
    if ([openDlg runModal] == NSModalResponseOK)
    {
        fileURL = [[openDlg URLs] objectAtIndex:0];
        
        // Save path where we ended up for next time
        mSMFStartDir = (NSMutableString *)[[fileURL path]
                       stringByDeletingLastPathComponent];
    }
   
    return fileURL;
}

- (void)loadSMF:(NSURL *)fileURL
{
    mEvents = [[NSMutableArray alloc] init];
    NSData *fileData = [[NSData alloc] initWithContentsOfURL:fileURL];
    int count = (int)[fileData length];
    Byte *data = (Byte *)malloc(count);
    [fileData getBytes:data range:NSMakeRange(0, count)];
    [self parseSMF:data withLength:count];
    free(data);
    mFileName = [fileURL lastPathComponent];
    NSString *plural = (mNumTracks > 1) ? @"s" : @"";
    NSString *text =
    [NSString stringWithFormat:
     @"%@    SMF Type %u, %u Track%@, %u PPQN, %lu Events",
     mFileName, mFormat, mNumTracks, plural, mPpqn,
     (unsigned long)[mEvents count]];
    [mLabel setStringValue:text];
    [mLabel setTextColor:[NSColor whiteColor]];
    NSSortDescriptor *sd = [[NSSortDescriptor alloc]
                             initWithKey:@"totalTime" ascending:YES];
    mEvents = (NSMutableArray *)[mEvents sortedArrayUsingDescriptors:@[sd]];
    [mTableView reloadData];
}

- (IBAction)iaDrumChannel:(id)sender
{
    NSNumber *number;
    
    if ((number = [(NSControl *)sender objectValue]))
    {
        mDrumChannel = number;
    }
    else
    {
        [uiDrumChannel setStringValue:[mDrumChannel stringValue]];
    }
}

- (void)parseSMF:(Byte *)data withLength:(int) count
{
    UInt32 i;             // loop counter
    UInt32 n;             // loop counter or index
    UInt32 w;             // working storage index
    UInt64 chunk_length;  // chunk length
    UInt32 format;        // MIDI file format
    UInt32 bpm;           // beats per minute
    UInt32 ppqn;          // pulses-per-quarter-note
    Byte keysig;          // key signature
    UInt32 num_trks;      // number of track chunks
    UInt32 trk_num;       // track number
    UInt64 dt;            // delta time
    UInt64 tt;            // total time
    Byte b;               // general purpose byte data
    Byte event;           // track event
    Byte type;            // event type
    UInt64 el;            // event length
    UInt64 ed;            // event data
    Byte last_state;      // last status byte state
    Byte last_status;     // last status byte
    struct LTSMFEvent midiEvent;

    bpm = DEFAULT_BPM;
    ppqn = DEFAULT_PPQN;
    keysig = DEFAULT_KEY_SIG;

    // Check for a valid header chunk
    w = 0;

    if ((*(data + w++) != 'M') || (*(data + w++) != 'T') ||
        (*(data + w++) != 'h') || (*(data + w++) != 'd'))
    {
        LTLog(mLog, LTLOG_NO_FILE, OS_LOG_TYPE_ERROR,
              @"Input file is not a MIDI file!n");
        return;
    }

    // Get the header chunk length
    chunk_length = ((UInt64) *(data + w++)) << 24;
    chunk_length = chunk_length + (((UInt64) *(data + w++)) << 16);
    chunk_length = chunk_length + (((UInt64) *(data + w++)) << 8);
    chunk_length = chunk_length + ((UInt64) *(data + w++));

    // Get the format and check to see if we can handle it
    format = ((UInt32) *(data + w++)) << 8;
    format = format + ((UInt32) *(data + w++));

    if (format > 1)
    {
        LTLog(mLog, LTLOG_NO_FILE, OS_LOG_TYPE_ERROR,
              @"Can only process MIDI file formats 0 or 1!");
        return;
    }

    // Get the number of tracks
    num_trks = ((UInt32) *(data + w++)) << 8;
    num_trks = num_trks + ((UInt32) *(data + w++));

    // Get the ppqn value
    ppqn = ((UInt32) *(data + w++)) << 8;
    ppqn = ppqn + ((UInt32) *(data + w++));

    // Discard any extra header chunk bytes
    while (chunk_length > 6)
    {
        ++w;
        --chunk_length;
    }
    
    // Set file info
    mFormat = format;
    mNumTracks = num_trks;
    mPpqn = ppqn;

    // Now parse each track chunk
    trk_num = 0;

    for (i = 0; i < num_trks; i++)
    {
        tt = 0;
        last_state = SYS_BYTE;
        last_status = 0x00;

        for (n = 0; n < MIDI_DATA_SIZE; n++)
        {
            midiEvent.data[n] = '\0';
        }

        // Check for a valid track chunk
        if ((*(data + w++) != 'M') || (*(data + w++) != 'T') ||
            (*(data + w++) != 'r') || (*(data + w++) != 'k'))
        {
            LTLog(mLog, LTLOG_NO_FILE, OS_LOG_TYPE_ERROR,
                  @"Invalid track chunk!\n");
            return;
        }

        // Get the chunk length
        chunk_length = ((UInt64) *(data + w++)) << 24;
        chunk_length = chunk_length+(((UInt64) *(data + w++))<<16);
        chunk_length = chunk_length+(((UInt64) *(data + w++)) << 8);
        chunk_length = chunk_length + ((UInt64) *(data + w++));

        // Process each track event
        while (TRUE)
        {
            type = 0;

            // Get the delta time (variable length)
            if ((dt = *(data + w++)) & 0x80)
            {
                dt = dt & 0x7F;

                do
                {
                   dt = (dt << 7) + ((b = *(data + w++)) & 0x7F);
                } while (b & 0x80);
            }               

            // Get event and process it
            memset((void*)&midiEvent, 0, sizeof(midiEvent));
            midiEvent.deltaTime = dt;
            tt += dt;
            midiEvent.time = tt;
            midiEvent.track = trk_num + 1;
            event = *(data + w++);

            if (event < MIDI_STATUS)
            {
                switch (last_state)
                {
                    default:
                        case STAT_BYTE:
                            midiEvent.length = 3;
                            midiEvent.status = last_status;
                            midiEvent.data[0] = event;
                            midiEvent.data[1] = *(data + w++);
                            break;
                        case STAT_BYTE_X:
                            midiEvent.length = 2;
                            midiEvent.status = last_status;
                            midiEvent.data[0] = event;
                            break;
                }
            }
            else if ((event >= MIDI_NOTE_OFF) && (event < MIDI_SYSEX))
            {
                switch (event & MIDI_CHNLMASK)
                {
                    case MIDI_NOTE_OFF:
                    case MIDI_NOTE_ON:
                    case MIDI_AFTER_TOUCH:
                    case MIDI_CONTROL_CHANGE:
                    case MIDI_PITCH_WHEEL:
                    default:
                        midiEvent.length = 3;
                        midiEvent.status = event;
                        last_status = event;
                        midiEvent.data[0] = *(data + w++);
                        midiEvent.data[1] = *(data + w++);
                        last_state = STAT_BYTE;
                        break;
                    case MIDI_SET_PROGRAM:
                    case MIDI_SET_PRESSURE:
                        midiEvent.length = 2;
                        midiEvent.status = event;
                        last_status = event;
                        midiEvent.data[0] = *(data + w++);
                        last_state = STAT_BYTE_X;
                        break;
                }
            }
            else if (event == MIDI_META_EVENT)
            {
                midiEvent.status = event;
                last_status = event;
                type = *(data + w++);
                n = 0;
                midiEvent.data[n++] = type;
                el = *(data + w++);
                midiEvent.data[n++] = el;

                if (el & 0x80)
                {
                    el = el & 0x7F;

                    do
                    {
                        b = *(data + w++) & 0x7F;
                        midiEvent.data[n++] = b;
                        el = (el << 7) + b;
                    } while (b & 0x80);
                }
                   
                midiEvent.length = el + n + 1;
                midiEvent.mlength = el;

                if (type == TYPE_TEMPO)
                {
                    ed = (((UInt64) *(data + w++)) << 16);
                    ed = ed + (((UInt64) *(data + w++)) << 8);
                    ed = ed + ((UInt64) *(data + w++));
                    bpm = (UInt32)(60000000.0 / ed);
                    midiEvent.data[n++] = bpm;
                }
                else if ((type == TYPE_SEQ_NAME) || (type == TYPE_SEQ_SPEC) ||
                         (type == TYPE_TEXT) || (type == TYPE_COPYRIGHT) ||
                         (type == TYPE_CUE) || (type == TYPE_MARKER) ||
                         (type == TYPE_INS_NAME) || (type == TYPE_LYRIC))
                {
                    while (el > 0)
                    {
                        b = *(data + w++);

                        if (n < MIDI_DATA_SIZE)
                        {
                            midiEvent.data[n++] = b;
                        }

                        --el;
                    }
                }
                else if (type == TYPE_TIME_SIG)
                {
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                }
                else if (type == TYPE_KEY_SIG)
                {
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    keysig = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                }
                else if (type == TYPE_SMPTE)
                {
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                }
                else if (type == TYPE_SELECT_PORT)
                {
                    b = *(data + w++);
                    midiEvent.data[n++] = b;
                }
                else
                {
                    while (el > 0)
                    {
                        ++w;
                        --el;
                    }
                }
            }
            else if (event == MIDI_SYSEX)
            {
                midiEvent.status = event;
                last_status = event;
                el = *(data + w++);
                n = 0;
                midiEvent.data[n++] = el;
                
                if (el & 0x80)
                {
                    el = el & 0x7F;

                    do
                    {
                        b = *(data + w++) & 0x7F;
                        midiEvent.data[n++] = b;
                        el = (el << 7) + b;
                    } while (b & 0x80);
                }               

                midiEvent.length = el + n + 1;

                while (el > 0)
                {
                    b = *(data + w++);

                    if (n < MIDI_DATA_SIZE)
                    {
                        midiEvent.data[n++] = b;
                    }

                    --el;
                }

                if (n < MIDI_DATA_SIZE)
                {
                    midiEvent.data[n++] = b;
                }
            }
             
            // Store event
            midiEvent.ppqn = ppqn;
            midiEvent.keysig = keysig + 7;
            LTViewerEvent *newEvent =
                [[LTViewerEvent alloc] initWithEvent:midiEvent
                 withDrumChannel:mDrumChannel];
            [mEvents addObject:newEvent];
            
            if (type == TYPE_END)
            {
                break;
            }
        }

        ++trk_num;
    }
}

- (IBAction)iaLoadFile:(id)sender
{
    NSURL *fileURL = [self getSMFURL];
    [self loadSMF:fileURL];
}

@end
