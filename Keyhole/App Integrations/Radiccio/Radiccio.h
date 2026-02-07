/*
 * Radiccio.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class RadiccioApplication, RadiccioApplication;

enum RadiccioRdPS {
	RadiccioRdPSStopped = 'rdST',
	RadiccioRdPSPlaying = 'rdPL',
	RadiccioRdPSPaused = 'rdPA'
};
typedef enum RadiccioRdPS RadiccioRdPS;



/*
 * Standard Suite
 */

// The application's top-level scripting object.
@interface RadiccioApplication : SBApplication

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the active application?
@property (copy, readonly) NSString *version;  // The version number of the application.

- (void) quit;  // Quit the application.
- (void) play;  // Play the current track
- (void) pause;  // Pause playback
- (void) playpause;  // Toggle the playing/paused state of the current track, or stop if it is a live stream
- (void) nextTrack;  // Advance to the next track in the current playback queue
- (void) previousTrack;  // Return to the previous track in the current playback queue
- (void) stop;  // Stop playback
- (void) restartTrack;  // Reposition to beginning of current track

@end



/*
 * Music Suite
 */

// The application program
@interface RadiccioApplication (MusicSuite)

@property (readonly) double playerPosition;  // the player’s position within the currently playing track in seconds.
@property (readonly) RadiccioRdPS playerState;  // is the player stopped, paused, or playing?
@property NSInteger soundVolume;  // the sound output volume (0 = minimum, 100 = maximum; must be divisible by 5)
@property (readonly) NSInteger queuePosition;  // the index of the current track in the playback queue (starting from 1)
@property (readonly) NSInteger queueCount;  // the total number of tracks currently in the playback queue

@end

