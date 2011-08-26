//
//  main.c
//  coderunner
//
//  Created by Aaron Dodson on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <xpc/xpc.h>
#include <assert.h>

static void coderunner_peer_event_handler(xpc_connection_t peer, xpc_object_t event) 
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
        const char *_code = xpc_dictionary_get_string(event, "code");
        const char *lang = xpc_dictionary_get_string(event, "language");
        
        NSString *code = [NSString stringWithCString:_code encoding:NSUTF8StringEncoding];
        NSString *temp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"];
        [code writeToURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", temp]] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        NSData *compilerOutput;
        
        if (strcmp(lang, "c.lang") == 0) {
            NSTask *compiler = [[NSTask alloc] init];
            NSMutableArray *args = [NSMutableArray array];
            NSPipe *output = [NSPipe pipe];
            
            [args addObject:@"main.c"];
            [args addObject:@"-o"];
            [args addObject:@"a.out"];
            [compiler setCurrentDirectoryPath:NSTemporaryDirectory()];
            [compiler setLaunchPath:@"/usr/bin/clang"];
            [compiler setArguments:args];
            [compiler setStandardOutput:output];
            [compiler setStandardError:output];
            [compiler launch];
            
            compilerOutput = [[output fileHandleForReading] readDataToEndOfFile];
            
            [compiler waitUntilExit];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"a.out"]]) {
            NSTask *program = [[NSTask alloc] init];
            NSMutableArray *args = [NSMutableArray array];
            NSPipe *output = [NSPipe pipe];
            
            [args addObject:@"main.c"];
            [args addObject:@"-o"];
            [args addObject:@"a.out"];
            [program setCurrentDirectoryPath:NSTemporaryDirectory()];
            [program setLaunchPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"a.out"]];
            [program setArguments:args];
            [program setStandardOutput:output];
            [program setStandardError:output];
            [program launch];
            
            NSData *programOutput = [[output fileHandleForReading] readDataToEndOfFile];
            
            [program waitUntilExit];
            
            NSString *programLog = [[NSString alloc] initWithData:programOutput encoding:NSUTF8StringEncoding];
            xpc_dictionary_set_string(reply, "programOutput", [programLog cStringUsingEncoding:NSUTF8StringEncoding]);
            xpc_connection_send_message(peer, reply);
        } else {
            NSString *compilerLog = [[NSString alloc] initWithData:compilerOutput encoding:NSUTF8StringEncoding];
            xpc_dictionary_set_string(reply, "compilerOutput", [compilerLog cStringUsingEncoding:NSUTF8StringEncoding]);
            xpc_connection_send_message(peer, reply);
        }
        
        xpc_release(reply);
	}
}

static void coderunner_event_handler(xpc_connection_t peer) 
{
	// By defaults, new connections will target the default dispatch
	// concurrent queue.
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		coderunner_peer_event_handler(peer, event);
	});
	
	// This will tell the connection to begin listening for events. If you
	// have some other initialization that must be done asynchronously, then
	// you can defer this call until after that initialization is done.
	xpc_connection_resume(peer);
}

int main(int argc, const char *argv[])
{
	xpc_main(coderunner_event_handler);
	return 0;
}
