import ballerina/http;
import ballerina/io;
import ballerina/cache;

string __path = "NOT-USED";

final cache:Cache contentCache = new;

# Attach a webserver at a given path for a given document root to the
# given listener.
#
# + hl - hl HTTP listener to attached webserver t 
# + webPath - webPath URL path at which to attach webserver to 
# + docRoot - webRoot file system path to where the files to serve are at
# + return - error if unable to attach or unable to open & process docRoot
public function serve(http:Listener hl, string webPath, string docRoot) returns @tainted error? {
    // load the content into cache
    check loadContent(contentCache, webPath, docRoot);

    // register the webservering service
    __path = webPath; // temp hack
    check hl.__attach(
        @http:ServiceConfig {
            basePath: __path // temp hack - shoudl be basePath: webPath
        }
        service {
            @http:ResourceConfig {
                path: "/*",
                methods: ["GET", "HEAD"]
            } 
            resource function process(http:Caller hc, http:Request req) returns error? {
                if req.method == "GET" {
                    return processGet(hc, req);
                } else { // HEAD
                    check hc->badRequest("Unsupported method: HEAD");
                }
            }
            @http:ResourceConfig {
                path: "/*",
                methods: ["*"]
            }
            resource function unknownMethod(http:Caller hc, http:Request req) returns error? {
                check hc->badRequest("Unsupported method: Not GET/HEAD");
            }
        }
    );
    return;
}

function processGet (http:Caller hc, http:Request req) returns error? {
    io:println("Got request: ", req.method, " ", req.rawPath);
    string basePath = <@untainted> req.rawPath;
    ResourceInfo ri =  <ResourceInfo> check contentCache.get(basePath);

    http:Response resp = new;
    resp.setPayload(ri.content);
    resp.setContentType(ri.mediaType);
    resp.setHeader("etag", ri.eTag);
    resp.setHeader("content-length", ri.contentLength.toString());
    resp.setHeader("last-modified", ri.lastModifiedTime.toString());
    check hc->ok(resp);
}