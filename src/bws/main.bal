import ballerina/io;
import ballerina/http;

http:Listener hl = new(9999);

public function main(string? webroot = ".") returns @tainted error? {
    io:println("Hello World!");
    check serve(hl, "/web", ".");
    check hl.__start();
}
