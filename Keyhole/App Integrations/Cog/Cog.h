/*
 * Cog.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class CogItem, CogApplication, CogWindow, CogPlaylistentry;

enum CogSaveOptions {
	CogSaveOptionsYes = 'yes ' /* Save the file. */,
	CogSaveOptionsNo = 'no  ' /* Do not save the file. */,
	CogSaveOptionsAsk = 'ask ' /* Ask the user whether or not to save the file. */
};
typedef enum CogSaveOptions CogSaveOptions;

@protocol CogGenericMethods

- (void) closeSaving:(CogSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end



/*
 * Cog Suite
 */

// A scriptable object.
@interface CogItem : SBObject <CogGenericMethods>

@property (copy) NSDictionary *properties;  // All of the object's properties.


@end

// Cog's top level scripting object.
@interface CogApplication : SBApplication

- (SBElementArray<CogWindow *> *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *version;  // The version of the application.
@property (copy, readonly) CogPlaylistentry *currentEntry;  // The current entry playing.

- (void) open;  // Open an object.
- (void) quitSaving:(CogSaveOptions)saving;  // Quit an application.
- (void) play;  // Begin playback.
- (void) pause;  // Pause playback.
- (void) stop;  // Stop playback.
- (void) previous;  // Play previous track.
- (void) next;  // Play next track.

@end

// A window.
@interface CogWindow : SBObject <CogGenericMethods>

@property (copy) NSString *name;  // The full title of the window.
- (NSNumber *) id;  // The unique identifier of the window.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (copy, readonly) id document;  // The document whose contents are being displayed in the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (readonly) BOOL titled;  // Whether the window has a title bar.
@property (copy) NSNumber *index;  // The index of the window in the back-to-front window ordering.
@property (readonly) BOOL floating;  // Whether the window floats.
@property (readonly) BOOL miniaturizable;  // Whether the window can be miniaturized.
@property BOOL miniaturized;  // Whether the window is currently miniaturized.
@property (readonly) BOOL modal;  // Whether the window is the application's current modal window.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.


@end

@interface CogPlaylistentry : SBObject <CogGenericMethods>

@property (copy, readonly) NSURL *url;  // The URL of the entry.
@property (copy, readonly) NSString *album;  // The album of the entry.
@property (copy, readonly) NSString *albumartist;  // The album artist of the entry.
@property (copy) NSString *artist;  // The artist of the entry
@property (copy) NSString *composer;  // The composer of the entry
@property (copy, readonly) NSString *title;  // The title of the entry.
@property (copy, readonly) NSString *genre;  // The genre of the entry.
@property (readonly) double length;  // The length of the entry, in seconds.
@property (readonly) NSInteger track;  // The track number of the entry.
@property (readonly) NSInteger disc;  // The disc number of the entry.
@property (readonly) NSInteger year;  // The year of the entry.
@property (readonly) NSInteger bitrate;  // The bitrate of the entry, in kilobits per second.
@property (copy, readonly) NSString *playcount;  // The play count of the entry.
@property (copy, readonly) NSString *playinfo;  // The play count info of the entry, as either first seen time, or also last played time. May be empty string.
@property (copy, readonly) NSString *spam;  // Formatted now playing spam for the entry.


@end

