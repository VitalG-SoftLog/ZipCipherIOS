//============================================================
//
// Copyright (c) nCrypted Cloud, 2012. All Rights Reserved.
//
// File: NCryptBox.h
// Created By: Oleg Lavronov on 9/5/12.
//
// Description: Namespace for nCrypted Cloud functions.
//
//===========================================================
#import "SystemConfiguration/SystemConfiguration.h"
#import "WebServiceProvider.h"
#import "NCryptBox.h"

@implementation WebServiceProvider

@synthesize responseData = _responseData;
@synthesize userName = _userName;
@synthesize userEmail = _userEmail;
@synthesize userPassword = _userPassword;
@synthesize authToken = _authToken;
@synthesize computerName = _computerName;

- (id) init {
	if (self= [super init]) {
        self.responseData = [NSMutableData data];
        _userName = @"";
        _userEmail = @"";
        _userPassword = @"";
        _authToken = @"";
        _computerName = [[UIDevice currentDevice] name];
	}
	return self;
}

#pragma mark -
#pragma mark Internet Connection
- (BOOL) isConnectionAvailable
{
	SCNetworkReachabilityFlags flags;
    BOOL receivedFlags;

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), [kWebServiceDNS UTF8String]);
    receivedFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);

    if (!receivedFlags || (flags == 0) )
    {
        return FALSE;
    } else {
		return TRUE;
	}
}

- (void) setAuthToken:(NSString *)newAuthToken
{
    if (newAuthToken != _authToken) {
        _authToken = newAuthToken;
        [[NSUserDefaults standardUserDefaults] setObject:newAuthToken forKey:@"authToken"];
    }
}

- (void) setUserEmail:(NSString *)newUserEmail
{
    if (newUserEmail != _userEmail) {
        _userEmail = newUserEmail;
        [[NSUserDefaults standardUserDefaults] setObject:newUserEmail forKey:@"userEmail"];
    }
}

- (void) setComputerName:(NSString *)newComputerName
{
    if (newComputerName != _computerName) {
        _computerName = newComputerName;
        [[NSUserDefaults standardUserDefaults] setObject:newComputerName forKey:@"computerName"];
    }
}

- (NSMutableURLRequest*) prepereRequest:(NSDictionary *)data
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:kWebServiceDNS]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:5.0];
    //convert object to data
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                       options:NSJSONWritingPrettyPrinted error:&error];

    [request setHTTPBody:jsonData];

    NSLog(@"Request: %@", request);
    //    [[[NSURL alloc] initWithScheme: @"http" host: @"myproxy.com:3333" path: @"http://www.google.com/index.html"] autorelease];
    //    NSLog(@"%@", [request allHTTPHeaderFields]);
    //    NSLog(@"%@",[request absolute ]);
    return request;
}

- (void) send:(NSDictionary *)data
{
    [[[NSURLConnection alloc] initWithRequest:[self prepereRequest:data] delegate:self] autorelease];
}


#pragma mark -
#pragma mark Login
/*
 data={ "auth-info" :
 { 	"authtoken" : "",
 "computername" : "",
 "email" : ""
 },
 "message" :
 {
 "ver" : "1.0",
 "message-type" : "RegisterAccount",
 "computername" : "testing",
 "email" : "John12@Paglierani.net",
 "firstname" : "John",
 "invitation" : "",
 "lastname" : "Paglierani",
 "name" : "John Paglierani",
 "password" : "xxxxxx"
 } ,
 "debug" : true
 }
 */
/*
 { "auth-info" :
 { "authtoken" : "", "computername" : "", "email" : "igor@test2.com" },
 "debug" : true,
 "message" :
 { "computername" : "zipcipher",
 "email" : "igor@testnew.com",
 "firstname" : "Igor",
 "invitation" : "",
 "lastname" : "Test",
 "name" : "Igor Test",
 "password" : "test" }, "message-type" : "RegisterAccount", "ver" : "1.0" }
 */
- (void) sendRegisterAccount:(NSString *)userEmail firstName:(NSString *)firstName
                    lastName:(NSString *)lastName invitation:(NSString *)invitation
                computername:(NSString *)computername password:(NSString *)password
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"", @"authtoken",
                               @"", @"computername",
                               @"", @"email",
                               nil];

    NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
                             computername,   @"computername",
                             userEmail,      @"email",
                             firstName,      @"firstname",
                             lastName,       @"lastname",
                             invitation,     @"invitation",
                             @"Name",        @"name",
                             password,       @"password",
                             nil];

    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kRegisterAccount,               @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];
    [self send:data];
}

/*
 Type: RetrieveKeys
 Example:
 data={ "auth-info" : { "authtoken" : "20bdcc801b2347da514611546624ebfa", "computername" : "testing", "email" : "John12@Paglierani.net" },
 "debug" : true,
 "message" : {  },
 "message-type" : "RetrieveKeys",
 "ver" : "1.0"
 }

 Server Reply: {"auth-info":{"authtoken":"20bdcc801b2347da514611546624ebfa","computername":"testing","email":"John12@Paglierani.net"},
 "debug":true,
 "message":{
 "keys":
 [
 {"id":"{023746C9-1D4E-4D94-9165-512AB800170B}","data":"","label":"MyBackupKey"},
 {"id":"{CB2AD46D-E6B2-F44D-B76F-A315F32A7313}","data":"","label":"MyKey"}
 ]
 },
 "message-type":"RetrieveKeys",
 "ver":"1.0",
 "debugstr":"",
 "error-code":null,
 "error":0
 }
 */

- (void) sendRetrieveKeys
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self authToken],    @"authtoken",
                               [self computerName], @"computername",
                               [self userEmail],    @"email",
                               nil];

    NSDictionary* message = [[[NSDictionary alloc] init] autorelease];

    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kRetrieveKeys,                  @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];
    [self send:data];
}

/*
 Type: StoreKeys"
 MessageProperties:
 "Keys" - list of keys with "id", "label" and "data" properties.
 Example
 data={ "auth-info" :
 { "authtoken" : "20bdcc801b2347da514611546624ebfa", "computername" : "testing", "email" : "John12@Paglierani.net" },
 "debug" : true,
 "message" : {
 "keys" : [ { "data" : "", "id" : "{023746C9-1D4E-4D94-9165-512AB800170B}", "label" : "MyBackupKey" },
 { "data" : "", "id" : "{CB2AD46D-E6B2-F44D-B76F-A315F32A7313}", "label" : "MyKey" }
 ]
 },
 "message-type" : "StoreKeys",
 "ver" : "1.0"
 }"

 "Server Reply: {"auth-info":{"authtoken":"20bdcc801b2347da514611546624ebfa","computername":"testing","email":"John12@Paglierani.net"},
 "debug":true,
 "message":{
 "keys":[
 {"data":"<zipcipher>\\r\\n  <kc>\\r\\n    <k>\\r\\n      <kid>{023746C9-1D4E-4D94-9165-512AB800170B}<\/kid>\\r\\n      <kv><![CDATA[PFJTQUtleVZhbHVlPjxNb2R1bHVzPnluUWFZeWJTd0dITVZZMVRmenpxNTkrMHlsUjY3SHArcDFVVXVJOHRBZHBuUC9KOE12RzVxQzkyM25VRkptQ0pjTGdWQjFuWlQ4Y244bUYrK0RJTVNEUEpGRlNibUJpWE1IeHMvSDBNb3hRVnVnaEUzcE5kRUZXeXh1bFNXemtvc1czQm1SKzU5VlhrUFpPNnh2NDBQMmhoZFdPdlMxM2tOaFpBdlZINk1TZFhPWm1yM0ZWZmExUTZ2VHpwVGw3Z0x5Y1NkeGt2SmJYQi8zR0VKZkZka3VYRFdwaUdGL1lXVERiTWRZWFhHbEJRT0MzMSsvK1haajNqTGlaLy9Gc2FtbjhLQlFoaDVldSt4VGtoalJkTFYvNERGQnRwS2ZkVjR6SVNNSVJTcXJ5RUVkOE8rQlZUQk9CcnhINllQbjZ6U2U0V0NJL1h1SHBRY0hTKzJYVk1nUT09PC9Nb2R1bHVzPjxFeHBvbmVudD5BUUFCPC9FeHBvbmVudD48UD45TmZkMjJFV1p5T1E2aVV3YVZwNkU3WURTMUVTU0gvNCtHaExTK2gwakxUT1VDVVhHU3ZMakxqdCtLSHVoR1MzVnhLaWJsMFdKU09uRExxd24zZFRpcW1QMHEyenR6dnJGM0lZN28xVFQxemtzQUJRVU5jNUtsRHhyQW1TOFU5cmd5QndzYUF1b2dCdUs4QnJnM3ExR0dzSWtDTldsbWtqdXFGZVlKQm9sOHM9PC9QPjxRPjA2M0JFR0VHN1k3aWc1NWdLRVZRS3VVUTZSd2I1ZnhQQUxwbjF5S05QMU5Dc04xU3ZoaUg2NzdXVUl3cUF2UzhEUHcwNURrOTVOY05YeVZUNm01SjlvbTdTMFlzMFhsRkZ1T1VDallFZGF2QjJyd2ZJNmRISnp4b3hTQmFTZ2k2aE1EYU1PWkZhSWZMQXpTaGkrbVpHR0J4L3RnSHpQVmlWQXJ4NUFzYXEyTT08L1E PERQPmFwcis3MEVqbHY3R1h4eVlLcGNKWmtHdXg0RmlHNDBVNDF2TnhSeE9ldUZTbjFTMjdPL0RyZDdyUm9HREw4UUdpL1FDSTFtR2hkOHpJZmk3WklONUxYdk1zbWVOUTIva1dZNEZTd0RmMEVOYkUwTGZ0WU13VWJ0eXJueHdyWDd1Q2ViN0NtdjdRZkE4Qi9LOUhUODFVSTl4NkFocThBeVJVUFpuK0ZXSUpPYz08L0RQPjxEUT5jS3RFWHZaMkhJMzRMVHhvVENjUWs3UlhPdXkyUU1UNlBCWDczWHZMbU5BMWFEUjFyUzhiY2JTakdENXl3aDRIMWhXTUJZb2VVcWJRdkRyL0hvSFRwb0VMQ3Zid05oTUpYalNHQUtWZDNGQXVuOEdRQlljdERVcFBMZFdabVZ4cUF1MHZkZVdyUGdkQlhKUndCQ3V6VEZGUmUrYjZ4L0k0Z3lsTU5TaGY2cWM9PC9EUT48SW52ZXJzZVE dFgzZHNDcWJXSDJrS1AxVmpMUyszNU9wcXFBS3IwWlNhR085VVp2akhYbkU2enN0Y3M4cytBUHB0VVVFbjFNVHhLTDd3b0FsNDlzbzlEMVRKY1hqZDdqRHZqL1hNZ3I4ajN2c3NmazR5ZW5udEtVdlFYYXEzckEyaWEzWmZEVVJzK0NrS0FBT3RSQlIwZzRhNzNrVnVmeUYwL0xtYTUzRnFHOUF4OCtGL2lFPTwvSW52ZXJzZVE PEQ cWl6TndXcHczS1ZZVE5GdXpoVTJuNUc3TmhlcysvbzdYQXg0VG1xTE9uT0xOb1Z0UUtWUG1iL0wrMUlCOGpCVFZ4eGxFTGpGb2ZtVjZuZHBjdGNlMjlJcnc1c2E3czQ4eDlUUEI2MVZZZjhRQkQvUEpBaGF3ZEJIWmt2Wm5qUjlzQ2JDQlNSVis1TW5OMXRtTkw2WXpIUEErQnZDeldjdTNRZjNneXZWVWxwdmlYbk00RDBiUml3d0grNXVCYUdKOEIycjVrcFRWQmVrTDJrWDFyeHBhbmxNb3pNYVlXcmZvQ1JobFRpZFFWQnljbzBRNi9VMytweWlYRnJQc0czTzlLRUFYYXRSTlZWMEkwOTlPWmgwSFYwNUd2aS93U0ZaMDQ1ZEhGMEVqYmRRek1UQVZ3TnJHdHk0a09hdVVqbFVkMVpFdnlKQzJ4b2w3ZWw3bDNaTHdRPT08L0Q PC9SU0FLZXlWYWx1ZT4=]]><\/kv>\\r\\n    <\/k>\\r\\n  <\/kc>\\r\\n<\/zipcipher>","id":"{023746C9-1D4E-4D94-9165-512AB800170B}","label":"MyBackupKey"},{"data":"<zipcipher>\\r\\n  <kc>\\r\\n    <sk>\\r\\n      <skid>{CB2AD46D-E6B2-F44D-B76F-A315F32A7313}<\/skid>\\r\\n      <skv><![CDATA[0kIRc763Lb zyTtRTenOjRyD8taUnj9pMcZRTmFZBg0=]]><\/skv>\\r\\n    <\/sk>\\r\\n\\r\\n  <\/kc>\\r\\n<\/zipcipher>",
 "id":"{CB2AD46D-E6B2-F44D-B76F-A315F32A7313}",
 "label":"MyKey"}
 ]
 },
 "message-type":"StoreKeys",
 "ver":"1.0",
 "debugstr":"",
 "error-code":null,
 "error":0
 }
 */

- (void) sendStoreKeys:(NSDictionary*)keys withKeyID:(NSString*)keyID
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self authToken],    @"authtoken",
                               [self computerName], @"computername",
                               [self userEmail],    @"email",
                               nil];

    NSString* privateKey = [keys valueForKey:kPrivateRSAKey];
    NSString* publicKey = [keys valueForKey:kPublicRSAKey];

    NSString* privateKeyXml = [NCryptBox generateEncryptionKeyFile:keyID keyValue:privateKey];
    NSString* publicKeyXml = [NCryptBox generateEncryptionKeyFile:keyID keyValue:publicKey];

    NSDictionary* k = [NSDictionary dictionaryWithObjectsAndKeys:
                       keyID,           @"key-id",
                       privateKeyXml,   @"key-data",
                       @"MyBackupKey",  @"key-label",
                       @"1",            @"key-type",
                       publicKeyXml,    @"owner-backup-key",
                       nil];

    NSArray* messageKeys = [[[NSMutableArray alloc] initWithObjects:k, nil] autorelease];
    NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
                             messageKeys, @"keys",
                             nil];

    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kStoreKeys,                     @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];
    [self send:data];

}

/*
 { "auth-info" :
 { "authtoken" : "",
 "computername" : "",
 "email" : "igor@testnew.com" },
 "debug" : true,
 "message" : { "computername" : "zipcipher", "email" : "igor@testnew.com", "password" : "test" },
 "message-type" : "AssociateMachine", "ver" : "1.0"
 }
 */

- (void) sendAssociateMachine:(NSString *)userEmail
                  andPassword:(NSString *)password
              andComputerName:(NSString *)computerName
{

    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"", @"authtoken",
                               @"", @"computername",
                               @"", @"email",
                               nil];

    NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
                             computerName,       @"computername",
                             userEmail,          @"email",
                             password,           @"password",
                             @"Name",            @"name",
                             nil];

    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kAssociateMachine,              @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];

    [self send:data];
}

- (void) sendUnlinkMachine
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self authToken], @"authtoken",
                               [self computerName], @"computername",
                               [self userEmail], @"email",
                               nil];

    NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"authtoken",@"",
                             nil];


    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kUnlinkMachine,                 @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];

    [self send:data];
}


- (void) sendValidateToken
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self authToken], @"authtoken",
                               [self computerName], @"computername",
                               [self userEmail], @"email",
                               nil];

    NSDictionary* message = [[[NSDictionary alloc] init] autorelease];

    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kValidateToken,                 @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];

    [self send:data];
}

/*
 { "auth-info" :
 { "authtoken" : "5a58e0fc1026a3f5b762615bde50fcb5", "computername" : "zipcipher1", "email" : "igor@ncryptedbox.com" },
 "debug" : true,
 "message" : { "key-id" : "{EDEA59A2-5C02-4C15-951F-18EE8A9DA1E7}" },
 "message-type" : "GetKey", "ver" : "1.0" }
 */
- (NSDictionary*) sendSynchronousGetKey:(NSString*)keyID
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self authToken], @"authtoken",
                               [self computerName], @"computername",
                               [self userEmail], @"email",
                               nil];

    NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
                             keyID,                 @"key-id",
                             nil];


    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kGetKey,                        @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];

    NSError        *error = nil;
    NSURLResponse  *response = nil;
    NSData* content = [NSURLConnection sendSynchronousRequest:[self prepereRequest:data] returningResponse:&response error:&error];
    if (!error)
    {
        return [self parseResponse:content async:NO];
    }
    return nil;
}

- (void) sendGetKey:(NSString*)keyID
{
    NSDictionary* auth_info = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self authToken], @"authtoken",
                               [self computerName], @"computername",
                               [self userEmail], @"email",
                               nil];

    NSDictionary* message = [NSDictionary dictionaryWithObjectsAndKeys:
                             keyID,                 @"key-id",
                             nil];


    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:YES],  @"debug",
                          @"1.0",                         @"ver",
                          kGetKey,                        @"message-type",
                          message,                        @"message",
                          auth_info,                      @"auth-info",
                          nil];
    [self send:data];
}


- (void)dialogServerError:(NSError*)error
{
    NSLog(@"Server error: %@",[error description]);
}

#pragma mark -
#pragma mark NSURLConnection delegates
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed: %@",[error description]);
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLCredential *credential = [NSURLCredential credentialWithUser:self.userName
                                                             password:self.userPassword
                                                          persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    NSLog(@"Authentication Challenge");
}

#pragma mark -
#pragma mark NSURLConnection delegates

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Response: %@", response);
    NSHTTPURLResponse* answer = nil;

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        answer = (NSHTTPURLResponse*)response;
        NSLog(@"Response: %d\n%@", [answer statusCode], [answer allHeaderFields]);
    }

    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveResponse");
    [self.responseData appendData:data];
}

- (NSDictionary*)parseResponse:(NSData*)response async:(BOOL)async
{
    NSLog(@"Received %d bytes of data",[response length]);
    NSString *content = [NSString stringWithUTF8String:[response bytes]];
    NSLog(@"%@", content);

    // convert to JSON
    NSError *error = nil;
    NSDictionary* result = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
    // show all values
    for(id key in result) {
        id value = [result objectForKey:key];
        NSLog(@"%@ => %@", key, value);
    }

    NSDictionary* auth_info = nil;
    NSDictionary* message = nil;

    id object = [result objectForKey:@"auth-info"];
    if ([object isKindOfClass:[NSDictionary class]]) {
        auth_info = object;
    }

    object = [result objectForKey:@"message"];
    if ([object isKindOfClass:[NSDictionary class]]) {
        message = object;
    }
    NSLog(@"\nauth-info:\n%@\nmessage:\n%@", auth_info, message);

    NSString* errorCode = [result objectForKey:@"error-code"];
    if (![errorCode isKindOfClass:[NSNull class]]) {
        if ([errorCode integerValue] != kWebNONE) {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:[self errorToString:[errorCode integerValue]] forKey:NSLocalizedDescriptionKey];
            NSError* error = [NSError errorWithDomain:@"Server error" code:[errorCode integerValue] userInfo:details];
            if ([errorCode integerValue] == kWebKEY_NOTFOUND) {
                [details setValue:@"key-id" forKey:kWebKEY];
                [self notifyErrorKeyNotFound:error];
            } else {
                [self notifyError:error];
            }
            return nil;
        }
    }

    if (message) {
        NSString* type = [result objectForKey:@"message-type"];
        if ([type length] != 0) {
            if ([type isEqualToString:kRegisterAccount]) {
                self.authToken = [message objectForKey:@"authtoken"];
                self.userEmail = [message objectForKey:@"email"];
                self.computerName = [message objectForKey:@"computername"];
                [self notifyRegisterAccount:message];
            } else if ([type isEqualToString:kAssociateMachine]) {
                self.authToken = [message objectForKey:@"authtoken"];
                self.userEmail = [message objectForKey:@"email"];
                self.computerName = [message objectForKey:@"computername"];
                [self notifyAssociateMachine:message];
                [self sendRetrieveKeys];
            } else if ([type isEqualToString:kUnlinkMachine]) {
                self.authToken = @"";
                self.userEmail = @"";
                self.computerName = @"";
                [self notifyUnlinkMachine:nil];
            } else if ([type isEqualToString:kRetrieveKeys]) {
                [self notifyRetrieveKeys:[message objectForKey:@"keys"]];
            } else if ([type isEqualToString:kStoreKeys]) {
                [self notifyStoreKeys:nil];
            } else if ([type isEqualToString:kValidateToken]) {
                [self notifyValidateToken:nil];
            } else if ([type isEqualToString:kGetKey]) {
                if (async)
                    [self notifyGetKey:message];
            }
        } else {

        }
        NSLog(@"Response => %@", type);
    }
    return message;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self parseResponse:self.responseData async:YES];
}

- (void) notifyError:(NSError*)param {
    [[NSNotificationCenter defaultCenter] postNotificationName:kWebError object:param];
}

- (void) notifyErrorKeyNotFound:(NSError*)param {
    [[NSNotificationCenter defaultCenter] postNotificationName:kWebErrorKeyNotFound object:param];
}


- (void) notifyRegisterAccount:(id)param {
    if ([self.authToken length] != 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRegisterAccount object: param];
    }
}

- (void) notifyAssociateMachine:(id)param {
    if ([self.authToken length] != 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAssociateMachine object: param];
    }
}

- (void) notifyUnlinkMachine:(id)param {
    [[NSNotificationCenter defaultCenter] postNotificationName:kUnlinkMachine object: nil];
}

- (void) notifyRetrieveKeys:(id)param {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRetrieveKeys object:param];
}

- (void) notifyStoreKeys:(id)param {
    [[NSNotificationCenter defaultCenter] postNotificationName:kStoreKeys object:param];
}


- (void) notifyValidateToken :(id)param {
    if ([self.authToken length] != 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kValidateToken object: nil];
    }
}

- (void) notifyGetKey :(id)param {
    if ([self.authToken length] != 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kGetKey object:param];
    }
}


- (NSString*)errorToString:(int)error
{
    switch (error) {
        case kWebGENERAL_ERROR:
            return @"Internal Server error";
            break;
        case kWebEMAIL_EXISTS:
            return @"Email exists";
            break;
        case kWebUSENAME_EXISTS:
            return @"User name exists";
            break;
        case kWebAUTOREGISTER_DISABLED:
            return @"Autoregister disabled";
            break;
        case kWebCANNOT_ASSOCIATE_MACHINE_WITH_ACCOUNT:
            return @"Can't associate machine with account";
            break;
        case kWebSAVING_USER_FAILED:
            return @"Saving user failed";
            break;
        case kWebEMAIL_NOTFOUND:
            return @"EMail not found";
            break;
        case kWebINVALID_MACHINE_NAME:
            return @"Invalid machine name";
            break;
        case kWebCOMPUTERNAME_EXISTS:
            return @"Computer name exists";
            break;
        case kWebCOMPUTERNAME_NOTFOUND:
            return @"Computer name not found";
            break;
        case kWebACCOUNT_NOTFOUND:
            return @"Account not found";
            break;
        case kWebINVALID_AUTH_TOKEN:
            return @"Invalid auth token";
            break;
        case kWebCANNOT_INSERT_KEY_RECORD:
            return @"Can't insert key record";
            break;
        case kWebKEY_NOTFOUND:
            return @"Key not found";
            break;
        case kWebINVALID_INVITATION:
            return @"Invalid invitation";
            break;
        case kWebINVITATION_REQUIRED:
            return @"Invitation required";
            break;
        case kWebINVALID_TASK:
            return @"Invalid task";
            break;
        case kWebINVALID_MESSAGE_VERSION:
            return @"Invalid message version";
            break;
        case kWebINVALID_MESSAGE_TYPE:
            return @"Invalid message type";
            break;
        case kWebCANNOT_CREATE_GROUP:
            return @"Can't create group";
            break;
        case kWebCANNOT_CREATE_ASSOCIATION:
            return @"Can't create association";
            break;
        default:
            break;
    }
    return @"Unknown error.";
    
}


@end
