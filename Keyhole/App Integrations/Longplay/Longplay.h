/*
 * Longplay.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class LongplayApplication, LongplayWindow, LongplayApplication, LongplayEntry, LongplayAlbum, LongplayPlaylist, LongplayCollection, LongplayOrder, LongplayTrack;

enum LongplaySearchMode {
	LongplaySearchModeDefault = 'SMDe' /* Treat query as entire search string */,
	LongplaySearchModeAutocompletion = 'SMAu' /* Treat query as prefix of search string */
};
typedef enum LongplaySearchMode LongplaySearchMode;

@protocol LongplayGenericMethods

- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.

@end



/*
 * Standard Suite
 */

// The application's top-level scripting object.
@interface LongplayApplication : SBApplication

- (SBElementArray<LongplayWindow *> *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the active application?
@property (copy, readonly) NSString *version;  // The version number of the application.

- (BOOL) exists:(id)x;  // Verify that an object exists.
- (NSArray<LongplayEntry *> *) topAlbumsBy:(id)by max:(NSInteger)max;  // gets the top albums for the specified order.
- (NSArray<LongplayEntry *> *) searchFor:(NSString *)for_ mode:(LongplaySearchMode)mode;  // search for albums or playlists matching the search string.
- (void) play;  // play the current album/playlist or the specified one.
- (void) playpause;  // toggle the playing/paused state of the current album/playlist.
- (void) pause;  // pauses the current album/playlist.
- (void) skip;  // skip the current album/playlist, and either play the next in the queue or a random one.
- (void) stop;  // stop playback
- (void) nextTrack;  // advance to the next track in the current album/playlist, or start the next album if this is the last track
- (void) previousTrack;  // return to the previous track in the current album/playlist

@end

// A window.
@interface LongplayWindow : SBObject <LongplayGenericMethods>

@property (copy, readonly) NSString *name;  // The title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Does the window have a close button?
@property (readonly) BOOL miniaturizable;  // Does the window have a minimize button?
@property BOOL miniaturized;  // Is the window minimized right now?
@property (readonly) BOOL resizable;  // Can the window be resized?
@property BOOL visible;  // Is the window visible right now?
@property (readonly) BOOL zoomable;  // Does the window have a zoom button?
@property BOOL zoomed;  // Is the window zoomed right now?


@end



/*
 * Longplay Suite
 */

// The app's top level scripting object.
@interface LongplayApplication (LongplaySuite)

- (SBElementArray<LongplayAlbum *> *) albums;
- (SBElementArray<LongplayPlaylist *> *) playlists;
- (SBElementArray<LongplayEntry *> *) entries;
- (SBElementArray<LongplayCollection *> *) collections;
- (SBElementArray<LongplayOrder *> *) orders;

@property (copy, readonly) NSString *appVersion;  // The version of the app.
@property (copy, readonly) NSString *playerState;  // The current player state ('playing' or 'paused').
@property (copy, readonly) LongplayTrack *currentTrack;  // The currently playing track.
@property BOOL visible;  // Is Longplay visible?

@end

// a playable media item such as an album or playlist
@interface LongplayEntry : SBObject <LongplayGenericMethods>

- (NSString *) id;  // the unique identifier of the album/playlist
@property (copy, readonly) NSString *kind;  // the kind of the item, either 'album' or 'playlist'

- (void) play;  // play the current album/playlist or the specified one.
- (void) playNext;  // enqueue the specified album/playlist to be played next.
- (void) playLast;  // enqueue the specified album/playlist to be played last.
- (void) addTo:(LongplayCollection *)to;  // add the specified album/playlist to a collection
- (void) removeFrom:(LongplayCollection *)from;  // remove the specified album/playlist to a collection

@end

// an album
@interface LongplayAlbum : LongplayEntry

@property (copy, readonly) NSString *name;  // the album title
@property (copy, readonly) NSString *artist;  // the album artist
@property (readonly) NSInteger year;  // the year the album was recorded/released
@property (copy, readonly) NSString *artworkURL;  // the (temporary) URL of the artwork


@end

// a playlist
@interface LongplayPlaylist : LongplayEntry

@property (copy, readonly) NSString *name;  // the playlist name
@property (copy, readonly) NSString *artworkURL;  // the (temporary) URL of the artwork


@end

// a collection
@interface LongplayCollection : SBObject <LongplayGenericMethods>

- (SBElementArray<LongplayEntry *> *) entries;

- (NSString *) id;  // the unique identifier of the collection
@property (copy, readonly) NSString *name;  // the name of the collection

- (void) shuffle;  // start album shuffle for the specified collection or order.

@end

// a order that can be used for shuffling
@interface LongplayOrder : SBObject <LongplayGenericMethods>

- (NSString *) id;  // the unique identifier of the order
@property (copy, readonly) NSString *name;  // the name of the order

- (void) shuffle;  // start album shuffle for the specified collection or order.

@end

// a currently playing track
@interface LongplayTrack : SBObject <LongplayGenericMethods>

@property (copy, readonly) NSString *name;  // the track name
@property (copy, readonly) NSString *trackArtist;  // the track artist
@property (copy, readonly) LongplayEntry *entry;  // the track's album or playlist
@property BOOL loved;  // whether the track is loved/favorited (setting to true sets track rating to 5, setting to false sets it to 0)
@property NSInteger rating;  // star rating of track; 0 for unrated


@end

