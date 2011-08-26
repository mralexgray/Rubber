//
//  main.c
//  hilite
//
//  Created by Aaron Dodson on 8/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <xpc/xpc.h>
#include <assert.h>
#include "sourcehighlight.h"
#include <sstream>

static void hilite_peer_event_handler(xpc_connection_t peer, xpc_object_t event) 
{
	xpc_type_t type = xpc_get_type(event);
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
	} else {
		assert(type == XPC_TYPE_DICTIONARY);
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        const char *code = xpc_dictionary_get_string(event, "code");
        const char *lang = xpc_dictionary_get_string(event, "language");
        
        NSString *highlightStyle = [[NSBundle mainBundle] pathForResource:@"style" ofType:@"css"];
        
        //Use the source-highlight library to do all the difficult stuff
        srchilite::SourceHighlight sourceHighlight("html.outlang");
        sourceHighlight.setDataDir([[[[NSBundle mainBundle] pathForResource:@"c" ofType:@"lang" inDirectory:@"data"] stringByDeletingLastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding]);
        std::istringstream iss(code);
        std::ostringstream outstr;
        std::string css([highlightStyle UTF8String]);
        sourceHighlight.setStyleCssFile(css);
        sourceHighlight.highlight(iss, outstr, lang);
        
        xpc_dictionary_set_string(reply, "html", outstr.str().c_str());
        xpc_connection_send_message(peer, reply);
        xpc_release(reply);
	}
}

static void hilite_event_handler(xpc_connection_t peer) 
{
	// By defaults, new connections will target the default dispatch
	// concurrent queue.
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		hilite_peer_event_handler(peer, event);
	});
	
	// This will tell the connection to begin listening for events. If you
	// have some other initialization that must be done asynchronously, then
	// you can defer this call until after that initialization is done.
	xpc_connection_resume(peer);
}

int main(int argc, const char *argv[])
{
	xpc_main(hilite_event_handler);
	return 0;
}
